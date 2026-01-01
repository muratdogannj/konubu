const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json'); // Assumes key is present, if not I'll try without if initialized

// Initialize app if not already
if (admin.apps.length === 0) {
    try {
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
    } catch (e) {
        console.log("Service key not found, trying default init (might fail locally without auth)");
        admin.initializeApp();
    }
}

const db = admin.firestore();

async function checkUser(emailOrId) {
    console.log(`Checking user: ${emailOrId}`);

    let userDoc;
    // Try as ID first
    let docRef = db.collection('users').doc(emailOrId);
    let docSnap = await docRef.get();

    if (docSnap.exists) {
        userDoc = docSnap;
    } else {
        // Try as email
        const q = await db.collection('users').where('email', '==', emailOrId).limit(1).get();
        if (!q.empty) {
            userDoc = q.docs[0];
        }
    }

    if (!userDoc) {
        console.log('❌ User not found');
        return;
    }

    const data = userDoc.data();
    console.log(`✅ User Found: ${userDoc.id}`);
    console.log(`- notificationsEnabled: ${data.notificationsEnabled} (${typeof data.notificationsEnabled})`);
    console.log(`- notifyOnCityConfession: ${data.notifyOnCityConfession} (${typeof data.notifyOnCityConfession})`);
    console.log(`- subscribedCities: ${JSON.stringify(data.subscribedCities)}`);
    console.log(`- subscribedCities types: ${data.subscribedCities ? data.subscribedCities.map(x => typeof x) : 'N/A'}`);
    console.log(`- fcmToken: ${data.fcmToken ? (data.fcmToken.substring(0, 10) + '...') : 'MISSING'}`);
}

// Replace with the user ID provided by user or use a known one if available
// I will ask user for their ID or Email if I can't find it
// For now, I'll list the first 5 users to sanity check the structure
async function listUsers() {
    const sn = await db.collection('users').limit(5).get();
    sn.docs.forEach(d => {
        const d_data = d.data();
        console.log(`User: ${d.id}, Cities: ${JSON.stringify(d_data.subscribedCities)}, Token: ${!!d_data.fcmToken}`);
    });
}

listUsers();
