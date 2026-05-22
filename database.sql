-- ============================================================================
-- NoorAI — Supabase database setup
-- ----------------------------------------------------------------------------
-- Run this ONCE in your Supabase project:
--   Supabase Dashboard → SQL Editor → New query → paste this whole file → Run.
--
-- It creates every table the backend needs, the voice-notes storage bucket,
-- indexes, and locks the tables down with Row Level Security so they are only
-- reachable with the service_role key (which is exactly what the backend uses).
-- The mobile app never talks to Supabase directly — it goes through the API.
--
-- After running this, the only two things you add to the backend are:
--   SUPABASE_URL   = https://<your-project-ref>.supabase.co
--   SUPABASE_KEY   = <your project's service_role key>   (Settings → API)
-- ============================================================================

-- ── users ──────────────────────────────────────────────────────────────────
-- Parents/accounts. Passwords are salted + SHA-256 hashed by the backend; the
-- plaintext password is never stored.
create table if not exists public.users (
    user_id         text primary key,
    email           text unique not null,
    name            text,
    salt            text,
    password_hash   text,
    child_name      text,
    child_age       integer,
    child_condition text,
    city            text,
    area            text,
    phone           text,
    created_at      text
);

-- ── tokens ─────────────────────────────────────────────────────────────────
-- Session tokens, stored HASHED at rest (token_hash). kind = 'access' | 'refresh'.
-- expires_at is a unix timestamp (seconds). Refresh tokens carry "remember".
create table if not exists public.tokens (
    token_hash  text primary key,
    user_id     text not null,
    kind        text not null,
    remember    boolean,
    created_at  text,
    expires_at  bigint
);

-- ── messages ───────────────────────────────────────────────────────────────
-- Chat (text + voice) between a parent and a therapist. thread_id groups a pair.
-- voice_url points at the backend's /api/voice-notes/<file> route.
create table if not exists public.messages (
    message_id   text primary key,
    thread_id    text not null,
    user_id      text not null,
    therapist_id text not null,
    sender       text,
    kind         text,
    text         text,
    voice_url    text,
    duration_ms  integer,
    created_at   text
);

-- ── bookings ───────────────────────────────────────────────────────────────
-- Therapy bookings. sessions / intent_snapshot are JSON blobs from the pipeline.
create table if not exists public.bookings (
    booking_id        text primary key,
    therapist_id      text,
    user_id           text,
    sessions          jsonb,
    total_price       integer,
    confirmation_code text,
    status            text,
    created_at        text,
    intent_snapshot   jsonb
);

-- ── service_bookings ─────────────────────────────────────────────────────────
-- Bookings for general home services (plumber, electrician, tutor, …).
create table if not exists public.service_bookings (
    booking_id        text primary key,
    provider_id       text,
    provider_name     text,
    category          text,
    user_id           text,
    slot              text,
    date              text,
    time              text,
    price             integer,
    confirmation_code text,
    status            text,
    created_at        text,
    intent_snapshot   jsonb
);

-- ── traces ─────────────────────────────────────────────────────────────────
-- Per-run agent traces rendered by the app's Agent Trace screen. entries is a
-- JSON array appended to across a pipeline run.
create table if not exists public.traces (
    trace_id     text primary key,
    created_at   text,
    updated_at   text,
    user_message text,
    entries      jsonb
);

-- ── indexes for the lookups the backend actually does ────────────────────────
create index if not exists idx_messages_thread_id        on public.messages (thread_id);
create index if not exists idx_messages_user_id          on public.messages (user_id);
create index if not exists idx_bookings_user_id          on public.bookings (user_id);
create index if not exists idx_service_bookings_user_id  on public.service_bookings (user_id);
create index if not exists idx_tokens_user_id            on public.tokens (user_id);

-- ── Row Level Security ───────────────────────────────────────────────────────
-- Enable RLS and add NO policies. With RLS on and no policy, the anon/public
-- key can read or write nothing. The backend connects with the service_role
-- key, which bypasses RLS entirely — so the API keeps full access while these
-- tables (which hold password hashes and session tokens) are never exposed
-- through Supabase's public REST endpoint.
alter table public.users            enable row level security;
alter table public.tokens           enable row level security;
alter table public.messages         enable row level security;
alter table public.bookings         enable row level security;
alter table public.service_bookings enable row level security;
alter table public.traces           enable row level security;

-- ── Storage bucket for voice notes ───────────────────────────────────────────
-- Private bucket; the backend uploads/downloads with the service_role key.
insert into storage.buckets (id, name, public)
values ('voice-notes', 'voice-notes', false)
on conflict (id) do nothing;
