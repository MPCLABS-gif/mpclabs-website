import 'package:cloud_firestore/cloud_firestore.dart';
import '/auth/firebase_auth/auth_util.dart';

class MessageService {
  static final MessageService _instance = MessageService._internal();
  factory MessageService() => _instance;
  MessageService._internal();

  final _db = FirebaseFirestore.instance;

  // Send a broadcast message to the club (coach only)
  Future<void> sendMessage({
    required String clubId,
    required String text,
    required String coachName,
    bool pinned = false,
  }) async {
    await _db
        .collection('clubs')
        .doc(clubId)
        .collection('messages')
        .add({
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': currentUserUid,
      'createdByName': coachName,
      'pinned': pinned,
      'readBy': <String>[],
    });
  }

  // Stream all messages for a club, pinned first then newest first
  Stream<List<Map<String, dynamic>>> streamMessages(String clubId) {
    return _db
        .collection('clubs')
        .doc(clubId)
        .collection('messages')
        .orderBy('pinned', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  // Get the single latest message (for My Club subtitle)
  Future<Map<String, dynamic>?> getLatestMessage(String clubId) async {
    final query = await _db
        .collection('clubs')
        .doc(clubId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return {'id': doc.id, ...doc.data()};
  }

  // Count unread messages for the current user in this club
  Future<int> getUnreadCount(String clubId) async {
    if (currentUserUid.isEmpty) return 0;
    final query = await _db
        .collection('clubs')
        .doc(clubId)
        .collection('messages')
        .get();
    return query.docs.where((d) {
      final readBy = List<String>.from(d.data()['readBy'] ?? []);
      return !readBy.contains(currentUserUid);
    }).length;
  }

  // Mark a single message as read by the current user
  Future<void> markAsRead({
    required String clubId,
    required String messageId,
  }) async {
    if (currentUserUid.isEmpty) return;
    await _db
        .collection('clubs')
        .doc(clubId)
        .collection('messages')
        .doc(messageId)
        .update({
      'readBy': FieldValue.arrayUnion([currentUserUid]),
    });
  }

  // Mark all messages in a club as read by the current user
  Future<void> markAllAsRead(String clubId) async {
    if (currentUserUid.isEmpty) return;
    final query = await _db
        .collection('clubs')
        .doc(clubId)
        .collection('messages')
        .get();
    final batch = _db.batch();
    for (final doc in query.docs) {
      final readBy = List<String>.from(doc.data()['readBy'] ?? []);
      if (!readBy.contains(currentUserUid)) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([currentUserUid]),
        });
      }
    }
    await batch.commit();
  }
}
