-- VitaPulse initial schema: profiles, health_metrics, daily_summaries + RLS.

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  date_of_birth date,
  gender text,
  height_cm numeric,
  step_goal int default 8000,
  water_goal_ml int default 2000,
  created_at timestamptz default now()
);

create table public.health_metrics (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  metric_type text not null check (metric_type in (
    'steps','heart_rate','sleep_session','bp_systolic','bp_diastolic',
    'spo2','weight','water_intake','calories_burned')),
  value numeric not null,
  unit text not null,
  recorded_at timestamptz not null,
  source text not null default 'health_connect',
  created_at timestamptz default now(),
  unique (user_id, metric_type, recorded_at, source)
);
create index on public.health_metrics (user_id, metric_type, recorded_at desc);

create table public.daily_summaries (
  user_id uuid not null references auth.users(id) on delete cascade,
  day date not null,
  total_steps int, avg_heart_rate numeric, resting_heart_rate numeric,
  sleep_minutes int, bp_systolic numeric, bp_diastolic numeric,
  avg_spo2 numeric, water_ml int, calories numeric, weight_kg numeric,
  primary key (user_id, day)
);

alter table public.profiles enable row level security;
alter table public.health_metrics enable row level security;
alter table public.daily_summaries enable row level security;

create policy "own profile" on public.profiles
  for all using (auth.uid() = id) with check (auth.uid() = id);
create policy "own metrics" on public.health_metrics
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own summaries" on public.daily_summaries
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
