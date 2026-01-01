// Temporary script to fix user statistics
// Run this in Firebase Console > Firestore > Rules playground or use Firebase CLI

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function fixUserStats(userId) {
    console.log('Fixing stats for user:', userId);

    // Count confessions
    const confessionsSnapshot = await db.collection('confessions')
        .where('userId', '==', userId)
        .where('status', '==', 'approved')
        .get();
    const confessionCount = confessionsSnapshot.size;
    console.log('Confessions:', confessionCount);

    // Count likes received on confessions
    const confessionIds = confessionsSnapshot.docs.map(doc => doc.id);
    let totalLikesReceived = 0;

    if (confessionIds.length > 0) {
        for (let i = 0; i < confessionIds.length; i += 10) {
            const batch = confessionIds.slice(i, i + 10);
            const likesSnapshot = await db.collection('likes')
                .where('targetType', '==', 'confession')
                .where('targetId', 'in', batch)
                .get();
            totalLikesReceived += likesSnapshot.size;
        }
    }

    // Count likes received on comments
    const commentsSnapshot = await db.collectionGroup('comments')
        .where('authorId', '==', userId)
        .where('status', '==', 'approved')
        .get();

    const commentIds = commentsSnapshot.docs.map(doc => doc.id);

    if (commentIds.length > 0) {
        for (let i = 0; i < commentIds.length; i += 10) {
            const batch = commentIds.slice(i, i + 10);
            const likesSnapshot = await db.collection('likes')
                .where('targetType', '==', 'comment')
                .where('targetId', 'in', batch)
                .get();
            totalLikesReceived += likesSnapshot.size;
        }
    }

    const totalCommentsGiven = commentsSnapshot.size;

    console.log('Total Likes Received:', totalLikesReceived);
    console.log('Total Comments Given:', totalCommentsGiven);

    // Update user document
    await db.collection('users').doc(userId).update({
        confessionCount,
        totalLikesReceived,
        totalCommentsGiven,
        statsLastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log('✅ Stats updated successfully!');

    return {
        confessionCount,
        totalLikesReceived,
        totalCommentsGiven
    };
}

// Run for your user
fixUserStats('IxeBuDndTlVMLuv17uWH6pq5ADn1')
    .then(stats => {
        console.log('Final stats:', stats);
        process.exit(0);
    })
    .catch(error => {
        console.error('Error:', error);
        process.exit(1);
    });
