-- Skärgårdsspaning — Supabase schema
-- Kör hela filen i Supabase: SQL Editor → New query → klistra in → Run.
-- (Matchar det som faktiskt körs i produktion — synkad från live-migreringar.)

create table if not exists boats (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  emoji text not null default '⛵',
  captain text,
  route jsonb not null default '[]'::jsonb,
  roles jsonb not null default '{}'::jsonb,
  workshop jsonb not null default '{}'::jsonb,
  start_harbor text,
  end_harbor text,
  model text,
  loa text,
  beam text,
  draft text,
  mast text,
  weight text,
  rig text,
  engine text,
  oil text,
  created_at timestamptz default now()
);

create table if not exists sailors (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  pin_hash text not null,
  emoji text not null default '⛵',
  boat_id uuid references boats(id),
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

create table if not exists chat (
  id uuid primary key default gen_random_uuid(),
  sailor_id uuid references sailors(id),
  author text not null,
  body text not null,
  reply_to uuid,
  created_at timestamptz default now()
);

create table if not exists port_notes (
  id uuid primary key default gen_random_uuid(),
  sailor_id uuid references sailors(id),
  author text not null,
  place text not null,
  rating int check (rating between 1 and 5),
  body text,
  photo_url text,
  created_at timestamptz default now()
);

create table if not exists settings (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz default now()
);

create table if not exists track_points (
  id uuid primary key default gen_random_uuid(),
  sailor_id uuid references sailors(id),
  lat double precision not null,
  lng double precision not null,
  sog real,
  ts timestamptz default now()
);

create table if not exists captain_log (
  id uuid primary key default gen_random_uuid(),
  boat_id uuid references boats(id),
  sailor_id uuid references sailors(id),
  departure_place text,
  departure_time timestamptz,
  arrival_place text,
  arrival_time timestamptz,
  miles numeric,
  weather text,
  notes text,
  created_at timestamptz default now()
);

create table if not exists custom_spots (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  grp text not null,
  author text,
  created_at timestamptz default now()
);

create table if not exists ideas (
  id uuid primary key default gen_random_uuid(),
  author text,
  body text not null,
  created_at timestamptz default now()
);

-- Senast delade positionen per båt (för "Visa båtar" på Seglandet 2026-kartan)
create table if not exists boat_positions (
  boat_id uuid primary key references boats(id) on delete cascade,
  lat double precision not null,
  lng double precision not null,
  sog real,
  sailor_name text,
  updated_at timestamptz not null default now()
);

-- Resor per båt: tidigare/kommande resor med en enkel ordnad lista hamnstopp (för 🧳 Resor-fliken)
create table if not exists trips (
  id uuid primary key default gen_random_uuid(),
  boat_id uuid references boats(id) on delete cascade,
  name text not null default 'Resa',
  status text not null default 'planned' check (status in ('planned','completed')),
  stops jsonb not null default '[]'::jsonb,
  notes text,
  created_at timestamptz default now()
);

-- En logg per sak och seglare (spots, hamnutmaningar, knopar, dagens quiz/minispel)
create unique index if not exists one_per_sailor
  on logs (sailor_id, kind, ref)
  where kind in ('spot','checkpoint','knot','quiz','minigame','bonus');

-- Dagens överraskning: först till kvarn — bara EN i hela besättningen
create unique index if not exists one_surprise_claim
  on logs (kind, ref)
  where kind = 'surprise';

-- RLS: öppet för anon-nyckeln (kompisspel — säkerheten är PIN + hemlig URL)
alter table sailors enable row level security;
alter table boats enable row level security;
alter table logs enable row level security;
alter table chat enable row level security;
alter table port_notes enable row level security;
alter table settings enable row level security;
alter table track_points enable row level security;
alter table captain_log enable row level security;
alter table custom_spots enable row level security;
alter table ideas enable row level security;
alter table boat_positions enable row level security;
alter table trips enable row level security;

create policy "anon read sailors"   on sailors for select to anon using (true);
create policy "anon insert sailors" on sailors for insert to anon with check (true);

create policy "anon read boats"     on boats for select to anon using (true);
create policy "anon insert boats"   on boats for insert to anon with check (true);
create policy "anon update boats"   on boats for update to anon using (true) with check (true);

create policy "anon read logs"      on logs for select to anon using (true);
create policy "anon insert logs"    on logs for insert to anon with check (true);
create policy "anon delete logs"    on logs for delete to anon using (true);

create policy "anon read chat"      on chat for select to anon using (true);
create policy "anon insert chat"    on chat for insert to anon with check (true);

create policy "anon read notes"     on port_notes for select to anon using (true);
create policy "anon insert notes"   on port_notes for insert to anon with check (true);

create policy "anon read settings"  on settings for select to anon using (true);
create policy "anon insert settings" on settings for insert to anon with check (true);
create policy "anon update settings" on settings for update to anon using (true);

create policy "anon read track"     on track_points for select to anon using (true);
create policy "anon insert track"   on track_points for insert to anon with check (true);

create policy "anon read captain_log"   on captain_log for select to anon using (true);
create policy "anon insert captain_log" on captain_log for insert to anon with check (true);
create policy "anon delete captain_log" on captain_log for delete to anon using (true);

create policy "anon read custom_spots"   on custom_spots for select to anon using (true);
create policy "anon insert custom_spots" on custom_spots for insert to anon with check (true);

create policy "anon read ideas"   on ideas for select to anon using (true);
create policy "anon insert ideas" on ideas for insert to anon with check (true);

create policy "anon read boat_positions"   on boat_positions for select to anon using (true);
create policy "anon insert boat_positions" on boat_positions for insert to anon with check (true);
create policy "anon update boat_positions" on boat_positions for update to anon using (true) with check (true);

create policy "anon read trips"   on trips for select to anon using (true);
create policy "anon insert trips" on trips for insert to anon with check (true);
create policy "anon update trips" on trips for update to anon using (true) with check (true);
create policy "anon delete trips" on trips for delete to anon using (true);

-- Realtime så allas skärmar uppdateras direkt
alter publication supabase_realtime add table logs;
alter publication supabase_realtime add table chat;
alter publication supabase_realtime add table settings;
alter publication supabase_realtime add table boats;
alter publication supabase_realtime add table boat_positions;
alter publication supabase_realtime add table trips;

-- Standardbåt — döp om eller lägg till fler via appens "Mönstra på"-formulär
-- (nya båtar som skapas via appens wizard fyller start_harbor/end_harbor/model/loa/beam/draft/mast/weight/rig automatiskt)
insert into boats (name, emoji, captain, route, start_harbor, end_harbor, model, loa, beam, draft, mast, weight, rig)
values ('Sun-Day', '⛵', 'Martin',
  '["Barösund","Hangö","Airisto","Själö","Brännskär","Korpoström","Aspö","Nötö","Björkö","Helsingholm","Högsåra","Örö","Dalsbruk","NÅDENDAL"]'::jsonb,
  'HELSINGFORS', 'NÅDENDAL', 'Degerö 33', '9,81 m (33 fot)', '3,52 m', '1,5 m', '15 m', '5 200 kg', 'Slup (en mast)')
on conflict (name) do nothing;
