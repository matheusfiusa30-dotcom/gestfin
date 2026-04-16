// Service Worker mínimo — necessário para PWA
// Não faz cache agressivo para não quebrar updates do app

const CACHE_NAME = 'gestfin-v1';

self.addEventListener('install', (event) => {
  // Ativa imediatamente sem esperar
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  // Toma controle imediato de todas as páginas abertas
  event.waitUntil(clients.claim());
  // Limpa caches antigos
  event.waitUntil(
    caches.keys().then((names) =>
      Promise.all(names.filter((n) => n !== CACHE_NAME).map((n) => caches.delete(n)))
    )
  );
});

self.addEventListener('fetch', (event) => {
  // Network-first: sempre tenta buscar da rede primeiro
  // Só usa cache se offline (para que updates sejam sempre aplicados)
  const req = event.request;
  if (req.method !== 'GET') return;

  event.respondWith(
    fetch(req)
      .then((response) => {
        // Cacheia apenas assets estáticos (não APIs do Supabase)
        if (req.url.includes('supabase.co') || req.url.includes('mercadopago')) {
          return response;
        }
        if (response.ok) {
          const clone = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(req, clone));
        }
        return response;
      })
      .catch(() => caches.match(req))
  );
});
