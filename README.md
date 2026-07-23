# Essence Tabacaria — Catálogo Digital + Painel Administrativo

Catálogo completo, com painel administrativo, PWA instalável
(Android/iPhone/Desktop), SEO e proteções básicas de segurança.

**Arquitetura 100% frontend + Supabase** — não há mais backend Node/Express.
Todo o catálogo (produtos, categorias, promoções, configurações) e o upload
de imagens são feitos diretamente do navegador para o Supabase (Postgres +
Storage), usando `@supabase/supabase-js`.

## Estrutura do projeto

```
essence-tabacaria/
├── frontend/
│   ├── admin.html                    → painel administrativo (conectado ao Supabase)
│   ├── index.html                    → catálogo público (conectado ao Supabase), PWA instalável
│   ├── manifest.json                 → configuração do app instalável
│   ├── service-worker.js             → cache offline (app shell + imagens)
│   ├── robots.txt / sitemap.xml
│   ├── supabase-config.example.js    → modelo com a URL e a chave anon do projeto
│   ├── supabase-config.js            → sua config real (não versionar — está no .gitignore)
│   └── assets/icons/                 → ícones do app e favicons
├── supabase/
│   └── schema.sql                    → script único: tabelas, RLS e bucket de imagens
├── netlify.toml / vercel.json        → deploy do frontend estático
└── README.md
```

## 1. Criar o projeto no Supabase

1. Crie uma conta e um projeto em [supabase.com](https://supabase.com).
2. No painel do projeto, abra **SQL Editor** → **New query**, cole todo o
   conteúdo de `supabase/schema.sql` e execute. Isso cria:
   - as tabelas `categorias`, `produtos`, `configuracoes`, `promocoes` e
     `promocao_produtos`;
   - as políticas de RLS (leitura/escrita liberadas — veja a nota de
     segurança abaixo);
   - o bucket de Storage `essence-uploads` (público) com políticas para
     upload/leitura de imagens;
   - o registro único de `configuracoes` (id = 1) e as 4 categorias padrão.
3. Em **Project Settings → API**, copie a **Project URL** e a chave
   **anon public**.

## 2. Configurar o frontend

Em `frontend/`, copie `supabase-config.example.js` para `supabase-config.js`
e preencha:

```js
window.SUPABASE_URL = "https://SEU-PROJETO.supabase.co";
window.SUPABASE_ANON_KEY = "SUA_CHAVE_ANON_PUBLICA_AQUI";
```

Esse arquivo é carregado tanto por `index.html` quanto por `admin.html`.
Nunca coloque a chave **service_role** aqui — apenas a **anon public**, que é
segura para uso no navegador (o acesso é controlado pelas políticas de RLS).

## 3. Rodar localmente

Como agora é só HTML/CSS/JS estático, basta servir a pasta `frontend/` com
qualquer servidor HTTP simples, por exemplo:

```bash
cd frontend
npx serve .
# ou: python3 -m http.server 5500
```

- Catálogo: `http://localhost:5500/index.html`
- Painel administrativo: `http://localhost:5500/admin.html`

Nenhum produto fictício é criado — o catálogo nasce vazio, pronto para
receber os produtos reais cadastrados pelo painel.

## Como adicionar produtos

1. Acesse `admin.html` → menu **Produtos** → **Novo Produto**.
2. Preencha nome, categoria, marca, descrição, preço (e preço promocional,
   se houver), estoque, status, e envie uma imagem (JPG, PNG, WEBP ou GIF).
   A imagem é enviada para o bucket `essence-uploads` no Supabase Storage.
3. Marque "Destaque" se quiser que apareça na vitrine da Home.
4. Salvar — o produto é gravado na tabela `produtos` e aparece imediatamente
   no catálogo público (produtos com status "Esgotado/Inativo" não aparecem
   na loja, só no painel).

Categorias e promoções seguem o mesmo padrão, nos menus **Categorias** e
**Promoções** do painel (uma promoção associa um desconto a um conjunto de
produtos e um período de vigência, usando a tabela associativa
`promocao_produtos`).

## Como alterar banners, logo e cores

No painel, menu **Configurações**:

- **Logo** e **Banner**: envie uma nova imagem — substitui a atual no
  Storage e atualiza o registro único da tabela `configuracoes`.
- **Cor principal**: escolha no seletor de cor (aplicada em tempo real no
  catálogo).

## Como alterar o WhatsApp, Instagram, endereço e horário

Também em **Configurações**. O número de WhatsApp deve incluir o DDI e DDD
(ex.: `5511999999999`) — é para esse número que o botão "Finalizar pedido"
do carrinho abre a conversa no WhatsApp, com a lista de itens já formatada.

## Segurança

- Escape de HTML em todo conteúdo vindo do banco antes de ser inserido na
  página (proteção contra XSS armazenado via nome/descrição de produtos).
- RLS habilitado em todas as tabelas do Supabase.
- **Importante:** como o login do painel é uma simulação (sem autenticação
  real — o mesmo comportamento que o backend Node anterior já tinha, que não
  exigia login em nenhuma rota da API), as políticas de RLS deste projeto
  liberam leitura e escrita para a chave `anon`. Isso significa que qualquer
  pessoa com a URL e a chave anon do projeto (ambas públicas, pois vão para
  o navegador) consegue alterar os dados diretamente pela API do Supabase,
  sem passar pelo painel. Antes de usar em produção de verdade, configure o
  **Supabase Auth** e restrinja as políticas de escrita (`insert`/`update`/
  `delete`) ao papel `authenticated`, adicionando um login real ao
  `admin.html`.
- Upload de imagem: o bucket `essence-uploads` é público (necessário para o
  catálogo exibir as imagens), então qualquer arquivo enviado por ele fica
  acessível por URL direta — mesmo comportamento que a pasta `/uploads`
  pública do backend anterior.

## PWA — instalação como aplicativo

O catálogo pode ser instalado como app:

- **Android (Chrome)**: menu ⋮ → "Adicionar à tela inicial" / banner de instalação automático.
- **iPhone (Safari)**: botão compartilhar → "Adicionar à Tela de Início".
- **Desktop (Chrome/Edge)**: ícone de instalação na barra de endereço.

Isso funciona porque o projeto inclui `manifest.json`, ícones em vários
tamanhos e um service worker (`service-worker.js`) que cacheia o app shell
para carregamento rápido e uso offline parcial.

## SEO

`index.html` inclui meta description, Open Graph, Twitter Card, favicons e
título/descrição otimizados. `robots.txt` e `sitemap.xml` já estão
preparados na raiz do frontend — troque `https://seudominio.com.br` pela URL
final do site em `sitemap.xml` após o deploy. O painel (`admin.html`) usa
`noindex` para não aparecer em buscadores.

## Observação sobre Pedidos e Clientes no painel

As telas **Pedidos** e **Clientes** do painel continuam exibindo dados de
demonstração (mock) — não fazem parte do escopo deste banco de dados. O
fluxo de venda atual é "carrinho → WhatsApp": o pedido é formatado e enviado
direto para o WhatsApp da loja, sem gravar no Supabase. Para registrar
pedidos formalmente, seria necessário criar uma tabela `pedidos` no Supabase
e as consultas correspondentes no `admin.html` — uma expansão futura natural
sobre a estrutura atual.

## Publicando o projeto (deploy)

Agora que o frontend é 100% estático (fala direto com o Supabase), qualquer
serviço de hospedagem de arquivos estáticos funciona:

### Netlify / Vercel
1. Suba o projeto para um repositório Git (o arquivo `supabase-config.js`
   está no `.gitignore` — não será versionado).
2. Conecte o repositório na Netlify ou Vercel — os arquivos `netlify.toml` /
   `vercel.json` na raiz já apontam para a pasta `frontend/`.
3. Nas variáveis de ambiente/configuração de build do serviço (ou editando
   `supabase-config.js` antes do deploy), garanta que `SUPABASE_URL` e
   `SUPABASE_ANON_KEY` estejam preenchidos no arquivo publicado.

### Qualquer outro host estático (GitHub Pages, Cloudflare Pages, S3, etc.)
Basta publicar o conteúdo da pasta `frontend/` — não há build nem servidor
para configurar.

## Banco de dados

Postgres gerenciado pelo Supabase. Tabelas: `produtos`, `categorias`,
`configuracoes` (registro único, id = 1), `promocoes` e a tabela associativa
`promocao_produtos`. Veja a estrutura completa e comentada em
`supabase/schema.sql`.

## Frontend

- **Painel (`admin.html`)**: Dashboard com estatísticas, Produtos,
  Categorias, Promoções e Configurações — tudo lendo e gravando no Supabase
  via `supabase-js`. Upload de imagem real (Supabase Storage) para logo,
  banner e produtos.
- **Catálogo (`index.html`)**: Home, categorias, banner, promoções, busca,
  detalhes de produto, favoritos e carrinho — 100% carregados do Supabase.
  Instalável como PWA, com lazy loading de imagens, toasts de feedback e
  botão "voltar ao topo". Carrinho e favoritos ficam em `localStorage`; o
  pedido final é enviado formatado para o WhatsApp configurado no painel.
