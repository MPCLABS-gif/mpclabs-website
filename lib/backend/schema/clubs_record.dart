import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ClubsRecord extends FirestoreRecord {
  ClubsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  String? _clubName;
  String get clubName => _clubName ?? '';
  bool hasClubName() => _clubName != null;

  String? _location;
  String get location => _location ?? '';
  bool hasLocation() => _location != null;

  String? _playerCode;
  String get playerCode => _playerCode ?? '';
  bool hasPlayerCode() => _playerCode != null;

  String? _coachCode;
  String get coachCode => _coachCode ?? '';
  bool hasCoachCode() => _coachCode != null;

  String? _createdBy;
  String get createdBy => _createdBy ?? '';
  bool hasCreatedBy() => _createdBy != null;

  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  void _initializeFields() {
    _clubName = snapshotData['clubName'] as String?;
    _location = snapshotData['location'] as String?;
    _playerCode = snapshotData['playerCode'] as String?;
    _coachCode = snapshotData['coachCode'] as String?;
    _createdBy = snapshotData['createdBy'] as String?;
    _createdAt = snapshotData['createdAt'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('clubs');

  static Stream<ClubsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ClubsRecord.fromSnapshot(s));

  static Future<ClubsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ClubsRecord.fromSnapshot(s));

  static ClubsRecord fromSnapshot(DocumentSnapshot snapshot) => ClubsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ClubsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ClubsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ClubsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ClubsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createClubsRecordData({
  String? clubName,
  String? location,
  String? playerCode,
  String? coachCode,
  String? createdBy,
  DateTime? createdAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'clubName': clubName,
      'location': location,
      'playerCode': playerCode,
      'coachCode': coachCode,
      'createdBy': createdBy,
      'createdAt': createdAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class ClubsRecordDocumentEquality implements Equality<ClubsRecord> {
  const ClubsRecordDocumentEquality();

  @override
  bool equals(ClubsRecord? e1, ClubsRecord? e2) {
    return e1?.clubName == e2?.clubName &&
        e1?.playerCode == e2?.playerCode &&
        e1?.coachCode == e2?.coachCode &&
        e1?.createdBy == e2?.createdBy;
  }

  @override
  int hash(ClubsRecord? e) => const ListEquality().hash([
        e?.clubName,
        e?.playerCode,
        e?.coachCode,
        e?.createdBy,
      ]);

  @override
  bool isValidKey(Object? o) => o is ClubsRecord;
}
