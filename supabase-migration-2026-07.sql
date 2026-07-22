-- Rode isso tudo de uma vez no Supabase: Dashboard -> SQL Editor -> New query -> Run
-- Atualiza a tabela "posts" que você já tem pro novo formato do admin
-- (edição de posts, capa + imagens do corpo, cliente e data do projeto).

alter table posts alter column behance_url drop not null;
alter table posts add column if not exists body_images text[] default '{}';
alter table posts add column if not exists client text;
alter table posts add column if not exists project_date text;
alter table posts add column if not exists sort_order integer;

update posts set sort_order = sub.rn
from (select id, row_number() over (order by created_at desc) as rn from posts) sub
where posts.id = sub.id and posts.sort_order is null;

drop policy if exists "Só autenticado pode editar" on posts;
create policy "Só autenticado pode editar"
  on posts for update
  to authenticated
  using (true)
  with check (true);
