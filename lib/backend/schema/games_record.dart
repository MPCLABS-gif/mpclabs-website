import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class GamesRecord extends FirestoreRecord {
  GamesRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "matchRef" field.
  DocumentReference? _matchRef;
  DocumentReference? get matchRef => _matchRef;
  bool hasMatchRef() => _matchRef != null;

  // "gameNumber" field.
  int? _gameNumber;
  int get gameNumber => _gameNumber ?? 0;
  bool hasGameNumber() => _gameNumber != null;

  // "playerScore" field.
  int? _playerScore;
  int get playerScore => _playerScore ?? 0;
  bool hasPlayerScore() => _playerScore != null;

  // "opponentScore" field.
  int? _opponentScore;
  int get opponentScore => _opponentScore ?? 0;
  bool hasOpponentScore() => _opponentScore != null;

  // "notes" field.
  String? _notes;
  String get notes => _notes ?? '';
  bool hasNotes() => _notes != null;

  void _initializeFields() {
    _matchRef = snapshotData['matchRef'] as DocumentReference?;
    _gameNumber = castToType<int>(snapshotData['gameNumber']);
    _playerScore = castToType<int>(snapshotData['playerScore']);
    _opponentScore = castToType<int>(snapshotData['opponentScore']);
    _notes = snapshotData['notes'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('games');

  static Stream<GamesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => GamesRecord.fromSnapshot(s));

  static Future<GamesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => GamesRecord.fromSnapshot(s));

  static GamesRecord fromSnapshot(DocumentSnapshot snapshot) => GamesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static GamesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      GamesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'GamesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is GamesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createGamesRecordData({
  DocumentReference? matchRef,
  int? gameNumber,
  int? playerScore,
  int? opponentScore,
  String? notes,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'matchRef': matchRef,
      'gameNumber': gameNumber,
      'playerScore': playerScore,
      'opponentScore': opponentScore,
      'notes': notes,
    }.withoutNulls,
  );

  return firestoreData;
}

class GamesRecordDocumentEquality implements Equality<GamesRecord> {
  const GamesRecordDocumentEquality();

  @override
  bool equals(GamesRecord? e1, GamesRecord? e2) {
    return e1?.matchRef == e2?.matchRef &&
        e1?.gameNumber == e2?.gameNumber &&
        e1?.playerScore == e2?.playerScore &&
        e1?.opponentScore == e2?.opponentScore &&
        e1?.notes == e2?.notes;
  }

  @override
  int hash(GamesRecord? e) => const ListEquality().hash(
      [e?.matchRef, e?.gameNumber, e?.playerScore, e?.opponentScore, e?.notes]);

  @override
  bool isValidKey(Object? o) => o is GamesRecord;
}
