-- Migration: Complete Savora Food Delivery Database Schema
-- Profiles, Restaurants, Foods, Favorites, Addresses, Orders, Order Items, Order Events

-- 1. PROFILES
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text,
  avatar_url text,
  phone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "Allow authenticated users to read their own profile" on public.profiles;
create policy "Allow authenticated users to read their own profile"
  on public.profiles for select
  to authenticated
  using ((select auth.uid()) = id);

drop policy if exists "Allow authenticated users to insert their own profile" on public.profiles;
create policy "Allow authenticated users to insert their own profile"
  on public.profiles for insert
  to authenticated
  with check ((select auth.uid()) = id);

drop policy if exists "Allow authenticated users to update their own profile" on public.profiles;
create policy "Allow authenticated users to update their own profile"
  on public.profiles for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- Trigger for auto-profile creation
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, email, full_name, avatar_url)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.raw_user_meta_data->>'avatar_url', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 2. RESTAURANTS
create table if not exists public.restaurants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  image_url text not null,
  rating numeric(2,1) not null default 4.8,
  delivery_time text not null default '25-35 min',
  delivery_fee numeric(10,2) not null default 2.99,
  category text not null,
  is_featured boolean not null default false,
  address text,
  created_at timestamptz not null default now()
);

alter table public.restaurants enable row level security;

drop policy if exists "Allow public read on restaurants" on public.restaurants;
create policy "Allow public read on restaurants"
  on public.restaurants for select
  to anon, authenticated
  using (true);

-- 3. FOODS
create table if not exists public.foods (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid references public.restaurants(id) on delete cascade,
  name text not null,
  description text,
  price numeric(10,2) not null,
  image_url text not null,
  category text not null,
  rating numeric(2,1) not null default 4.9,
  calories int,
  prep_time text not null default '15-20 min',
  is_popular boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.foods enable row level security;

drop policy if exists "Allow public read on foods" on public.foods;
create policy "Allow public read on foods"
  on public.foods for select
  to anon, authenticated
  using (true);

-- 4. FAVORITES
create table if not exists public.favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  food_id uuid references public.foods(id) on delete cascade not null,
  created_at timestamptz not null default now(),
  unique (user_id, food_id)
);

alter table public.favorites enable row level security;

drop policy if exists "Allow users to read their own favorites" on public.favorites;
create policy "Allow users to read their own favorites"
  on public.favorites for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Allow users to insert their own favorites" on public.favorites;
create policy "Allow users to insert their own favorites"
  on public.favorites for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Allow users to delete their own favorites" on public.favorites;
create policy "Allow users to delete their own favorites"
  on public.favorites for delete
  to authenticated
  using ((select auth.uid()) = user_id);

-- 5. ADDRESSES
create table if not exists public.addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  title text not null default 'Home',
  street text not null,
  city text not null,
  state text,
  postal_code text,
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.addresses enable row level security;

drop policy if exists "Allow users to manage their own addresses" on public.addresses;
create policy "Allow users to read their own addresses"
  on public.addresses for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "Allow users to insert their own addresses"
  on public.addresses for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "Allow users to update their own addresses"
  on public.addresses for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "Allow users to delete their own addresses"
  on public.addresses for delete
  to authenticated
  using ((select auth.uid()) = user_id);

-- 6. ORDERS
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  status text not null default 'pending',
  subtotal numeric(10,2) not null,
  delivery_fee numeric(10,2) not null default 2.99,
  tax numeric(10,2) not null default 1.50,
  total numeric(10,2) not null,
  delivery_address text not null,
  payment_method text not null default 'card',
  payment_status text not null default 'unpaid',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.orders enable row level security;

drop policy if exists "Allow users to read their own orders" on public.orders;
create policy "Allow users to read their own orders"
  on public.orders for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Allow users to insert their own orders" on public.orders;
create policy "Allow users to insert their own orders"
  on public.orders for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

-- 7. ORDER ITEMS
create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid references public.orders(id) on delete cascade not null,
  food_id uuid references public.foods(id) on delete set null,
  name text not null,
  price numeric(10,2) not null,
  quantity int not null default 1,
  created_at timestamptz not null default now()
);

alter table public.order_items enable row level security;

drop policy if exists "Allow users to read their order items" on public.order_items;
create policy "Allow users to read their order items"
  on public.order_items for select
  to authenticated
  using (
    exists (
      select 1 from public.orders
      where orders.id = order_items.order_id
        and orders.user_id = (select auth.uid())
    )
  );

drop policy if exists "Allow users to insert their order items" on public.order_items;
create policy "Allow users to insert their order items"
  on public.order_items for insert
  to authenticated
  with check (
    exists (
      select 1 from public.orders
      where orders.id = order_items.order_id
        and orders.user_id = (select auth.uid())
    )
  );

-- 8. ORDER EVENTS (For live realtime timeline)
create table if not exists public.order_events (
  id uuid primary key default gen_random_uuid(),
  order_id uuid references public.orders(id) on delete cascade not null,
  status text not null,
  title text not null,
  description text,
  created_at timestamptz not null default now()
);

alter table public.order_events enable row level security;

drop policy if exists "Allow users to read their order events" on public.order_events;
create policy "Allow users to read their order events"
  on public.order_events for select
  to authenticated
  using (
    exists (
      select 1 from public.orders
      where orders.id = order_events.order_id
        and orders.user_id = (select auth.uid())
    )
  );

create policy "Allow users to insert their order events"
  on public.order_events for insert
  to authenticated
  with check (
    exists (
      select 1 from public.orders
      where orders.id = order_events.order_id
        and orders.user_id = (select auth.uid())
    )
  );

-- Enable Realtime on orders & order_events
alter publication supabase_realtime add table public.orders;
alter publication supabase_realtime add table public.order_events;

