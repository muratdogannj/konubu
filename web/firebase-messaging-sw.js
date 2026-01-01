importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Firebase configuration - from firebase_options.dart
firebase.initializeApp({
    apiKey: "AIzaSyDvbSaRqNuRTqEMUDXBzL2NvbmZlc3Npb25zIjoiZGVkaWtvZHVwcm9qZXNpIiwiY29sbGVjdGlvbklkIjoiY29uZmVzc2lvbnMiLCJwcm9qZWN0SWQiOiJ0aXJhZi1mOWNjNiJ9",
    authDomain: "tiraf-f9cc6.firebaseapp.com",
    projectId: "tiraf-f9cc6",
    storageBucket: "tiraf-f9cc6.firebasestorage.app",
    messagingSenderId: "1029063667894",
    appId: "1:1029063667894:web:0a6f7e5e5e5e5e5e5e5e5e"
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
    console.log('Received background message:', payload);

    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
        icon: '/icons/Icon-192.png',
        badge: '/icons/Icon-192.png',
        data: payload.data
    };

    return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification click
self.addEventListener('notificationclick', (event) => {
    console.log('Notification clicked:', event);
    event.notification.close();

    // Open the app or navigate to confession
    const confessionId = event.notification.data?.confessionId;
    const urlToOpen = confessionId
        ? `${self.location.origin}/#/confession/${confessionId}`
        : self.location.origin;

    event.waitUntil(
        clients.matchAll({ type: 'window', includeUncontrolled: true })
            .then((clientList) => {
                // Check if there's already a window open
                for (const client of clientList) {
                    if (client.url === urlToOpen && 'focus' in client) {
                        return client.focus();
                    }
                }
                // Open new window
                if (clients.openWindow) {
                    return clients.openWindow(urlToOpen);
                }
            })
    );
});
