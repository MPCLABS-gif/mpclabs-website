import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class MatchesRecord extends FirestoreRecord {
  MatchesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "ownerUid" field.
  String? _ownerUid;
  String get ownerUid => _ownerUid ?? '';
  bool hasOwnerUid() => _ownerUid != null;

  // "PlayerName" field.
  String? _playerName;
  String get playerName => _playerName ?? '';
  bool hasPlayerName() => _playerName != null;

  // "OpponentName" field.
  String? _opponentName;
  String get opponentName => _opponentName ?? '';
  bool hasOpponentName() => _opponentName != null;

  // "matchDate" field.
  DateTime? _matchDate;
  DateTime? get matchDate => _matchDate;
  bool hasMatchDate() => _matchDate != null;

  // "notes" field.
  String? _notes;
  String get notes => _notes ?? '';
  bool hasNotes() => _notes != null;

  // "matchType" field.
  String? _matchType;
  String get matchType => _matchType ?? '';
  bool hasMatchType() => _matchType != null;

  // "g1Player" field.
  int? _g1Player;
  int get g1Player => _g1Player ?? 0;
  bool hasG1Player() => _g1Player != null;

  // "g1Opponent" field.
  int? _g1Opponent;
  int get g1Opponent => _g1Opponent ?? 0;
  bool hasG1Opponent() => _g1Opponent != null;

  // "g2Player" field.
  int? _g2Player;
  int get g2Player => _g2Player ?? 0;
  bool hasG2Player() => _g2Player != null;

  // "g2Opponent" field.
  int? _g2Opponent;
  int get g2Opponent => _g2Opponent ?? 0;
  bool hasG2Opponent() => _g2Opponent != null;

  // "g3Player" field.
  int? _g3Player;
  int get g3Player => _g3Player ?? 0;
  bool hasG3Player() => _g3Player != null;

  // "g3Opponent" field.
  int? _g3Opponent;
  int get g3Opponent => _g3Opponent ?? 0;
  bool hasG3Opponent() => _g3Opponent != null;

  // "partnerName" field.
  String? _partnerName;
  String get partnerName => _partnerName ?? '';
  bool hasPartnerName() => _partnerName != null;

  // "opponentPartnerName" field.
  String? _opponentPartnerName;
  String get opponentPartnerName => _opponentPartnerName ?? '';
  bool hasOpponentPartnerName() => _opponentPartnerName != null;

  // "currentGame" field.
  int? _currentGame;
  int get currentGame => _currentGame ?? 0;
  bool hasCurrentGame() => _currentGame != null;

  String? _mood;
  String get mood => _mood ?? "";
  bool hasMood() => _mood != null;

  String? _scoringFormat;
  String get scoringFormat => _scoringFormat ?? '21';
  bool hasScoringFormat() => _scoringFormat != null;

  void _initializeFields() {
    _ownerUid = snapshotData['ownerUid'] as String?;
    _playerName = snapshotData['PlayerName'] as String?;
    _opponentName = snapshotData['OpponentName'] as String?;
    _matchDate = snapshotData['matchDate'] as DateTime?;
    _notes = snapshotData['notes'] as String?;
    _matchType = snapshotData['matchType'] as String?;
    _g1Player = castToType<int>(snapshotData['g1Player']);
    _g1Opponent = castToType<int>(snapshotData['g1Opponent']);
    _g2Player = castToType<int>(snapshotData['g2Player']);
    _g2Opponent = castToType<int>(snapshotData['g2Opponent']);
    _g3Player = castToType<int>(snapshotData['g3Player']);
    _g3Opponent = castToType<int>(snapshotData['g3Opponent']);
    _partnerName = snapshotData['partnerName'] as String?;
    _opponentPartnerName = snapshotData['opponentPartnerName'] as String?;
    _currentGame = castToType<int>(snapshotData['currentGame']);
    _mood = snapshotData['mood'] as String?;
    _scoringFormat = snapshotData['scoringFormat'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('matches');

  static Stream<MatchesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => MatchesRecord.fromSnapshot(s));

  static Future<MatchesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => MatchesRecord.fromSnapshot(s));

  static MatchesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      MatchesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static MatchesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      MatchesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'MatchesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is MatchesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createMatchesRecordData({
  String? ownerUid,
  String? playerName,
  String? opponentName,
  DateTime? matchDate,
  String? notes,
  String? matchType,
  int? g1Player,
  int? g1Opponent,
  int? g2Player,
  int? g2Opponent,
  int? g3Player,
  int? g3Opponent,
  String? partnerName,
  String? opponentPartnerName,
  int? currentGame,
  String? mood,
  String? scoringFormat,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'ownerUid': ownerUid,
      'PlayerName': playerName,
      'OpponentName': opponentName,
      'matchDate': matchDate,
      'notes': notes,
      'matchType': matchType,
      'g1Player': g1Player,
      'g1Opponent': g1Opponent,
      'g2Player': g2Player,
      'g2Opponent': g2Opponent,
      'g3Player': g3Player,
      'g3Opponent': g3Opponent,
      'partnerName': partnerName,
      'opponentPartnerName': opponentPartnerName,
      'currentGame': currentGame,
      'mood': mood,
      'scoringFormat': scoringFormat,
    }.withoutNulls,
  );

  return firestoreData;
}

class MatchesRecordDocumentEquality implements Equality<MatchesRecord> {
  const MatchesRecordDocumentEquality();

  @override
  bool equals(MatchesRecord? e1, MatchesRecord? e2) {
    return e1?.ownerUid == e2?.ownerUid &&
        e1?.playerName == e2?.playerName &&
        e1?.opponentName == e2?.opponentName &&
        e1?.matchDate == e2?.matchDate &&
        e1?.notes == e2?.notes &&
        e1?.matchType == e2?.matchType &&
        e1?.g1Player == e2?.g1Player &&
        e1?.g1Opponent == e2?.g1Opponent &&
        e1?.g2Player == e2?.g2Player &&
        e1?.g2Opponent == e2?.g2Opponent &&
        e1?.g3Player == e2?.g3Player &&
        e1?.g3Opponent == e2?.g3Opponent &&
        e1?.partnerName == e2?.partnerName &&
        e1?.currentGame == e2?.currentGame;
  }

  @override
  int hash(MatchesRecord? e) => const ListEquality().hash([
        e?.ownerUid,
        e?.playerName,
        e?.opponentName,
        e?.matchDate,
        e?.notes,
        e?.matchType,
        e?.g1Player,
        e?.g1Opponent,
        e?.g2Player,
        e?.g2Opponent,
        e?.g3Player,
        e?.g3Opponent,
        e?.partnerName,
        e?.currentGame
      ]);

  @override
  bool isValidKey(Object? o) => o is MatchesRecord;
}
