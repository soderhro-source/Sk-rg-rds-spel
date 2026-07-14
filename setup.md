# Skärgårdsspaning — setup (ca 20 min totalt)

Multiplayer-däckspel för veckotörnen Helsingfors → Åbo på s/y Sun-Day (Degerö 33).

## Vad spelet innehåller

Spelplan i Monopoly-stil (START Helsingfors → 12 hamnar → MÅL Åbo). Alla poäng flyttar din pjäs (30 p per etapp, 360 p till Åbo). Besättningens gemensamma skepp ⛵ seglar på summan av allas poäng. Poäng får man från: artspaning (fartyg, fåglar, flora, sjöliv), hamnutmaningar (+5, låses upp när din pjäs nått hamnen), knopar (visa för en kompis), frågesport (1 bokföring/dag), dagens överraskning (först till kvarn i besättningen) och Spelrummet (Lastrummet-tetris & Skärgårdsminne, max 5 resp. 4 p/dag).

Utan server körs appen i **lokalt läge** — allt funkar men poängen stannar i varje telefon. Med Supabase delas allt live.

**Flera båtar:** vid "Mönstra på" väljer man en befintlig båt eller skapar en ny (namn + symbol) — den som skapar båten blir automatiskt dess kapten. Varje båt har sin egen rutt, kapten och spelplansposition; poängen för artspaning/frågesport/spelrum är gemensam kul för alla, men "Besättningens resa" och Törnrapporten visar bara din egen båts besättning. En båt utan kapten visar en "Bli kapten"-knapp till nästa som mönstrar på den.

## Steg 1 — Supabase (~10 min)

1. Gå till https://supabase.com → Sign up (GitHub eller e-post) → **New project**. Namn t.ex. `skargardsspaning`, region EU (Frankfurt/Stockholm), valfritt DB-lösenord (behövs inte senare).
2. Vänta ~2 min tills projektet är klart.
3. Öppna **SQL Editor** → New query → klistra in hela innehållet i `schema.sql` → **Run**. Ska sluta med "Success".
4. Gå till **Settings → API**. Kopiera:
   - **Project URL** → in i `config.js` som `SUPABASE_URL`
   - **anon public**-nyckeln → in i `config.js` som `SUPABASE_ANON_KEY`

## Steg 2 — Netlify (~5 min)

1. Gå till https://app.netlify.com/drop (logga in/skapa konto).
2. Dra hela mappen `skargardsspaning` till sidan. Klart — du får en URL typ `https://nagot-namn.netlify.app`.
3. Byt gärna namn: Site settings → Change site name → t.ex. `sunday-spaning`.

Uppdatering senare: dra mappen till samma site under Deploys, eller be Claude göra ändringar och deploya om.

## Steg 3 — Besättningen ombord (~1 min per person)

1. Skicka URL:en i er gruppchatt.
2. Var och en öppnar länken → **Mönstra på** → namn, symbol, 4-siffrig PIN.
3. Tips: lägg till på hemskärmen (Dela → Lägg till på hemskärmen) så känns det som en app.

## Bra att veta till sjöss

- **Dålig täckning:** appen loggar allt lokalt och synkar automatiskt när nätet kommer tillbaka (gul prick = väntar, grön = synkad). Ladda sidan i hamn, håll fliken öppen.
- **Säkerhet:** PIN är kompis-nivå, inte bank-nivå. Dela inte URL:en utanför gänget.
- **Fusk:** hela poängsystemet bygger på heder. Precis som det ska vara.

## Gemma-bryggan (skepps-AI i chatten)

Skeppschatten (💬 i appen) funkar direkt. För att **@gemma** ska svara:

1. På hemdatorn: se till att Ollama kör (`ollama serve`) och att modellen finns (`ollama pull gemma3` — eller ändra `GEMMA_MODEL` i `gemma_bridge.py` till den modell du kör).
2. Kör `python gemma_bridge.py` (kräver `pip install requests`).
3. Lämna datorn på under seglatsen (stäng av vila/sleep).

Bryggan pollar chatten var 15 s, skickar @gemma-frågor till din lokala Gemma och postar svaret tillbaka. Inga portar öppnas — allt går via Supabase.

## Filer

| Fil | Vad |
|---|---|
| `index.html` | Hela appen |
| `config.js` | Supabase-nycklar (enda filen du redigerar) |
| `schema.sql` | Körs en gång i Supabase |
| `SETUP.md` | Den här guiden |
