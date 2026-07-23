-- ================================================================
-- ESSENCE TABACARIA — SCHEMA SUPABASE (PostgreSQL)
-- Execute este script inteiro no SQL Editor do seu projeto Supabase.
-- ================================================================

-- ----------------------------------------------------------------
-- CATEGORIAS
-- "chave" é um slug único gerado automaticamente a partir do nome
-- (ex.: "Pods" -> "pods-m5k2x9") e é o identificador usado pelos
-- produtos e pelo catálogo — segue o mesmo comportamento que a
-- etapa anterior (backend Node) já usava.
-- ----------------------------------------------------------------
create table if not exists public.categorias (
  id         bigint generated always as identity primary key,
  chave      text not null unique,
  nome       text not null,
  icone      text not null default 'geral',
  created_at timestamptz not null default now()
);

-- ----------------------------------------------------------------
-- PRODUTOS
-- ----------------------------------------------------------------
create table if not exists public.produtos (
  id                 bigint generated always as identity primary key,
  nome               text not null,
  categoria          text not null references public.categorias(chave) on update cascade,
  marca              text,
  descricao          text,
  preco              numeric(10,2) not null default 0,
  "precoPromocional" numeric(10,2),
  estoque            integer not null default 0,
  imagem             text,
  destaque           boolean not null default false,
  status             text not null default 'disponivel' check (status in ('disponivel','esgotado')),
  created_at         timestamptz not null default now()
);

create index if not exists idx_produtos_categoria on public.produtos(categoria);
create index if not exists idx_produtos_status on public.produtos(status);

-- ----------------------------------------------------------------
-- CONFIGURAÇÕES (registro único — id sempre 1)
-- ----------------------------------------------------------------
create table if not exists public.configuracoes (
  id              integer primary key default 1,
  "nomeLoja"      text default 'Essence Tabacaria',
  whatsapp        text,
  instagram       text,
  endereco        text,
  horario         text,
  banner          text,
  logo            text,
  "corPrincipal"  text default '#d4af37',
  rodape          text,
  constraint configuracoes_single_row check (id = 1)
);

insert into public.configuracoes (id)
values (1)
on conflict (id) do nothing;

-- ----------------------------------------------------------------
-- PROMOÇÕES
-- (necessárias para manter a tela "Promoções" do painel, já criada
-- em uma etapa anterior, funcionando)
-- ----------------------------------------------------------------
create table if not exists public.promocoes (
  id           bigint generated always as identity primary key,
  titulo       text not null,
  desconto     numeric not null,
  "dataInicio" date,
  "dataFim"    date,
  ativo        boolean not null default true,
  created_at   timestamptz not null default now()
);

create table if not exists public.promocao_produtos (
  promocao_id bigint not null references public.promocoes(id) on delete cascade,
  produto_id  bigint not null references public.produtos(id) on delete cascade,
  primary key (promocao_id, produto_id)
);

-- ================================================================
-- ROW LEVEL SECURITY
-- Este protótipo não possui autenticação real no painel admin (o
-- login é uma simulação, como já era no backend Node anterior — o
-- backend antigo também não exigia autenticação em nenhuma rota).
-- Para manter o mesmo nível de acesso, habilitamos RLS e liberamos
-- leitura/escrita para a chave "anon". Antes de ir para produção
-- de verdade, troque isso por Supabase Auth + políticas restritas
-- ao papel "authenticated" (ou service role via um backend próprio).
-- ================================================================
alter table public.categorias enable row level security;
alter table public.produtos enable row level security;
alter table public.configuracoes enable row level security;
alter table public.promocoes enable row level security;
alter table public.promocao_produtos enable row level security;

create policy "categorias_select" on public.categorias for select using (true);
create policy "categorias_insert" on public.categorias for insert with check (true);
create policy "categorias_update" on public.categorias for update using (true);
create policy "categorias_delete" on public.categorias for delete using (true);

create policy "produtos_select" on public.produtos for select using (true);
create policy "produtos_insert" on public.produtos for insert with check (true);
create policy "produtos_update" on public.produtos for update using (true);
create policy "produtos_delete" on public.produtos for delete using (true);

create policy "configuracoes_select" on public.configuracoes for select using (true);
create policy "configuracoes_update" on public.configuracoes for update using (true);

create policy "promocoes_select" on public.promocoes for select using (true);
create policy "promocoes_insert" on public.promocoes for insert with check (true);
create policy "promocoes_update" on public.promocoes for update using (true);
create policy "promocoes_delete" on public.promocoes for delete using (true);

create policy "promocao_produtos_select" on public.promocao_produtos for select using (true);
create policy "promocao_produtos_insert" on public.promocao_produtos for insert with check (true);
create policy "promocao_produtos_delete" on public.promocao_produtos for delete using (true);

-- ================================================================
-- STORAGE — bucket público para imagens de produtos, logo e banner
-- ================================================================
insert into storage.buckets (id, name, public)
values ('essence-uploads', 'essence-uploads', true)
on conflict (id) do nothing;

create policy "essence_uploads_read" on storage.objects
  for select using (bucket_id = 'essence-uploads');

create policy "essence_uploads_insert" on storage.objects
  for insert with check (bucket_id = 'essence-uploads');

create policy "essence_uploads_update" on storage.objects
  for update using (bucket_id = 'essence-uploads');

create policy "essence_uploads_delete" on storage.objects
  for delete using (bucket_id = 'essence-uploads');

-- ================================================================
-- SEED opcional — categorias padrão do catálogo (pode editar/remover)
-- ================================================================
insert into public.categorias (chave, nome, icone) values
  ('pods',       'Pods',        'pods'),
  ('essencias',  'Essências',   'essencias'),
  ('narguiles',  'Narguilés',   'narguiles'),
  ('acessorios', 'Acessórios',  'acessorios')
on conflict (chave) do nothing;
