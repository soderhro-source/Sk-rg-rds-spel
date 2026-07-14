import type { Config } from "@netlify/functions";

// Skepps-AI-brygga #2: molnreserv för @gemma i Skeppschatten.
//
// gemma_bridge.py (körs på Roope's hemdator) svarar normalt inom sekunder,
// NÄR datorn är på. Den här funktionen körs istället i molnet var minut,
// oavsett om någon dator är på.
//
// TILLFÄLLIGT LÄGE (satt 2026-07-14 på begäran): GRACE_MS är nedskruvad
// till nästan noll, så Mistral svarar direkt istället för att vänta in
// lokala Gemma — eftersom hemdatorns brygga inte verkar köra just nu
// (flera @gemma-frågor från tidigare i veckan står obesvarade). Om/när
// Roope har gemma_bridge.py igång igen permanent, höj GRACE_MS tillbaka
// till t.ex. 3*60*1000 så lokala Gemma får förtur igen (den är gratis
// och kör en större modell). Detta är bara en kodändring här — det finns
// ingen "av/på-knapp" för själva Python-skriptet på hans dator; det stängs
// bara av genom att stänga terminalfönstret/processen där lokalt.
//
// Kräver miljövariabeln MISTRAL_API_KEY (satt i Netlifys
// projektinställningar — ALDRIG i den här filen eller i git).

const SUPABASE_URL = "https://wptovqfypslbneobnjim.supabase.co";
const SUPABASE_ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndwdG92cWZ5cHNsYm5lb2JuamltIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM3MDE3MTEsImV4cCI6MjA5OTI3NzcxMX0.FSk4R4QnKxV_X6FPIbZbTZPgwnomaiZjSkggv2UYkgc";
const GRACE_MS = 5 * 1000; // TILLFÄLLIGT: nästan ingen väntan, se kommentar ovan
const STALE_MS = 30 * 60 * 1000; // svara inte på frågor äldre än detta
const AUTHOR = "⚓ Gemma";
const SYSTEM_PROMPT =
  "Du är Gemma, skepps-AI ombord på segelbåten s/y Sun-Day (Degerö 33) " +
  "på veckotörn i Skärgårdshavet från Storören till Kasnäs. Besättningen: " +
  "Roope, Tiina, Pernilla, Patrik och Martin. Svara kort (max 5 meningar), " +
  "hjälpsamt och gärna med lite sjömanshumor. Svara på samma språk som frågan.";

type ChatMsg = { id: string; author: string; body: string; reply_to: string | null; created_at: string };

async function sb(path: string, init?: RequestInit) {
  const headers = {
    apikey: SUPABASE_ANON_KEY,
    Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
    "Content-Type": "application/json",
    ...(init?.headers || {}),
  };
  const r = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, { ...init, headers });
  if (!r.ok) throw new Error(`Supabase ${r.status}: ${await r.text()}`);
  return r.json();
}

async function askMistral(question: string, history: ChatMsg[], apiKey: string): Promise<string> {
  const context = history.slice(-6).map((m) => `${m.author}: ${m.body}`).join("\n");
  const prompt = `Senaste chatten:\n${context}\n\nFråga: ${question}`;
  const r = await fetch("https://api.mistral.ai/v1/chat/completions", {
    method: "POST",
    headers: { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      model: "mistral-small-latest",
      messages: [
        { role: "system", content: SYSTEM_PROMPT },
        { role: "user", content: prompt },
      ],
      max_tokens: 300,
    }),
  });
  if (!r.ok) throw new Error(`Mistral ${r.status}: ${await r.text()}`);
  const j = await r.json();
  const answer = j.choices?.[0]?.message?.content?.trim();
  if (!answer) throw new Error("Tomt svar från Mistral");
  return answer;
}

export default async (req: Request) => {
  const apiKey = Netlify.env.get("MISTRAL_API_KEY");
  if (!apiKey) {
    console.log("MISTRAL_API_KEY är inte satt — hoppar över molnreserven.");
    return;
  }

  let msgs: ChatMsg[];
  try {
    msgs = await sb("chat?select=*&order=created_at.asc&limit=200");
  } catch (e) {
    console.log("Kunde inte läsa chatten:", e);
    return;
  }

  const answered = new Set(msgs.filter((m) => m.reply_to).map((m) => m.reply_to));
  const now = Date.now();

  for (const m of msgs) {
    const body = (m.body || "").trim();
    if (!body.toLowerCase().startsWith("@gemma")) continue;
    if (answered.has(m.id)) continue; // redan besvarad (av lokala Gemma eller oss)
    const age = now - new Date(m.created_at).getTime();
    if (age < GRACE_MS || age > STALE_MS) continue;

    const q = body.slice(6).trim().replace(/^[\s:,\-—]+/, "") || "Säg hej till besättningen!";
    let answer: string;
    try {
      answer = await askMistral(q, msgs, apiKey);
    } catch (e) {
      answer = `(Gemma kunde inte svara just nu: ${e})`;
    }
    try {
      await sb("chat", {
        method: "POST",
        body: JSON.stringify({ author: AUTHOR, body: answer.slice(0, 1500), reply_to: m.id }),
      });
      console.log(`Svarade på fråga från ${m.author}: ${q.slice(0, 60)}`);
    } catch (e) {
      console.log("Kunde inte posta svaret:", e);
    }
  }
};

export const config: Config = { schedule: "* * * * *" }; // TILLFÄLLIGT: var minut (Netlifys minsta intervall) istället för var 2:a
