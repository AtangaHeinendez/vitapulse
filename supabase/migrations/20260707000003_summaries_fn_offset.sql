-- Replace the tz-name variant with an explicit UTC-offset variant: Dart can't
-- reliably produce IANA timezone names on all platforms, but the offset in
-- minutes is always available and unambiguous.

drop function if exists public.recompute_daily_summaries(date[], text);

create or replace function public.recompute_daily_summaries(
  p_days date[],
  p_offset_minutes int default 0
)
returns void
language sql
security invoker
set search_path = public
as $$
  insert into public.daily_summaries as ds (
    user_id, day, total_steps, avg_heart_rate, resting_heart_rate,
    sleep_minutes, bp_systolic, bp_diastolic, avg_spo2, water_ml,
    calories, weight_kg
  )
  select
    m.user_id,
    ((m.recorded_at at time zone 'UTC')
       + make_interval(mins => p_offset_minutes))::date as day,
    sum(m.value) filter (where m.metric_type = 'steps')::int,
    avg(m.value) filter (where m.metric_type = 'heart_rate'),
    min(m.value) filter (where m.metric_type = 'heart_rate'),
    sum(m.value) filter (where m.metric_type = 'sleep_session')::int,
    avg(m.value) filter (where m.metric_type = 'bp_systolic'),
    avg(m.value) filter (where m.metric_type = 'bp_diastolic'),
    avg(m.value) filter (where m.metric_type = 'spo2'),
    sum(m.value) filter (where m.metric_type = 'water_intake')::int,
    sum(m.value) filter (where m.metric_type = 'calories_burned'),
    (array_agg(m.value order by m.recorded_at desc)
       filter (where m.metric_type = 'weight'))[1]
  from public.health_metrics m
  where m.user_id = auth.uid()
    and ((m.recorded_at at time zone 'UTC')
           + make_interval(mins => p_offset_minutes))::date = any(p_days)
  group by m.user_id,
           (((m.recorded_at at time zone 'UTC')
               + make_interval(mins => p_offset_minutes))::date)
  on conflict (user_id, day) do update set
    total_steps        = excluded.total_steps,
    avg_heart_rate     = excluded.avg_heart_rate,
    resting_heart_rate = excluded.resting_heart_rate,
    sleep_minutes      = excluded.sleep_minutes,
    bp_systolic        = excluded.bp_systolic,
    bp_diastolic       = excluded.bp_diastolic,
    avg_spo2           = excluded.avg_spo2,
    water_ml           = excluded.water_ml,
    calories           = excluded.calories,
    weight_kg          = excluded.weight_kg;
$$;
