-- Ejecutar en Supabase > SQL Editor > New query.
-- Después de crear el usuario administrador, copiar su UUID a la instrucción indicada al final.
create extension if not exists pgcrypto;

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  short text not null,
  mayor numeric(12,2) not null default 0 check (mayor >= 0),
  units integer not null default 0 check (units >= 0),
  img text not null default 'assets/placeholder.svg',
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.product_backups (
  id bigint generated always as identity primary key,
  product_code text,
  action text not null check (action in ('INSERT','UPDATE','DELETE')),
  before_data jsonb,
  after_data jsonb,
  changed_by uuid,
  changed_at timestamptz not null default now()
);

create or replace function public.is_catalog_admin()
returns boolean language sql stable security definer set search_path = public
as $$ select exists (select 1 from public.admin_users where user_id = auth.uid()); $$;
revoke all on function public.is_catalog_admin() from public;
grant execute on function public.is_catalog_admin() to anon, authenticated;

create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = public
as $$ begin new.updated_at = now(); return new; end; $$;
drop trigger if exists products_set_updated_at on public.products;
create trigger products_set_updated_at before update on public.products
for each row execute function public.set_updated_at();

create or replace function public.backup_product_change()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  if TG_OP = 'INSERT' then
    insert into public.product_backups(product_code,action,before_data,after_data,changed_by) values (NEW.code,'INSERT',null,to_jsonb(NEW),auth.uid());
    return NEW;
  elsif TG_OP = 'UPDATE' then
    insert into public.product_backups(product_code,action,before_data,after_data,changed_by) values (NEW.code,'UPDATE',to_jsonb(OLD),to_jsonb(NEW),auth.uid());
    return NEW;
  else
    insert into public.product_backups(product_code,action,before_data,after_data,changed_by) values (OLD.code,'DELETE',to_jsonb(OLD),null,auth.uid());
    return OLD;
  end if;
end; $$;
drop trigger if exists products_backup_changes on public.products;
create trigger products_backup_changes after insert or update or delete on public.products
for each row execute function public.backup_product_change();

alter table public.products enable row level security;
alter table public.admin_users enable row level security;
alter table public.product_backups enable row level security;

drop policy if exists "Anyone can read active products" on public.products;
create policy "Anyone can read active products" on public.products for select to anon, authenticated using (active = true or public.is_catalog_admin());
drop policy if exists "Admins insert products" on public.products;
create policy "Admins insert products" on public.products for insert to authenticated with check (public.is_catalog_admin());
drop policy if exists "Admins update products" on public.products;
create policy "Admins update products" on public.products for update to authenticated using (public.is_catalog_admin()) with check (public.is_catalog_admin());
drop policy if exists "Admins delete products" on public.products;
create policy "Admins delete products" on public.products for delete to authenticated using (public.is_catalog_admin());
drop policy if exists "Admins can see own admin row" on public.admin_users;
create policy "Admins can see own admin row" on public.admin_users for select to authenticated using (user_id = auth.uid());
drop policy if exists "Admins can read backups" on public.product_backups;
create policy "Admins can read backups" on public.product_backups for select to authenticated using (public.is_catalog_admin());

-- Habilitar Realtime para productos (si no estuviera ya en la publicación).
do $$ begin
  alter publication supabase_realtime add table public.products;
exception when duplicate_object then null;
when undefined_object then raise notice 'No existe supabase_realtime; habilitá Realtime para public.products desde el Dashboard.';
end $$;

-- Imágenes nuevas: bucket público de lectura, escritura reservada a administradores.
insert into storage.buckets (id, name, public) values ('product-images','product-images',true)
on conflict (id) do nothing;
drop policy if exists "Public can view product images" on storage.objects;
create policy "Public can view product images" on storage.objects for select using (bucket_id = 'product-images');
drop policy if exists "Admins upload product images" on storage.objects;
create policy "Admins upload product images" on storage.objects for insert to authenticated with check (bucket_id = 'product-images' and public.is_catalog_admin());
drop policy if exists "Admins update product images" on storage.objects;
create policy "Admins update product images" on storage.objects for update to authenticated using (bucket_id = 'product-images' and public.is_catalog_admin()) with check (bucket_id = 'product-images' and public.is_catalog_admin());
drop policy if exists "Admins delete product images" on storage.objects;
create policy "Admins delete product images" on storage.objects for delete to authenticated using (bucket_id = 'product-images' and public.is_catalog_admin());

-- IMPORTANTE: primero creá el usuario en Authentication > Users. Luego reemplazá UUID_AQUI por su UUID real y ejecutá:
-- insert into public.admin_users(user_id) values ('UUID_AQUI');
