-- Tap Me initial Supabase schema
-- Run in Supabase SQL Editor. Do not place service_role keys in the mobile app.
create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  display_name text not null default '',
  bio text not null default '',
  avatar_url text,
  theme_color text not null default '#757575',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.profile_links (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  platform text not null check (platform in ('whatsapp', 'instagram', 'tiktok')),
  url text not null,
  sort_order integer not null default 0,
  unique (profile_id, platform)
);

create table if not exists public.tap_events (
  id bigint generated always as identity primary key,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  source text not null default 'profile',
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.profile_links enable row level security;
alter table public.tap_events enable row level security;

-- Public can view public profile and links. Owner-only editing/auth policies must be
-- added when account authentication is configured; do not make public write policies.
create policy "Public can read profiles" on public.profiles for select using (true);
create policy "Public can read profile links" on public.profile_links for select using (true);
