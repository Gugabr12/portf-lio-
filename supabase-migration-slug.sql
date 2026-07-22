-- Rode isso no Supabase: Dashboard -> SQL Editor -> New query -> Run
-- Adiciona a coluna "slug" (URL amigável, tipo /nome-do-projeto em vez de
-- post.html?id=uuid) e já preenche pros posts que você já tem.

alter table posts add column if not exists slug text;

create extension if not exists unaccent;

update posts
set slug = trim(both '-' from regexp_replace(lower(unaccent(title)), '[^a-z0-9]+', '-', 'g'))
where slug is null;

update posts set slug = id::text where slug is null or slug = '';

with dups as (
  select id, slug, row_number() over (partition by slug order by created_at) as rn
  from posts
)
update posts set slug = posts.slug || '-' || substr(posts.id::text, 1, 8)
from dups
where posts.id = dups.id and dups.rn > 1;

alter table posts drop constraint if exists posts_slug_unique;
alter table posts add constraint posts_slug_unique unique (slug);
