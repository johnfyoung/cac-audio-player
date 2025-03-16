// service-worker.js
const CACHE_NAME = "mossback-player-v1";
const urlsToCache = [
  "/",
  "/index.html",
  "/playlists.json",
  "/audio-player-logo.png",
  "/favicon.png",
  "/manifest.json",
  "/icons/icon-72x72.png",
  "/icons/icon-96x96.png",
  "/icons/icon-128x128.png",
  "/icons/icon-144x144.png",
  "/icons/icon-152x152.png",
  "/icons/icon-192x192.png",
  "/icons/icon-256x256.png",
  "/icons/icon-512x512.png",
  // External resources
  "https://fonts.googleapis.com/css2?family=Bowlby+One&display=swap",
  "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css",
];

// Add a separate array for font files that will be cached on demand
const fontResources = [
  "https://fonts.gstatic.com/s/",
  "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/",
];

// The install event - cache our basic files
self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(urlsToCache);
    })
  );
});

// The fetch event - handle requests
self.addEventListener("fetch", (event) => {
  // Special handling for font files - cache-on-demand
  const url = event.request.url;
  const isFontFile = fontResources.some((fontUrl) => url.includes(fontUrl));

  if (isFontFile) {
    // For font files, use a cache-first-then-network strategy with dynamic caching
    event.respondWith(
      caches.match(event.request).then((response) => {
        // Return cached response if we have one
        if (response) {
          return response;
        }

        // Otherwise fetch from network and cache
        return fetch(event.request).then((networkResponse) => {
          // Don't cache errors
          if (!networkResponse || networkResponse.status !== 200) {
            return networkResponse;
          }

          // Clone the response to save a copy in cache
          const responseToCache = networkResponse.clone();

          caches.open(CACHE_NAME).then((cache) => {
            cache.put(event.request, responseToCache);
          });

          return networkResponse;
        });
      })
    );
    return;
  }

  // Check if this is an audio file request - don't cache these
  if (url.includes("/audio/")) {
    // Skip the cache for audio files - let them go straight to network
    return;
  }

  // For other assets, use the cache-first strategy
  event.respondWith(
    caches.match(event.request).then((response) => {
      return (
        response ||
        fetch(event.request).then((networkResponse) => {
          // Don't bother caching responses from external sources that aren't fonts
          // (which we handle in the separate condition above)
          if (url.startsWith(self.location.origin)) {
            const responseToCache = networkResponse.clone();
            caches.open(CACHE_NAME).then((cache) => {
              cache.put(event.request, responseToCache);
            });
          }
          return networkResponse;
        })
      );
    })
  );
});
