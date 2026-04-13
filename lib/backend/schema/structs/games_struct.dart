// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class GamesStruct extends FFFirebaseStruct {
  GamesStruct({
    String? ownerUid,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _ownerUid = ownerUid,
        super(firestoreUtilData);

  // "ownerUid" field.
  String? _ownerUid;
  String get ownerUid => _ownerUid ?? '';
  set ownerUid(String? val) => _ownerUid = val;

  bool hasOwnerUid() => _ownerUid != null;

  static GamesStruct fromMap(Map<String, dynamic> data) => GamesStruct(
        ownerUid: data['ownerUid'] as String?,
      );

  static GamesStruct? maybeFromMap(dynamic data) =>
      data is Map ? GamesStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'ownerUid': _ownerUid,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'ownerUid': serializeParam(
          _ownerUid,
          ParamType.String,
        ),
      }.withoutNulls;

  static GamesStruct fromSerializableMap(Map<String, dynamic> data) =>
      GamesStruct(
        ownerUid: deserializeParam(
          data['ownerUid'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'GamesStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is GamesStruct && ownerUid == other.ownerUid;
  }

  @override
  int get hashCode => const ListEquality().hash([ownerUid]);
}

GamesStruct createGamesStruct({
  String? ownerUid,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    GamesStruct(
      ownerUid: ownerUid,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

GamesStruct? updateGamesStruct(
  GamesStruct? games, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    games
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addGamesStructData(
  Map<String, dynamic> firestoreData,
  GamesStruct? games,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (games == null) {
    return;
  }
  if (games.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && games.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final gamesData = getGamesFirestoreData(games, forFieldValue);
  final nestedData = gamesData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = games.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getGamesFirestoreData(
  GamesStruct? games, [
  bool forFieldValue = false,
]) {
  if (games == null) {
    return {};
  }
  final firestoreData = mapToFirestore(games.toMap());

  // Add any Firestore field values
  games.firestoreUtilData.fieldValues.forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getGamesListFirestoreData(
  List<GamesStruct>? gamess,
) =>
    gamess?.map((e) => getGamesFirestoreData(e, true)).toList() ?? [];
