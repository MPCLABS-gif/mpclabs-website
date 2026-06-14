import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class FitnessTestsRecord extends FirestoreRecord {
  FitnessTestsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  String? _ownerUid;
  String get ownerUid => _ownerUid ?? '';
  bool hasOwnerUid() => _ownerUid != null;

  DateTime? _testDate;
  DateTime? get testDate => _testDate;
  bool hasTestDate() => _testDate != null;

  double? _bleepTest;
  double get bleepTest => _bleepTest ?? 0.0;
  bool hasBleepTest() => _bleepTest != null;

  double? _sprintTime;
  double get sprintTime => _sprintTime ?? 0.0;
  bool hasSprintTime() => _sprintTime != null;

  double? _broadJump;
  double get broadJump => _broadJump ?? 0.0;
  bool hasBroadJump() => _broadJump != null;

  int? _doubleSkips;
  int get doubleSkips => _doubleSkips ?? 0;
  bool hasDoubleSkips() => _doubleSkips != null;

  int? _pressUps;
  int get pressUps => _pressUps ?? 0;
  bool hasPressUps() => _pressUps != null;

  int? _sitUps;
  int get sitUps => _sitUps ?? 0;
  bool hasSitUps() => _sitUps != null;

  String? _notes;
  String get notes => _notes ?? '';
  bool hasNotes() => _notes != null;

  void _initializeFields() {
    _ownerUid = snapshotData['ownerUid'] as String?;
    _testDate = snapshotData['testDate'] as DateTime?;
    _bleepTest = castToType<double>(snapshotData['bleepTest']);
    _sprintTime = castToType<double>(snapshotData['sprintTime']);
    _broadJump = castToType<double>(snapshotData['broadJump']);
    _doubleSkips = castToType<int>(snapshotData['doubleSkips']);
    _pressUps = castToType<int>(snapshotData['pressUps']);
    _sitUps = castToType<int>(snapshotData['sitUps']);
    _notes = snapshotData['notes'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('fitness_tests');

  static Stream<FitnessTestsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => FitnessTestsRecord.fromSnapshot(s));

  static Future<FitnessTestsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => FitnessTestsRecord.fromSnapshot(s));

  static FitnessTestsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      FitnessTestsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static FitnessTestsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      FitnessTestsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'FitnessTestsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is FitnessTestsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createFitnessTestsRecordData({
  String? ownerUid,
  DateTime? testDate,
  double? bleepTest,
  double? sprintTime,
  double? broadJump,
  int? doubleSkips,
  int? pressUps,
  int? sitUps,
  String? notes,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'ownerUid': ownerUid,
      'testDate': testDate,
      'bleepTest': bleepTest,
      'sprintTime': sprintTime,
      'broadJump': broadJump,
      'doubleSkips': doubleSkips,
      'pressUps': pressUps,
      'sitUps': sitUps,
      'notes': notes,
    }.withoutNulls,
  );

  return firestoreData;
}

class FitnessTestsRecordDocumentEquality
    implements Equality<FitnessTestsRecord> {
  const FitnessTestsRecordDocumentEquality();

  @override
  bool equals(FitnessTestsRecord? e1, FitnessTestsRecord? e2) {
    return e1?.ownerUid == e2?.ownerUid &&
        e1?.testDate == e2?.testDate;
  }

  @override
  int hash(FitnessTestsRecord? e) => const ListEquality().hash([
        e?.ownerUid,
        e?.testDate,
      ]);

  @override
  bool isValidKey(Object? o) => o is FitnessTestsRecord;
}
