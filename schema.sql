-- Skärgårdsspaning — Supabase schema
-- Kör hela filen i Supabase: SQL Editor → New query → klistra in → Run.

create table if not exists sailors (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  pin_hash text not null,
  emoji text not null default '⛵',
  created_at timestamptz default now()
);

create table if not exists logs (
  id uuid primary key default gen_random_uuid(),
  client_id text unique,
  sailor_id uuid references sailors(id) on delete cascade,
  kind text not null check (kind in ('spot','quiz','checkpoint','knot','surprise','minigame','bonus')),
  ref text not null,
  points int not null default 0,
  note text,
  created_at timestamptz default now()
);

-- En logg per sak och seglare (spots, hamnutmaningar, knopar, dagens quiz/minispel)
create unique index if not exists one_per_sailor
  on logs (sailor_id, kind, ref)
  where kind in ('spot','checkpoint','knot','quiz','minigame');

-- Dagens överraskning: först till kvarn — bara EN i hela besättningen
create unique index if not exists one_surprise_claim
  on logs (kind, ref)
  where kind = 'surprise';

-- RLS: öppet för anon-nyckeln (kompisspel — säkerheten är PIN + hemlig URL)
alter table sailors enable row level security;
alter table logs enable row level security;

create policy "anon read sailors"   on sailors for select to anon using (true);
create policy "anon insert sailors" on sailors for insert to anon with check (true);
create policy "anon read logs"      on logs for select to anon using (true);
create policy "anon insert logs"    on logs for insert to anon with check (true);
create policy "anon delete logs"    on logs for delete to anon using (true);

-- Realtime så allas skärmar uppdateras direkt
alter publication supabase_realtime add table logs;
