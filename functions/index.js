// Forced Update: 2025-12-25 09:22
const { onDocumentCreated, onDocumentDeleted } = require('firebase-functions/v2/firestore');
const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onCall } = require('firebase-functions/v2/https');
const { setGlobalOptions } = require('firebase-functions/v2');
const admin = require('firebase-admin');

admin.initializeApp();

// Set region to match Firestore database (eur3 = europe-west1)
setGlobalOptions({ region: 'europe-west1' });

/**
 * Send push notification when a new confession is created
 */
/**
 * Send push notification when a new confession is created
 */
exports.sendNewConfessionNotification = onDocumentCreated(
    {
        document: 'confessions/{confessionId}',
        region: 'europe-west1'
    },
    async (event) => {
        const confession = event.data.data();
        const confessionId = event.params.confessionId;

        console.log('🔔 New confession created:', confessionId);
        console.log('📍 City:', confession.cityName, 'Code:', confession.cityPlateCode);

        // No approval system -> Send notification immediately
        return sendConfessionNotification(confession, confessionId);
    }
);

/**
 * Send push notification when confession status changes to approved
 */
exports.sendConfessionApprovedNotification = onDocumentUpdated(
    {
        document: 'confessions/{confessionId}',
        region: 'europe-west1'
    },
    async (event) => {
        const before = event.data.before.data();
        const after = event.data.after.data();
        const confessionId = event.params.confessionId;

        console.log('📝 Confession updated:', confessionId);
        console.log('Status change:', before.status, '->', after.status);

        // Check if status changed to approved
        if (before.status !== 'approved' && after.status === 'approved') {
            console.log('✅ Confession approved, sending notification.');
            return sendConfessionNotification(after, confessionId);
        }

        return null;
    }
);

/**
 * Send notification to users
 */
async function sendConfessionNotification(confession, confessionId) {
    try {
        const db = admin.firestore();

        // Helper for Turkish suffixes
        const getTurkishSuffix = (word, suffixType) => {
            if (!word) return '';
            const lastLetter = word.trim().slice(-1).toLowerCase();
            const vowels = 'aeıioöuü';
            const hardConsonants = 'fstkçşhp';

            // Find last vowel for harmony
            let lastVowel = 'e'; // default
            for (let i = word.length - 1; i >= 0; i--) {
                if (vowels.includes(word[i].toLowerCase())) {
                    lastVowel = word[i].toLowerCase();
                    break;
                }
            }

            const isBackVowel = 'aıou'.includes(lastVowel); // a, ı, o, u -> a
            const isHardConsonant = hardConsonants.includes(lastLetter);

            if (suffixType === 'locative') { // -de/-da/-te/-ta (in/at)
                const consonant = isHardConsonant ? 't' : 'd';
                const vowel = isBackVowel ? 'a' : 'e';
                return `'${consonant}${vowel}`;
            }

            return '';
        };

        const cityName = confession.cityName || 'Şehir';
        const suffix = getTurkishSuffix(cityName, 'locative'); // 'da, 'de, 'ta, 'te

        // Build notification payload
        const notification = {
            title: `${cityName}${suffix} Yeni KonuBu!`,
            body: truncateText(confession.content, 100),
        };

        const data = {
            confessionId: confessionId,
            type: 'new_confession',
            cityPlateCode: String(confession.cityPlateCode),
        };

        console.log('Notification Payload:', notification);

        // Ensure plate code is integer for query (Model saves as int)
        const plateCodeInt = parseInt(confession.cityPlateCode);
        if (isNaN(plateCodeInt)) {
            console.error('Invalid plate code:', confession.cityPlateCode);
            return null;
        }

        // Query: Users following this city (Check Number, String "1", and String "01" formats)
        const cityFollowersQueryInt = db.collection('users')
            .where('notificationsEnabled', '==', true)
            .where('subscribedCities', 'array-contains', plateCodeInt);

        const cityFollowersQueryStr = db.collection('users')
            .where('notificationsEnabled', '==', true)
            .where('subscribedCities', 'array-contains', String(plateCodeInt));

        const queries = [cityFollowersQueryInt.get(), cityFollowersQueryStr.get()];

        // If plate is single digit (1-9), also check zero-padded version ("01" - "09")
        if (plateCodeInt < 10) {
            const paddedPlate = '0' + plateCodeInt;
            const cityFollowersQueryPadded = db.collection('users')
                .where('notificationsEnabled', '==', true)
                .where('subscribedCities', 'array-contains', paddedPlate);
            queries.push(cityFollowersQueryPadded.get());
        }

        const snapshots = await Promise.all(queries);

        console.log(`Found ${snapshots.reduce((acc, s) => acc + s.size, 0)} potential city followers`);

        // Collect FCM tokens
        const tokens = [];
        const tokenSet = new Set(); // Avoid duplicates

        const processDocs = (docs) => {
            docs.forEach((doc) => {
                // Skip the author of the confession
                if (doc.id === confession.authorId) return;

                const user = doc.data();
                const notifyCity = user.notifyOnCityConfession !== false;

                if (notifyCity && user.fcmToken && !tokenSet.has(user.fcmToken)) {
                    tokens.push(user.fcmToken);
                    tokenSet.add(user.fcmToken);
                }
            });
        };

        snapshots.forEach(s => processDocs(s.docs));

        console.log(`Collected ${tokens.length} unique tokens to send`);

        if (tokens.length === 0) {
            console.log('No eligible tokens found.');
            return null;
        }

        // Send notifications in batches
        const batchSize = 500;
        const batches = [];
        for (let i = 0; i < tokens.length; i += batchSize) {
            batches.push(tokens.slice(i, i + batchSize));
        }

        const results = await Promise.all(
            batches.map((batchTokens) =>
                admin.messaging().sendEachForMulticast({
                    tokens: batchTokens,
                    notification: notification,
                    data: data,
                    android: {
                        priority: 'high',
                        notification: { channelId: 'konubu_channel' },
                    },
                    apns: {
                        payload: { aps: { sound: 'default', badge: 1 } },
                    },
                })
            )
        );

        // Log results and clean up invalid tokens...
        let successCount = 0;
        let failureCount = 0;
        const invalidTokens = [];

        results.forEach((result, batchIndex) => {
            successCount += result.successCount;
            failureCount += result.failureCount;

            result.responses.forEach((response, idx) => {
                if (!response.success) {
                    const error = response.error;
                    if (error.code === 'messaging/invalid-registration-token' ||
                        error.code === 'messaging/registration-token-not-registered') {
                        invalidTokens.push(batches[batchIndex][idx]);
                    }
                }
            });
        });

        console.log(`Sent: ${successCount} success, ${failureCount} failed.`);

        // Remove invalid tokens
        if (invalidTokens.length > 0) {
            console.log(`Removing ${invalidTokens.length} invalid tokens.`);
            const batch = db.batch();
            const usersSnapshot = await db.collection('users')
                .where('fcmToken', 'in', invalidTokens.slice(0, 10))
                .get();

            usersSnapshot.forEach((doc) => {
                batch.update(doc.ref, { fcmToken: admin.firestore.FieldValue.delete() });
            });
            await batch.commit();
        }

        // Persist to Firestore (In-App Inbox)
        // Note: Firestore batch limit is 500.
        const writeBatches = [];
        let batch = db.batch();
        let operationCounter = 0;
        let persistedCount = 0;

        cityFollowersSnapshot.forEach((doc) => {
            const user = doc.data();
            const notifyCity = user.notifyOnCityConfession !== false;

            // Save to inbox if user wants notifications (even if no token, they might check app manually)
            // or strictly following notifyCity pref.
            if (notifyCity) {
                const newRef = db.collection('notifications').doc();
                batch.set(newRef, {
                    userId: doc.id,
                    title: notification.title,
                    body: notification.body,
                    confessionId: confessionId,
                    cityName: cityName,
                    type: 'new_city_confession',
                    isRead: false,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                });

                operationCounter++;
                persistedCount++;

                if (operationCounter === 499) {
                    writeBatches.push(batch.commit());
                    batch = db.batch();
                    operationCounter = 0;
                }
            }
        });

        // Commit remaining
        if (operationCounter > 0) {
            writeBatches.push(batch.commit());
        }

        await Promise.all(writeBatches);
        console.log(`✅ Persisted ${persistedCount} notifications to Firestore.`);

        return { success: successCount, failed: failureCount, persisted: persistedCount };
    } catch (error) {
        console.error('Error sending confession notification:', error);
        throw error;
    }
}

/**
 * Send notification when user receives a comment or reply
 */
exports.sendCommentNotification = onDocumentCreated(
    {
        document: 'confessions/{confessionId}/comments/{commentId}',
        region: 'europe-west1'
    },
    async (event) => {
        const comment = event.data.data();
        const confessionId = event.params.confessionId;
        const commentId = event.params.commentId;

        console.log('💬 New comment created. ID:', commentId, 'Confession:', confessionId);

        try {
            const db = admin.firestore();
            let targetUserId;
            let notificationTitle;
            let notificationType;
            let checkPreference;

            // Check if this is a reply
            if (comment.parentId) {
                console.log('This is a reply to comment:', comment.parentId);
                // Fetch parent comment from the SAME subcollection logic
                const parentCommentDoc = await db.collection('confessions')
                    .doc(confessionId)
                    .collection('comments')
                    .doc(comment.parentId)
                    .get();

                if (parentCommentDoc.exists) {
                    targetUserId = parentCommentDoc.data().authorId || parentCommentDoc.data().userId;
                    notificationTitle = 'Yorumuna yanıt geldi!';
                    notificationType = 'new_reply';
                    checkPreference = (user) => user.notifyOnReply !== false;
                } else {
                    console.log('Parent comment not found, checking top-level fallback...');
                    // Fallback check if comment moved or logic differs (unlikely)
                    return null;
                }
            } else {
                // Top-level comment -> Notify Confession Author
                const confessionDoc = await db.collection('confessions').doc(confessionId).get();
                if (confessionDoc.exists) {
                    targetUserId = confessionDoc.data().authorId || confessionDoc.data().userId;
                    notificationTitle = 'Konuna yeni yorum!';
                    notificationType = 'new_comment';
                    checkPreference = (user) => user.notifyOnComment !== false;
                } else {
                    console.log('Confession not found:', confessionId);
                    return null;
                }
            }

            if (!targetUserId) {
                console.log('Target user ID not found.');
                return null;
            }

            // Don't notify if user acted on their own content
            if (targetUserId === comment.authorId || targetUserId === comment.userId) {
                console.log('User commented on own content, skipping notification.');
                return null;
            }

            // Get target user details
            const userDoc = await db.collection('users').doc(targetUserId).get();
            if (!userDoc.exists) {
                console.log('Target user profile not found:', targetUserId);
                return null;
            }

            const user = userDoc.data();
            if (!user.fcmToken || !user.notificationsEnabled) {
                console.log('User has no token or notifications disabled.');
                return null;
            }

            if (!checkPreference(user)) {
                console.log(`User disabled ${notificationType} notifications.`);
                return null;
            }

            // Send FCM
            await admin.messaging().send({
                token: user.fcmToken,
                notification: {
                    title: notificationTitle,
                    body: truncateText(comment.content, 100),
                },
                data: {
                    confessionId: confessionId,
                    type: notificationType,
                    commentId: commentId,
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                },
                android: {
                    priority: 'high',
                    notification: { channelId: 'konubu_channel' }
                },
                apns: {
                    payload: { aps: { sound: 'default', badge: 1 } }
                }
            });

            // Persist to Firestore for In-App Notification Area
            await db.collection('notifications').add({
                userId: targetUserId,
                title: notificationTitle,
                body: truncateText(comment.content, 100),
                confessionId: confessionId,
                commentId: commentId,
                type: notificationType,
                isRead: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                SenderId: comment.authorId || comment.userId, // Who triggered it
            });

            console.log(`✅ ${notificationType} sent and saved for ${user.username || targetUserId}`);
            return { success: true };

        } catch (error) {
            console.error('Error sending comment notification:', error);
            throw error;
        }
    }
);

// ==================== USER STATISTICS TRIGGERS ====================

/**
 * Update view stats when a confession view count changes
 */
exports.onViewStatsUpdated = onDocumentUpdated(
    {
        document: 'confessions/{confessionId}',
        region: 'europe-west1'
    },
    async (event) => {
        const before = event.data.before.data();
        const after = event.data.after.data();
        const confessionId = event.params.confessionId;

        // Check if viewCount changed
        const viewsBefore = before.viewCount || 0;
        const viewsAfter = after.viewCount || 0;

        if (viewsAfter <= viewsBefore) {
            return null; // No new views or view count decreased (shouldn't happen)
        }

        const viewDifference = viewsAfter - viewsBefore;
        const authorId = after.authorId;

        if (!authorId) {
            console.log('No authorId found for view update');
            return null;
        }

        console.log(`👀 View count increased by ${viewDifference} for confession: ${confessionId}`);

        try {
            await admin.firestore().collection('users').doc(authorId).update({
                totalViewsReceived: admin.firestore.FieldValue.increment(viewDifference)
            });
            console.log('✅ User totalViewsReceived updated');
        } catch (error) {
            console.error('Error updating user view stats:', error);
        }

        return null;
    }
);

/**
 * Update confession count when a confession is created
 */
exports.onConfessionCreated = onDocumentCreated(
    {
        document: 'confessions/{confessionId}',
        region: 'europe-west1'
    },
    async (event) => {
        const confession = event.data.data();
        const authorId = confession.authorId;

        if (!authorId) {
            console.log('No authorId found');
            return null;
        }

        console.log('📊 Incrementing confession count for user:', authorId);

        try {
            // Also add initial views if any (though usually 0 on create)
            const initialViews = confession.viewCount || 0;

            await admin.firestore().collection('users').doc(authorId).update({
                confessionCount: admin.firestore.FieldValue.increment(1),
                totalViewsReceived: admin.firestore.FieldValue.increment(initialViews)
            });
            console.log('✅ Confession count and initial views incremented');
        } catch (error) {
            console.error('Error updating confession count:', error);
        }

        return null;
    }
);

/**
 * Update confession count when a confession is deleted
 */
exports.onConfessionDeleted = onDocumentDeleted(
    {
        document: 'confessions/{confessionId}',
        region: 'europe-west1'
    },
    async (event) => {
        const confession = event.data.data();
        const authorId = confession.authorId;

        if (!authorId) {
            console.log('No authorId found');
            return null;
        }

        console.log('📊 Decrementing confession count for user:', authorId);

        try {
            // Subtract the views of the deleted confession
            const viewstoSubtract = confession.viewCount || 0;

            await admin.firestore().collection('users').doc(authorId).update({
                confessionCount: admin.firestore.FieldValue.increment(-1),
                totalViewsReceived: admin.firestore.FieldValue.increment(-viewstoSubtract)
            });
            console.log(`✅ Confession count decremented and ${viewstoSubtract} views removed`);
        } catch (error) {
            console.error('Error updating confession count:', error);
        }

        return null;
    }
);

/**
 * Update like stats when a like is created
 */
exports.onLikeCreated = onDocumentCreated(
    {
        document: 'likes/{likeId}',
        region: 'europe-west1'
    },
    async (event) => {
        const like = event.data.data();
        const { targetType, targetId } = like;

        console.log('❤️ Like created:', { targetType, targetId });

        try {
            const db = admin.firestore();
            let authorId = null;

            // Find the author of the liked content
            if (targetType === 'confession') {
                const confessionDoc = await db.collection('confessions').doc(targetId).get();
                if (confessionDoc.exists) {
                    authorId = confessionDoc.data().authorId;
                }
            } else if (targetType === 'comment') {
                // Try to find comment in both top-level and subcollection
                const commentQuery = await db.collectionGroup('comments')
                    .where(admin.firestore.FieldPath.documentId(), '==', targetId)
                    .limit(1)
                    .get();

                if (!commentQuery.empty) {
                    authorId = commentQuery.docs[0].data().authorId;
                }
            }

            if (authorId) {
                console.log('📊 Incrementing likes received for user:', authorId);
                const userRef = db.collection('users').doc(authorId);

                await userRef.update({
                    totalLikesReceived: admin.firestore.FieldValue.increment(1)
                });
                console.log('✅ Likes received incremented');

                console.log('✅ Likes received incremented');

                // SEND LIKE NOTIFICATION logic...
                // Only notify if not liking own content
                if (like.userId !== authorId) {
                    const userDoc = await db.collection('users').doc(authorId).get();
                    if (userDoc.exists) {
                        const user = userDoc.data();
                        if (user.fcmToken && user.notificationsEnabled && user.notifyOnLike !== false) {
                            const title = targetType === 'confession' ? 'Konun beğenildi! ❤️' : 'Yorumun beğenildi! ❤️';
                            const body = 'Birisi paylaşımını beğendi.';

                            // Send FCM
                            await admin.messaging().send({
                                token: user.fcmToken,
                                notification: {
                                    title: title,
                                    body: body,
                                },
                                data: {
                                    type: 'new_like',
                                    confessionId: targetId, // If comment, this prevents navigation unless we resolve comment's confession.
                                    // For comment likes, we might need parent confession ID to navigate properly.
                                    // But let's stick to basic logic first.
                                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                                },
                                android: { priority: 'high', notification: { channelId: 'konubu_channel' } }
                            });

                            // Persist to Firestore
                            await db.collection('notifications').add({
                                userId: authorId,
                                title: title,
                                body: body,
                                confessionId: targetType === 'confession' ? targetId : null, // Todo: better handling for comments
                                type: 'new_like',
                                isRead: false,
                                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                            });
                            console.log('✅ Like notification sent and saved.');
                        }
                    }
                }
            } else {
                console.log('⚠️ Author not found for liked content');
            }

            // NEW: Increment totalLikesGiven for the LIKER
            if (like.userId) {
                console.log('📊 Incrementing likes GIVEN for user:', like.userId);
                await db.collection('users').doc(like.userId).update({
                    totalLikesGiven: admin.firestore.FieldValue.increment(1)
                });
            }
        } catch (error) {
            console.error('Error updating like stats:', error);
        }

        return null;
    }
);

/**
 * Update like stats when a like is deleted
 */
exports.onLikeDeleted = onDocumentDeleted(
    {
        document: 'likes/{likeId}',
        region: 'europe-west1'
    },
    async (event) => {
        const like = event.data.data();
        const { targetType, targetId } = like;

        console.log('💔 Like deleted:', { targetType, targetId });

        try {
            const db = admin.firestore();
            let authorId = null;

            // Find the author of the unliked content
            if (targetType === 'confession') {
                const confessionDoc = await db.collection('confessions').doc(targetId).get();
                if (confessionDoc.exists) {
                    authorId = confessionDoc.data().authorId;
                }
            } else if (targetType === 'comment') {
                const commentQuery = await db.collectionGroup('comments')
                    .where(admin.firestore.FieldPath.documentId(), '==', targetId)
                    .limit(1)
                    .get();

                if (!commentQuery.empty) {
                    authorId = commentQuery.docs[0].data().authorId;
                }
            }

            if (authorId) {
                console.log('📊 Decrementing likes received for user:', authorId);
                await db.collection('users').doc(authorId).update({
                    totalLikesReceived: admin.firestore.FieldValue.increment(-1)
                });
                console.log('✅ Likes received decremented');
            } else {
                console.log('⚠️ Author not found for unliked content');
            }

            // NEW: Decrement totalLikesGiven for the UNLIKER
            if (like.userId) {
                console.log('📊 Decrementing likes GIVEN for user:', like.userId);
                await db.collection('users').doc(like.userId).update({
                    totalLikesGiven: admin.firestore.FieldValue.increment(-1)
                });
            }
        } catch (error) {
            console.error('Error updating like stats:', error);
        }

        return null;
    }
);

/**
 * Update comment count when a comment is created
 */
exports.onCommentCreated = onDocumentCreated(
    {
        document: '{path=**}/comments/{commentId}',
        region: 'europe-west1'
    },
    async (event) => {
        const comment = event.data.data();
        const authorId = comment.authorId;

        if (!authorId) {
            console.log('No authorId found in comment');
            return null;
        }

        console.log('💬 Incrementing comment count for user:', authorId);

        try {
            await admin.firestore().collection('users').doc(authorId).update({
                totalCommentsGiven: admin.firestore.FieldValue.increment(1)
            });
            console.log('✅ Comment count incremented');
        } catch (error) {
            console.error('Error updating comment count:', error);
        }

        return null;
    }
);

/**
 * Update comment count when a comment is deleted
 */
exports.onCommentDeleted = onDocumentDeleted(
    {
        document: '{path=**}/comments/{commentId}',
        region: 'europe-west1'
    },
    async (event) => {
        const comment = event.data.data();
        const authorId = comment.authorId;

        if (!authorId) {
            console.log('No authorId found in comment');
            return null;
        }

        console.log('💬 Decrementing comment count for user:', authorId);

        try {
            await admin.firestore().collection('users').doc(authorId).update({
                totalCommentsGiven: admin.firestore.FieldValue.increment(-1)
            });
            console.log('✅ Comment count decremented');
        } catch (error) {
            console.error('Error updating comment count:', error);
        }

        return null;
    }
);

/**
 * Send notification when a private message is received
 */
exports.onMessageCreated = onDocumentCreated(
    {
        document: 'private_messages/{conversationId}/messages/{messageId}',
        region: 'europe-west1'
    },
    async (event) => {
        const message = event.data.data();
        const conversationId = event.params.conversationId;
        const messageId = event.params.messageId;

        console.log('📩 New private message:', messageId, 'Conversation:', conversationId);

        try {
            const db = admin.firestore();
            const receiverId = message.receiverId;
            const senderName = message.senderName;

            if (!receiverId) {
                console.log('No receiverId found in message');
                return null;
            }

            // Get receiver details
            const userDoc = await db.collection('users').doc(receiverId).get();
            if (!userDoc.exists) {
                console.log('Receiver profile not found:', receiverId);
                return null;
            }

            const user = userDoc.data();
            if (!user.fcmToken || !user.notificationsEnabled) {
                console.log('User has no token or notifications disabled.');
                return null;
            }

            // Check notification preference
            if (user.notifyOnMessage === false) {
                console.log('User disabled message notifications.');
                return null;
            }

            // Decrypt/Format content for notification
            let bodyText = message.content;
            if (message.isImage) {
                bodyText = message.isOneTime ? '🔥 Tek kullanımlık fotoğraf' : '📷 Fotoğraf gönderdi';
            } else {
                // Truncate
                bodyText = truncateText(bodyText, 100);
            }

            // Send
            await admin.messaging().send({
                token: user.fcmToken,
                notification: {
                    title: `${senderName || 'Birisi'} mesaj gönderdi`,
                    body: bodyText,
                },
                data: {
                    type: 'new_message',
                    conversationId: conversationId,
                    senderId: message.senderId,
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                },
                android: {
                    priority: 'high',
                    notification: { channelId: 'konubu_channel' }
                },
                apns: {
                    payload: { aps: { sound: 'default', badge: 1 } }
                }
            });

            console.log(`✅ Message notification sent to ${user.username || receiverId}`);
            return { success: true };

        } catch (error) {
            console.error('Error sending message notification:', error);
            throw error;
        }
    }
);

/**
 * Helper function to truncate text
 */
function truncateText(text, length) {
    if (!text) return '';
    if (text.length <= length) return text;
    return text.substring(0, length) + '...';
}

/**
 * Callable function to recalculate user statistics
 * This is useful for fixing stats for existing users
 */
exports.recalculateUserStats = onCall(
    {
        region: 'europe-west1'
    },
    async (request) => {
        const userId = request.auth?.uid;

        if (!userId) {
            throw new Error('Authentication required');
        }

        console.log('🔄 Recalculating stats for user:', userId);

        try {
            const db = admin.firestore();

            // Count confessions
            const confessionsSnapshot = await db.collection('confessions')
                .where('authorId', '==', userId)
                .where('status', '==', 'approved')
                .get();
            const confessionCount = confessionsSnapshot.size;

            // Count likes received on confessions
            const confessionIds = confessionsSnapshot.docs.map(doc => doc.id);
            let totalLikesReceived = 0;

            if (confessionIds.length > 0) {
                // Firestore 'in' query limit is 10, so we need to batch
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

            // Count comments given
            const totalCommentsGiven = commentsSnapshot.size;

            // Update user document
            await db.collection('users').doc(userId).update({
                confessionCount,
                totalLikesReceived,
                totalCommentsGiven,
                statsLastUpdated: admin.firestore.FieldValue.serverTimestamp()
            });

            console.log('✅ Stats recalculated:', {
                confessionCount,
                totalLikesReceived,
                totalCommentsGiven
            });

            return {
                success: true,
                stats: {
                    confessionCount,
                    totalLikesReceived,
                    totalCommentsGiven
                }
            };
        } catch (error) {
            console.error('Error recalculating stats:', error);
            throw error;
        }
    }
);

/**
 * Admin-only callable function to recalculate ALL user statistics
 * WARNING: This is expensive and should only be run once to fix existing data
 */
exports.recalculateAllUserStats = onCall(
    {
        region: 'europe-west1'
    },
    async (request) => {
        // Only allow authenticated users (you can add admin check here)
        if (!request.auth) {
            throw new Error('Authentication required');
        }

        console.log('🔄 Starting to recalculate stats for ALL users...');

        try {
            const db = admin.firestore();

            // Get all users
            const usersSnapshot = await db.collection('users').get();
            console.log(`Found ${usersSnapshot.size} users`);

            const results = [];
            let successCount = 0;
            let errorCount = 0;

            for (const userDoc of usersSnapshot.docs) {
                const userId = userDoc.id;
                const userData = userDoc.data();

                try {
                    console.log(`Processing user: ${userData.username || userId}`);

                    // Count confessions
                    const confessionsSnapshot = await db.collection('confessions')
                        .where('authorId', '==', userId)
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

                    // Count comments given
                    const totalCommentsGiven = commentsSnapshot.size;

                    // Calculate total views received
                    let totalViewsReceived = 0;
                    confessionsSnapshot.forEach(doc => {
                        const data = doc.data();
                        totalViewsReceived += (data.viewCount || 0);
                    });

                    // Update user document
                    await db.collection('users').doc(userId).update({
                        confessionCount,
                        totalLikesReceived,
                        totalCommentsGiven,
                        totalViewsReceived,
                        statsLastUpdated: admin.firestore.FieldValue.serverTimestamp()
                    });

                    console.log(`✅ Updated ${userData.username || userId}: Confessions=${confessionCount}, Likes=${totalLikesReceived}, Comments=${totalCommentsGiven}, Views=${totalViewsReceived}`);

                    results.push({
                        userId,
                        username: userData.username,
                        confessionCount,
                        totalLikesReceived,
                        totalCommentsGiven,
                        totalViewsReceived,
                        success: true
                    });

                    successCount++;

                } catch (error) {
                    console.error(`❌ Error for user ${userId}:`, error);
                    results.push({
                        userId,
                        username: userData.username,
                        error: error.message,
                        success: false
                    });
                    errorCount++;
                }
            }

            console.log(`\n✅ Successfully updated: ${successCount} users`);
            console.log(`❌ Errors: ${errorCount} users`);

            return {
                success: true,
                totalUsers: usersSnapshot.size,
                successCount,
                errorCount,
                results
            };

        } catch (error) {
            console.error('Fatal error:', error);
            throw error;
        }
    }

);

/**
 * Debug function to inspect user data for notifications
 */
exports.debugUserForNotifications = onCall(
    { region: 'europe-west1' },
    async (request) => {
        // Authenticated users only
        if (!request.auth) {
            return { error: 'Unauthorized' };
        }

        const userId = request.auth.uid;
        const db = admin.firestore();
        const userDoc = await db.collection('users').doc(userId).get();

        if (!userDoc.exists) return { error: 'User not found' };

        const data = userDoc.data();

        return {
            userId: userId,
            notificationsEnabled: data.notificationsEnabled,
            notifyOnCityConfession: data.notifyOnCityConfession,
            // Return raw array to check types (01 vs 1)
            subscribedCities: data.subscribedCities || [],
            fcmTokenExists: !!data.fcmToken,
            tokenPrefix: data.fcmToken ? data.fcmToken.substring(0, 5) + '...' : 'NONE'
        };
    }
);


/**
 * Clean up user data when account is deleted
 */
const functions = require('firebase-functions');

exports.cleanupUserData = functions
    .region('europe-west1')
    .auth.user()
    .onDelete(async (user) => {
        const uid = user.uid;

        console.log(`🗑️ User deleted: ${uid}. Cleaning up data...`);

        const db = admin.firestore();
        const batch = db.batch();

        // 1. Delete User Document
        const userRef = db.collection('users').doc(uid);
        batch.delete(userRef);

        // 2. Delete User Profile Image from Storage (if exists)
        try {
            const bucket = admin.storage().bucket();
            await bucket.file(`user_profiles/${uid}.jpg`).delete();
            console.log(`🗑️ Deleted profile image for ${uid}`);
        } catch (e) {
            console.log(`⚠️ Could not delete profile image (might not exist): ${e.message}`);
        }

        await batch.commit();
        console.log(`✅ User data cleanup complete for ${uid}`);
    });
