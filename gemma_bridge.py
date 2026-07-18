"""
Gemma-bryggan — kör på hemdatorn medan ni seglar.

Kollar Skeppschatten (Supabase) var 15:e sekund. När någon skriver
"@gemma <fråga>" skickas frågan till din lokala Gemma och svaret
postas tillbaka i chatten. Telefonerna pratar bara med Supabase —
inget behöver öppnas upp mot internet på hemdatorn.

Start:
    pip install requests
    python gemma_bridge.py

Kräver att lokala Gemma-servern kör (Ollama: `ollama serve`,
modellnamnet nedan måste finnas: `ollama pull gemma3`).
Lämna datorn på med locket öppet / sleep avstängt.
"""
import time
import requests

# ---------- Inställningar ----------
SUPABASE_URL = "https://wptovqfypslbneobnjim.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndwdG92cWZ5cHNsYm5lb2JuamltIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM3MDE3MTEsImV4cCI6MjA5OTI3NzcxMX0.FSk4R4QnKxV_X6FPIbZbTZPgwnomaiZjSkggv2UYkgc"

GEMMA_API = "http://localhost:11434/api/generate"   # Ollama-standard
GEMMA_MODEL = "gemma3"                               # byt till din modell, t.ex. "gemma3:12b"
POLL_SECONDS = 15
AUTHOR = "⚓ Gemma"

SYSTEM_PROMPT = (
    "Du är Gemma, skepps-AI ombord på segelbåten s/y Sun-Day (Degerö 33) "
    "på veckotörn i Skärgårdshavet från Storören till Kasnäs. Besättningen: "
    "Roope, Tiina, Pernilla, Patrik och Martin. Svara kort (max 5 meningar), "
    "hjälpsamt och gärna med lite sjömanshumor. Svara på samma språk som frågan."
)

H = {"apikey": SUPABASE_KEY, "Authorization": f"Bearer {SUPABASE_KEY}",
     "Content-Type": "application/json"}


def get(path):
    r = requests.get(f"{SUPABASE_URL}/rest/v1/{path}", headers=H, timeout=20)
    r.raise_for_status()
    return r.json()


def post(table, row):
    r = requests.post(f"{SUPABASE_URL}/rest/v1/{table}", headers=H, json=row, timeout=20)
    r.raise_for_status()


def ask_gemma(question, history):
    context = "\n".join(f"{m['author']}: {m['body']}" for m in history[-6:])
    prompt = f"{SYSTEM_PROMPT}\n\nSenaste chatten:\n{context}\n\nFråga: {question}\n\nSvar:"
    r = requests.post(GEMMA_API, json={
        "model": GEMMA_MODEL, "prompt": prompt, "stream": False,
        "options": {"num_predict": 300},
    }, timeout=180)
    r.raise_for_status()
    return r.json().get("response", "").strip()


def main():
    print(f"Gemma-bryggan igång — lyssnar på skeppschatten var {POLL_SECONDS} s. Ctrl+C avslutar.")
    while True:
        try:
            msgs = get("chat?select=*&order=created_at.asc&limit=200")
            answered = {m["reply_to"] for m in msgs if m.get("reply_to")}
            for m in msgs:
                body = (m.get("body") or "").strip()
                if body.lower().startswith("@gemma") and m["id"] not in answered:
                    q = body[6:].strip(" :,-—") or "Säg hej till besättningen!"
                    print(f"→ Fråga från {m['author']}: {q[:80]}")
                    try:
                        answer = ask_gemma(q, msgs)
                    except Exception as e:
                        answer = f"(Gemma kunde inte svara just nu: {e})"
                    post("chat", {"author": AUTHOR, "body": answer[:1500], "reply_to": m["id"]})
                    print(f"← Svar skickat ({len(answer)} tecken)")
        except KeyboardInterrupt:
            print("\nBryggan stängd. God segling!")
            return
        except Exception as e:
            print(f"(tillfälligt fel, försöker igen: {e})")
        time.sleep(POLL_SECONDS)


if __name__ == "__main__":
    main()
