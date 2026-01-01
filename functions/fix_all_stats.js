const admin = require('firebase-admin');

// Initialize with your service account
admin.initializeApp();
const db = admin.firestore();

async function fixAllUserStats() {
    console.log('🔄 Starting to fix all user statistics...\n');

    try {
        // Get all users
        const usersSnapshot = await db.collection('users').get();
        console.log(`Found ${usersSnapshot.size} users\n`);

        let fixed = 0;
        let errors = 0;

        for (const userDoc of usersSnapshot.docs) {
            const userId = userDoc.id;
            const userData = userDoc.data();

            try {
                console.log(`Processing user: ${userData.username || userId}`);

                // Count confessions
                const confessionsSnapshot = await db.collection('confessions')
                    .where('userId', '==', userId)
                    .where('status', '==', 'approved')
                    .get();
                const confessionCount = confessionsSnapshot.size;

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

                // Update user document
                await db.collection('users').doc(userId).update({
                    confessionCount,
                    totalLikesReceived,
                    totalCommentsGiven,
                    statsLastUpdated: admin.firestore.FieldValue.serverTimestamp()
                });

                console.log(`  ✅ Updated: Confessions=${confessionCount}, Likes=${totalLikesReceived}, Comments=${totalCommentsGiven}\n`);
                fixed++;

            } catch (error) {
                console.error(`  ❌ Error for user ${userId}:`, error.message, '\n');
                errors++;
            }
        }

        console.log('\n' + '='.repeat(50));
        console.log(`✅ Successfully fixed: ${fixed} users`);
        console.log(`❌ Errors: ${errors} users`);
        console.log('='.repeat(50));

    } catch (error) {
        console.error('Fatal error:', error);
        process.exit(1);
    }

    process.exit(0);
}

// Run the script
fixAllUserStats();
