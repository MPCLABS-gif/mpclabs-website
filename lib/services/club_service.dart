import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/auth/firebase_auth/auth_util.dart';

class ClubService {
  final _db = FirebaseFirestore.instance;

  String _generateCode(String prefix) {
    final rand = Random();
    final number = 1000 + rand.nextInt(8999);
    return '$prefix$number';
  }

  Future<Map<String, dynamic>> createClub({
    required String clubName,
    String? location,
  }) async {
    final playerCode = _generateCode('MPC-');
    final coachCode = _generateCode('MPC-C-');

    final docRef = await _db.collection('clubs').add({
      'clubName': clubName,
      'location': location ?? '',
      'playerCode': playerCode,
      'coachCode': coachCode,
      'createdBy': currentUserUid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('users').doc(currentUserUid).update({
      'clubId': docRef.id,
      'clubRole': 'headCoach',
      'clubLinkedAt': FieldValue.serverTimestamp(),
    });

    return {
      'clubId': docRef.id,
      'clubName': clubName,
      'playerCode': playerCode,
      'coachCode': coachCode,
    };
  }

  String _normalizeClubCode(String raw) {
    final cleaned = raw.toUpperCase().replaceAll('-', '').replaceAll(' ', '').trim();
    if (cleaned.startsWith('MPCC')) {
      return 'MPC-C-${cleaned.substring(4)}';
    } else if (cleaned.startsWith('MPC')) {
      return 'MPC-${cleaned.substring(3)}';
    }
    return cleaned;
  }
  Future<Map<String, dynamic>?> findClubByPlayerCode(String code) async {
    final query = await _db
        .collection('clubs')
        .where('playerCode', isEqualTo: _normalizeClubCode(code))
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return {'clubId': doc.id, ...doc.data()};
  }

  Future<Map<String, dynamic>?> findClubByCoachCode(String code) async {
    final query = await _db
        .collection('clubs')
        .where('coachCode', isEqualTo: _normalizeClubCode(code))
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return {'clubId': doc.id, ...doc.data()};
  }

  Future<void> joinClubAsPlayer({
    required String clubId,
  }) async {
    await _db.collection('users').doc(currentUserUid).update({
      'clubId': clubId,
      'clubRole': 'player',
      'clubLinkedAt': FieldValue.serverTimestamp(),
      'clubConsentAccepted': true,
    });
  }

  Future<void> joinClubAsCoach({
    required String clubId,
  }) async {
    await _db.collection('users').doc(currentUserUid).update({
      'clubId': clubId,
      'clubRole': 'coach',
      'clubLinkedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> leaveClub() async {
    await _db.collection('users').doc(currentUserUid).update({
      'clubId': FieldValue.delete(),
      'clubRole': FieldValue.delete(),
      'clubLinkedAt': FieldValue.delete(),
      'clubConsentAccepted': FieldValue.delete(),
    });
  }

  Future<Map<String, dynamic>?> getMyClub() async {
    final userDoc = await _db.collection('users').doc(currentUserUid).get();
    final clubId = userDoc.data()?['clubId'] as String?;
    if (clubId == null || clubId.isEmpty) return null;
    final clubDoc = await _db.collection('clubs').doc(clubId).get();
    if (!clubDoc.exists) return null;
    return {'clubId': clubDoc.id, ...clubDoc.data()!};
  }

  Future<List<Map<String, dynamic>>> getClubPlayers(String clubId) async {
    final query = await _db
        .collection('users')
        .where('clubId', isEqualTo: clubId)
        .where('clubRole', isEqualTo: 'player')
        .get(const GetOptions(source: Source.server));
    return query.docs.map((d) => {'uid': d.id, ...d.data()}).toList();
  }

  Future<List<Map<String, dynamic>>> getClubCoaches(String clubId) async {
    final query = await _db
        .collection('users')
        .where('clubId', isEqualTo: clubId)
        .where('clubRole', whereIn: ['headCoach', 'coach'])
        .get();
    return query.docs.map((d) => {'uid': d.id, ...d.data()}).toList();
  }
}
