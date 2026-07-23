/* ================================================================
   ESSENCE TABACARIA — SERVICE WORKER
   Estratégia:
     - App shell (HTML/CSS/JS/ícones): cache-first, com atualização em segundo plano.
     - Supabase REST (*.supabase.co/rest/...): network-only, sem cache —
       garante que produtos/preços/estoque nunca fiquem desatualizados.
     - Imagens do Supabase Storage e demais imagens: cache-first (economiza dados no celular).
   ================================================================ */
const CACHE_VERSION = 'essence-v1';
const APP_SHELL_CACHE = `${CACHE_VERSION}-shell`;
const RUNTIME_CACHE = `${CACHE_VERSION}-runtime`;

const APP_SHELL = [
  '/',
  '/index.html',
  '/manifest.json',
  '/assets/icons/icon-192.png',
  '/assets/icons/icon-512.png',
  '/assets/icons/apple-touch-icon.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(APP_SHELL_CACHE)
      .then((cache) => cache.addAll(APP_SHELL))
      .catch(() => null) // não falha a instalação se algum item não puder ser cacheado agora
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((chaves) => Promise.all(
      chaves
        .filter((chave) => chave.startsWith('essence-') && chave !== APP_SHELL_CACHE && chave !== RUNTIME_CACHE)
        .map((chave) => caches.delete(chave))
    ))
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const { request } = event;
  if (request.method !== 'GET') return; // não intercepta POST/PUT/DELETE (gravações no Supabase)

  const url = new URL(request.url);
  const ehSupabase = url.hostname.endsWith('.supabase.co');

  // Dados do Supabase (tabelas via REST): não intercepta — sempre busca na
  // rede, para nunca exibir produtos/preços/estoque desatualizados.
  if (ehSupabase && url.pathname.startsWith('/rest/')) {
    return;
  }

  // Imagens do Supabase Storage e demais imagens: cache-first (menos consumo de dados)
  if ((ehSupabase && url.pathname.startsWith('/storage/')) || request.destination === 'image') {
    event.respondWith(
      caches.match(request).then((cacheado) => cacheado || fetch(request).then((resposta) => {
        const clone = resposta.clone();
        caches.open(RUNTIME_CACHE).then((cache) => cache.put(request, clone));
        return resposta;
      }).catch(() => cacheado))
    );
    return;
  }

  // Qualquer outra origem externa (ex.: CDN do supabase-js, Google Fonts):
  // deixa o navegador cuidar normalmente, sem passar pelo cache do app.
  if (url.origin !== self.location.origin) return;

  // App shell (HTML/CSS/JS): cache-first com atualização em segundo plano
  event.respondWith(
    caches.match(request).then((cacheado) => {
      const buscaRede = fetch(request).then((resposta) => {
        caches.open(APP_SHELL_CACHE).then((cache) => cache.put(request, resposta.clone()));
        return resposta;
      }).catch(() => cacheado);
      return cacheado || buscaRede;
    })
  );
});
