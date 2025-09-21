// Placeholder service worker for Firebase Web Messaging.
// Replace with the generated content or proper config when enabling web push.
// See: https://firebase.google.com/docs/cloud-messaging/js/receive

self.addEventListener('install', (event) => {
  // Skip waiting to activate new service worker immediately
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  // Claim clients so updates take effect immediately
  event.waitUntil(self.clients.claim());
});
