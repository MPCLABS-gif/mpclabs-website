// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class MatchesStruct extends FFFirebaseStruct {
  MatchesStruct({
    String? ownerUid,
    String? playerName,
    String? opponentName,
    DateTime? matchDate,
    String? matchType,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _ownerUid = ownerUid,
        _playerName = playerName,
        _opponentName = opponentName,
        _matchDate = matchDate,
        _matchType = matchType,
        super(firestoreUtilData);

  // "ownerUid" field.
  String? _ownerUid;
  String get ownerUid => _ownerUid ?? '';
  set ownerUid(String? val) => _ownerUid = val;

  bool hasOwnerUid() => _ownerUid != null;

  // "playerName" field.
  String? _playerName;
  String get playerName => _playerName ?? '';
  set playerName(String? val) => _playerName = val;

  bool hasPlayerName() => _playerName != null;

  // "opponentName" field.
  String? _opponentName;
  String get opponentName => _opponentName ?? '';
  set opponentName(String? val) => _opponentName = val;

  bool hasOpponentName() => _opponentName != null;

  // "matchDate" field.
  DateTime? _matchDate;
  DateTime? get matchDate => _matchDate;
  set matchDate(DateTime? val) => _matchDate = val;

  bool hasMatchDate() => _matchDate != null;

  // "matchType" field.
  String? _matchType;
  String get matchType => _matchType ?? '';
  set matchType(String? val) => _matchType = val;

  bool hasMatchType() => _matchType != null;

  static MatchesStruct fromMap(Map<String, dynamic> data) => MatchesStruct(
        ownerUid: data['ownerUid'] as String?,
        playerName: data['playerName'] as String?,
        opponentName: data['opponentName'] as String?,
        matchDate: data['matchDate'] as DateTime?,
        matchType: data['matchType'] as String?,
      );

  static MatchesStruct? maybeFromMap(dynamic data) =>
      data is Map ? MatchesStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'ownerUid': _ownerUid,
        'playerName': _playerName,
        'opponentName': _opponentName,
        'matchDate': _matchDate,
        'matchType': _matchType,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'ownerUid': serializeParam(
          _ownerUid,
          ParamType.String,
        ),
        'playerName': serializeParam(
          _playerName,
          ParamType.String,
        ),
        'opponentName': serializeParam(
          _opponentName,
          ParamType.String,
        ),
        'matchDate': serializeParam(
          _matchDate,
          ParamType.DateTime,
        ),
        'matchType': serializeParam(
          _matchType,
          ParamType.String,
        ),
      }.withoutNulls;

  static MatchesStruct fromSerializableMap(Map<String, dynamic> data) =>
      MatchesStruct(
        ownerUid: deserializeParam(
          data['ownerUid'],
          ParamType.String,
          false,
        ),
        playerName: deserializeParam(
          data['playerName'],
          ParamType.String,
          false,
        ),
        opponentName: deserializeParam(
          data['opponentName'],
          ParamType.String,
          false,
        ),
        matchDate: deserializeParam(
          data['matchDate'],
          ParamType.DateTime,
          false,
        ),
        matchType: deserializeParam(
          data['matchType'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'MatchesStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is MatchesStruct &&
        ownerUid == other.ownerUid &&
        playerName == other.playerName &&
        opponentName == other.opponentName &&
        matchDate == other.matchDate &&
        matchType == other.matchType;
  }

  @override
  int get hashCode => const ListEquality()
      .hash([ownerUid, playerName, opponentName, matchDate, matchType]);
}

MatchesStruct createMatchesStruct({
  String? ownerUid,
  String? playerName,
  String? opponentName,
  DateTime? matchDate,
  String? matchType,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    MatchesStruct(
      ownerUid: ownerUid,
      playerName: playerName,
      opponentName: opponentName,
      matchDate: matchDate,
      matchType: matchType,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

MatchesStruct? updateMatchesStruct(
  MatchesStruct? matches, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    matches
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addMatchesStructData(
  Map<String, dynamic> firestoreData,
  MatchesStruct? matches,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (matches == null) {
    return;
  }
  if (matches.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && matches.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final matchesData = getMatchesFirestoreData(matches, forFieldValue);
  final nestedData = matchesData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = matches.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getMatchesFirestoreData(
  MatchesStruct? matches, [
  bool forFieldValue = false,
]) {
  if (matches == null) {
    return {};
  }
  final firestoreData = mapToFirestore(matches.toMap());

  // Add any Firestore field values
  matches.firestoreUtilData.fieldValues.forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getMatchesListFirestoreData(
  List<MatchesStruct>? matchess,
) =>
    matchess?.map((e) => getMatchesFirestoreData(e, true)).toList() ?? [];
