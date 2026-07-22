-- Rode isso tudo de uma vez no Supabase: Dashboard -> SQL Editor -> New query -> Run
-- (Se você já rodou esse script antes, só precisa rodar as linhas novas agora:
-- as colunas body_images/client/project_date/sort_order/slug e a policy de
-- update. O resto não faz nada de novo porque já existe, então não tem
-- problema rodar tudo de novo.)
alter table if exists posts alter column behance_url drop not null;
alter table if exists posts add column if not exists body_images text[] default '{}';
alter table if exists posts add column if not exists client text;
alter table if exists posts add column if not exists project_date text;
alter table if exists posts add column if not exists sort_order integer;
alter table if exists posts add column if not exists slug text;

-- dá um valor inicial de ordem pros posts que já existem (mais novo primeiro),
-- só nos que ainda não têm ordem definida
update posts set sort_order = sub.rn
from (select id, row_number() over (order by created_at desc) as rn from posts) sub
where posts.id = sub.id and posts.sort_order is null;

-- gera uma URL amigável (slug) a partir do título pros posts que ainda não têm
create extension if not exists unaccent;

update posts
set slug = trim(both '-' from regexp_replace(lower(unaccent(title)), '[^a-z0-9]+', '-', 'g'))
where slug is null;

update posts set slug = id::text where slug is null or slug = '';

-- se dois posts geraram o mesmo slug, deixa só o mais antigo com o slug "limpo"
-- e adiciona um sufixo nos outros pra não duplicar
with dups as (
  select id, slug, row_number() over (partition by slug order by created_at) as rn
  from posts
)
update posts set slug = posts.slug || '-' || substr(posts.id::text, 1, 8)
from dups
where posts.id = dups.id and dups.rn > 1;

alter table if exists posts drop constraint if exists posts_slug_unique;
alter table if exists posts add constraint posts_slug_unique unique (slug);

create table if not exists posts (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  slug text unique,
  text text,
  behance_url text,
  image_url text not null,
  body_images text[] default '{}',
  tags text[] default '{}',
  client text,
  project_date text,
  sort_order integer,
  created_at timestamptz not null default now()
);

alter table posts enable row level security;

-- qualquer pessoa pode ler os posts (é o que alimenta o portfólio público)
create policy "Posts são públicos para leitura"
  on posts for select
  to anon, authenticated
  using (true);

-- só usuário autenticado (o admin) pode criar
create policy "Só autenticado pode inserir"
  on posts for insert
  to authenticated
  with check (true);

-- só usuário autenticado (o admin) pode editar
drop policy if exists "Só autenticado pode editar" on posts;
create policy "Só autenticado pode editar"
  on posts for update
  to authenticated
  using (true)
  with check (true);

-- só usuário autenticado (o admin) pode excluir
create policy "Só autenticado pode excluir"
  on posts for delete
  to authenticated
  using (true);

-- bucket de imagens
insert into storage.buckets (id, name, public)
values ('portfolio-images', 'portfolio-images', true)
on conflict (id) do nothing;

create policy "Imagens do portfólio são públicas para leitura"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'portfolio-images');

create policy "Só autenticado pode enviar imagem"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'portfolio-images');

create policy "Só autenticado pode excluir imagem"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'portfolio-images');
