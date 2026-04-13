import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'tournament_calendar_model.dart';
export 'tournament_calendar_model.dart';

class TournamentCalendarWidget extends StatefulWidget {
  const TournamentCalendarWidget({super.key});
  static String routeName = 'TournamentCalendar';
  static String routePath = '/tournamentCalendar';

  @override
  State<TournamentCalendarWidget> createState() => _TournamentCalendarWidgetState();
}

class _TournamentCalendarWidgetState extends State<TournamentCalendarWidget> {
  late TournamentCalendarModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TournamentCalendarModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _showAddTournamentSheet(BuildContext context) {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final levelController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              Text("Add Tournament", style: GoogleFonts.interTight(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 4),
              Text("Add your upcoming tournament to stay prepared",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Tournament Name",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (picked != null) setModalState(() => selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blueGrey.shade300, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat("dd MMM yyyy").format(selectedDate),
                          style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500)),
                      Icon(Icons.calendar_today, size: 20, color: Colors.blueGrey.shade600),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: "Location",
                  hintText: "City or venue",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: levelController.text.isEmpty ? null : levelController.text,
                decoration: InputDecoration(
                  labelText: "Level",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
                items: ["Local", "County", "Regional", "National", "International"]
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (val) => levelController.text = val ?? "",
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Notes",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty) return;
                  try {
                    await TournamentsRecord.collection.doc().set(
                      createTournamentsRecordData(
                        ownerUid: currentUserUid,
                        name: nameController.text,
                        date: selectedDate,
                        location: locationController.text,
                        level: levelController.text,
                        notes: notesController.text,
                      ),
                    );
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error saving tournament: $e')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: FlutterFlowTheme.of(context).primary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  shadowColor: FlutterFlowTheme.of(context).primary.withOpacity(0.4),
                ),
                child: Text("Save Tournament", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, TournamentsRecord t) {
    final nameController = TextEditingController(text: t.name);
    final locationController = TextEditingController(text: t.location);
    final levelController = TextEditingController(text: t.level);
    final notesController = TextEditingController(text: t.notes);
    DateTime selectedDate = t.date ?? DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              Text("Edit Tournament", style: GoogleFonts.interTight(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              TextField(controller: nameController, decoration: InputDecoration(labelText: "Tournament Name", filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 365 * 2)));
                  if (picked != null) setModalState(() => selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat("dd MMM yyyy").format(selectedDate), style: const TextStyle(fontSize: 15)),
                      const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(controller: locationController, decoration: InputDecoration(labelText: "Location", filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
              const SizedBox(height: 12),
              TextField(controller: levelController, decoration: InputDecoration(labelText: "Level", filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
              const SizedBox(height: 12),
              TextField(controller: notesController, maxLines: 2, decoration: InputDecoration(labelText: "Notes", filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await t.reference.update({
                      "name": nameController.text,
                      "date": selectedDate,
                      "location": locationController.text,
                      "level": levelController.text,
                      "notes": notesController.text,
                    });
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating tournament: $e')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: FlutterFlowTheme.of(context).primary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: Text("Save Changes", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, TournamentsRecord tournament) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(tournament.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Delete Tournament", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await tournament.reference.delete();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tournament deleted")));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined),
              title: const Text("Cancel"),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Color _getUrgencyColor(DateTime date) {
    final daysUntil = date.difference(DateTime.now()).inDays;
    if (daysUntil < 0) return Colors.grey;
    if (daysUntil <= 7) return Colors.red;
    if (daysUntil <= 30) return Colors.orange;
    return Colors.green;
  }

  String _getUrgencyText(DateTime date) {
    final daysUntil = date.difference(DateTime.now()).inDays;
    if (daysUntil < 0) return "Passed";
    if (daysUntil == 0) return "Today!";
    if (daysUntil == 1) return "Tomorrow!";
    if (daysUntil <= 7) return "Starts in $daysUntil days";
    if (daysUntil <= 30) return "Starts in $daysUntil days";
    return "Starts in $daysUntil days";
  }

  @override
  Widget build(BuildContext context) {
    final primary = FlutterFlowTheme.of(context).primary;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: primary,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.white),
          onPressed: () => context.goNamed(HomePageWidget.routeName),
        ),
        title: Text("Tournament Calendar", style: GoogleFonts.interTight(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showAddTournamentSheet(context),
          ),
        ],
        elevation: 2.0,
      ),
      body: SafeArea(
        top: true,
        child: StreamBuilder<List<TournamentsRecord>>(
          stream: queryTournamentsRecord(
            queryBuilder: (q) => q
                .where("ownerUid", isEqualTo: currentUserUid)
                .orderBy("date", descending: false),
          ),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text("Could not load tournaments",
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() {}),
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primary)));
            }

            final tournaments = snapshot.data!;
            final upcoming = tournaments.where((t) => t.date != null && t.date!.isAfter(DateTime.now())).toList();
            final past = tournaments.where((t) => t.date != null && !t.date!.isAfter(DateTime.now())).toList();

            if (tournaments.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primary.withOpacity(0.06),
                      ),
                      child: Icon(Icons.emoji_events, size: 70, color: primary.withOpacity(0.35)),
                    ),
                    const SizedBox(height: 20),
                    Text("No tournaments added yet",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                    const SizedBox(height: 8),
                    Text("Track your upcoming competitions and stay prepared",
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade400), textAlign: TextAlign.center),
                    const SizedBox(height: 6),
                    Text("Plan ahead. Stay ready. Perform better.",
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade300, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      onPressed: () => _showAddTournamentSheet(context),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text("Add Your First Tournament", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (upcoming.isNotEmpty) ...[
                  Text("Upcoming", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  ...upcoming.map((t) => _buildTournamentCard(context, t)),
                  const SizedBox(height: 20),
                ],
                if (past.isNotEmpty) ...[
                  Text("Past", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 10),
                  ...past.map((t) => _buildTournamentCard(context, t, isPast: true)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTournamentCard(BuildContext context, TournamentsRecord t, {bool isPast = false}) {
    final urgencyColor = t.date != null ? _getUrgencyColor(t.date!) : Colors.grey;
    final urgencyText = t.date != null ? _getUrgencyText(t.date!) : "";

    return GestureDetector(
      onTap: () => _showEditSheet(context, t),
      onLongPress: () => _showDeleteDialog(context, t),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPast ? Colors.grey.shade50 : FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: isPast ? Border.all(color: Colors.grey.shade200) : Border.all(color: urgencyColor.withOpacity(0.3)),
          boxShadow: isPast ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: urgencyColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    t.date != null ? DateFormat("dd").format(t.date!) : "",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: urgencyColor),
                  ),
                  Text(
                    t.date != null ? DateFormat("MMM").format(t.date!).toUpperCase() : "",
                    style: TextStyle(fontSize: 10, color: urgencyColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.name, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16)),
                  if (t.location.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 2),
                        Text(t.location, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  ],
                  if (t.level.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(t.level, style: TextStyle(fontSize: 11, color: Colors.purple.shade700, fontWeight: FontWeight.w700)),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 12, color: Colors.orange.shade400),
                      const SizedBox(width: 4),
                      Text("Prepare your strategy",
                          style: TextStyle(fontSize: 11, color: Colors.orange.shade600, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            if (!isPast)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: urgencyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(urgencyText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: urgencyColor)),
              ),
          ],
        ),
      ),
    );
  }
}
