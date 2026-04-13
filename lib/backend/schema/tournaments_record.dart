import 'dart:async';
import '/backend/schema/util/firestore_util.dart';
import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class TournamentsRecord extends FirestoreRecord {
  TournamentsRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  String? _ownerUid;
  String get ownerUid => _ownerUid ?? "";
  bool hasOwnerUid() => _ownerUid != null;

  String? _name;
  String get name => _name ?? "";
  bool hasName() => _name != null;

  DateTime? _date;
  DateTime? get date => _date;
  bool hasDate() => _date != null;

  String? _location;
  String get location => _location ?? "";
  bool hasLocation() => _location != null;

  String? _notes;
  String get notes => _notes ?? "";
  bool hasNotes() => _notes != null;

  String? _level;
  String get level => _level ?? "";
  bool hasLevel() => _level != null;

  void _initializeFields() {
    _ownerUid = snapshotData["ownerUid"] as String?;
    _name = snapshotData["name"] as String?;
    _date = snapshotData["date"] as DateTime?;
    _location = snapshotData["location"] as String?;
    _notes = snapshotData["notes"] as String?;
    _level = snapshotData["level"] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection("tournaments");

  static Stream<TournamentsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => TournamentsRecord.fromSnapshot(s));

  static Future<TournamentsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => TournamentsRecord.fromSnapshot(s));

  static TournamentsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      TournamentsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static TournamentsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      TournamentsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      "TournamentsRecord(reference: \${reference.path}, data: \$snapshotData)";

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is TournamentsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createTournamentsRecordData({
  String? ownerUid,
  String? name,
  DateTime? date,
  String? location,
  String? notes,
  String? level,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      "ownerUid": ownerUid,
      "name": name,
      "date": date,
      "location": location,
      "notes": notes,
      "level": level,
    }.withoutNulls,
  );
  return firestoreData;
}
