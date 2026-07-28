/* EMC Contract Intake & Risk Review — offline service worker.
   Caches the app shell for offline use. Never touches cross-origin requests,
   so the AI review's calls to the Anthropic API always go straight to network. */
const CACHE = 'emc-review-v1';
const CORE = [
  './', './index.html', './app.html', './manifest.webmanifest',
  './assets/hero.jpg',
  './vendor/pdf.min.js', './vendor/pdf.worker.min.js',
  './icons/icon-192.png', './icons/icon-512.png', './icons/apple-touch-icon.png'
];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE)
      .then(c => Promise.allSettled(CORE.map(u => c.add(u))))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  // Only handle same-origin GETs — leave api.anthropic.com and every other host alone.
  if (url.origin !== location.origin) return;
  e.respondWith(
    caches.match(req).then(hit =>
      hit || fetch(req).then(resp => {
        const copy = resp.clone();
        caches.open(CACHE).then(c => c.put(req, copy)).catch(() => {});
        return resp;
      }).catch(() => caches.match('./app.html'))
    )
  );
});
