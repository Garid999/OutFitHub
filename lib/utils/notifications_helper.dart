import 'package:cloud_firestore/cloud_firestore.dart';

class NotifHelper {
  static final _db = FirebaseFirestore.instance;

  // Write to a specific user
  static Future<void> sendToUser(
    String uid, {
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    if (uid.isEmpty) return;
    await _db.collection('users').doc(uid).collection('notifications').add({
      'type':      type,
      'title':     title,
      'body':      body,
      'isRead':    false,
      'data':      data ?? {},
      'imageUrl':  imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Broadcast to all users (fetches all user UIDs)
  static Future<void> broadcast({
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    final users = await _db.collection('users').get();
    if (users.docs.isEmpty) return;

    final notif = {
      'type':      type,
      'title':     title,
      'body':      body,
      'isRead':    false,
      'data':      data ?? {},
      'imageUrl':  imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Batch write (max 500 per batch)
    var batch = _db.batch();
    int count = 0;
    for (final user in users.docs) {
      final ref = _db
          .collection('users')
          .doc(user.id)
          .collection('notifications')
          .doc();
      batch.set(ref, notif);
      count++;
      if (count == 499) {
        await batch.commit();
        batch = _db.batch();
        count = 0;
      }
    }
    if (count > 0) await batch.commit();
  }

  // Mark one as read
  static Future<void> markRead(String uid, String notifId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notifId)
        .update({'isRead': true});
  }

  // Mark all as read
  static Future<void> markAllRead(String uid) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.update(d.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
