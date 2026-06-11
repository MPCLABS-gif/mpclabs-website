import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_match_model.dart';
export 'add_match_model.dart';

class AddMatchWidget extends StatefulWidget {
  const AddMatchWidget({super.key});
  static String routeName = 'AddMatch';
  static String routePath = '/addMatch';
  @override
  State<AddMatchWidget> createState() => _AddMatchWidgetState();
}

class _AddMatchWidgetState extends State<AddMatchWidget> {
  late AddMatchModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String _mode = 'result';
  String? _selectedMood;
  String? _opponentHandedness;
  String _scoringFormat = '21';
  final _g1pController = TextEditingController();
  final _g1oController = TextEditingController();
  final _g2pController = TextEditingController();
  final _g2oController = TextEditingController();
  final _g3pController = TextEditingController();
  final _g3oController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddMatchModel());
    _model.playerNameTextController ??= TextEditingController();
    // Auto-fill player name from profile
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (currentUserUid.isNotEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserUid)
            .get();
        final name = doc.data()?['playerName'] as String? ?? '';
        if (name.isNotEmpty && (_model.playerNameTextController?.text.isEmpty ?? true)) {
          _model.playerNameTextController?.text = name;
        }
      }
    });
    _model.playerNameFocusNode ??= FocusNode();
    _model.opponentNameTextController ??= TextEditingController();
    _model.opponentNameFocusNode ??= FocusNode();
    _model.partnerNameTextController ??= TextEditingController();
    _model.partnerNameFocusNode ??= FocusNode();
    _model.opponentPartnerNameTextController ??= TextEditingController();
    _model.opponentPartnerNameFocusNode ??= FocusNode();
    _model.notesTextFieldTextController ??= TextEditingController();
    _model.notesTextFieldFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();
    _g1pController.dispose();
    _g1oController.dispose();
    _g2pController.dispose();
    _g2oController.dispose();
    _g3pController.dispose();
    _g3oController.dispose();
    super.dispose();
  }

  Widget _scoreRow(String label, TextEditingController p, TextEditingController o) {
    final pVal = int.tryParse(p.text);
    final oVal = int.tryParse(o.text);
    final pWins = pVal != null && oVal != null && pVal > oVal;
    final oWins = pVal != null && oVal != null && oVal > pVal;
    final highlightColor = Colors.green.withOpacity(0.15);
    final defaultColor = FlutterFlowTheme.of(context).secondaryBackground;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13))),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: p,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'You',
                filled: true,
                fillColor: pWins ? highlightColor : defaultColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: pWins ? BorderSide(color: Colors.green.shade400, width: 1.5) : BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('–', style: TextStyle(fontSize: 18, color: Colors.grey.shade400))),
          Expanded(
            child: TextFormField(
              controller: o,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Opp',
                filled: true,
                fillColor: oWins ? highlightColor : defaultColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: oWins ? BorderSide(color: Colors.green.shade400, width: 1.5) : BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = FlutterFlowTheme.of(context).primary;
    return GestureDetector(
      onTap: () { FocusScope.of(context).unfocus(); FocusManager.instance.primaryFocus?.unfocus(); },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: primary,
          automaticallyImplyLeading: true,
          title: Text('Add Match', style: GoogleFonts.interTight(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          elevation: 2.0,
        ),
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(color: FlutterFlowTheme.of(context).secondaryBackground, borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _mode = 'live'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(color: _mode == 'live' ? primary : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.sports_tennis, size: 16, color: _mode == 'live' ? Colors.white : Colors.grey),
                                  const SizedBox(width: 6),
                                  Text('Live Scoring', style: TextStyle(color: _mode == 'live' ? Colors.white : Colors.grey, fontWeight: FontWeight.w600, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _mode = 'result'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(color: _mode == 'result' ? primary : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit_note, size: 16, color: _mode == 'result' ? Colors.white : Colors.grey),
                                  const SizedBox(width: 6),
                                  Text('Enter Result', style: TextStyle(color: _mode == 'result' ? Colors.white : Colors.grey, fontWeight: FontWeight.w600, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // subtitle
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      _mode == 'live' ? 'Score point by point during the match' : 'Enter the final result after your match',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Players Section ──
                  _sectionHeader(context, Icons.people_alt_rounded, 'Players', primary),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _model.playerNameTextController,
                    focusNode: _model.playerNameFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Your Name',
                      hintText: 'Enter your name',
                      prefixIcon: Icon(Icons.person_outline, color: Colors.grey.shade400),
                      filled: true,
                      fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide.none),
                    ),
                    style: FlutterFlowTheme.of(context).bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  _OpponentField(
                    controller: _model.opponentNameTextController!,
                    ownerUid: currentUserUid,
                    theme: FlutterFlowTheme.of(context),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Opponent Handedness', style: TextStyle(fontSize: 13, color: FlutterFlowTheme.of(context).secondaryText)),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => setState(() => _opponentHandedness = _opponentHandedness == 'Right' ? null : 'Right'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _opponentHandedness == 'Right' ? FlutterFlowTheme.of(context).primary : FlutterFlowTheme.of(context).secondaryBackground,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.3)),
                          ),
                          child: Text('Right', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _opponentHandedness == 'Right' ? Colors.white : FlutterFlowTheme.of(context).primaryText)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _opponentHandedness = _opponentHandedness == 'Left' ? null : 'Left'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _opponentHandedness == 'Left' ? FlutterFlowTheme.of(context).primary : FlutterFlowTheme.of(context).secondaryBackground,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.3)),
                          ),
                          child: Text('Left', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _opponentHandedness == 'Left' ? Colors.white : FlutterFlowTheme.of(context).primaryText)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Match Setup Section ──
                  _sectionHeader(context, Icons.tune_rounded, 'Match Setup', primary),
                  const SizedBox(height: 10),

                  // Match type + format side by side
                  Row(
                    children: [
                      Expanded(
                        child: FlutterFlowDropDown<String>(
                          controller: _model.matchTypeValueController ??= FormFieldController<String>(null),
                          options: const ['Tournament', 'Practice'],
                          onChanged: (val) => safeSetState(() => _model.matchTypeValue = val),
                          width: double.infinity, height: 50.0,
                          textStyle: FlutterFlowTheme.of(context).bodyMedium,
                          hintText: 'Match type',
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: FlutterFlowTheme.of(context).secondaryText, size: 24.0),
                          fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                          elevation: 2.0, borderColor: Colors.transparent, borderWidth: 0.0, borderRadius: 8.0,
                          margin: const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
                          hidesUnderline: true, isOverButton: false, isSearchable: false, isMultiSelect: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FlutterFlowDropDown<String>(
                          controller: _model.matchFormatValueController ??= FormFieldController<String>(_model.matchFormatValue ??= 'Singles'),
                          options: const ['Singles', 'Doubles'],
                          onChanged: (val) => safeSetState(() => _model.matchFormatValue = val),
                          width: double.infinity, height: 50.0,
                          textStyle: FlutterFlowTheme.of(context).bodyMedium,
                          hintText: 'Format',
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: FlutterFlowTheme.of(context).secondaryText, size: 24.0),
                          fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                          elevation: 2.0, borderColor: Colors.transparent, borderWidth: 0.0, borderRadius: 8.0,
                          margin: const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
                          hidesUnderline: true, isOverButton: false, isSearchable: false, isMultiSelect: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Scoring toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.scoreboard_outlined, size: 18, color: Colors.grey.shade500),
                        const SizedBox(width: 10),
                        Text('Scoring', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _scoringFormat = '21'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: _scoringFormat == '21' ? primary : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('21 pts', style: TextStyle(color: _scoringFormat == '21' ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _scoringFormat = '15'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: _scoringFormat == '15' ? primary : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('15 pts', style: TextStyle(color: _scoringFormat == '15' ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Partner names (only show when Doubles selected)
                  if (_model.matchFormatValue == 'Doubles') ...[
                    TextFormField(
                      controller: _model.partnerNameTextController,
                      focusNode: _model.partnerNameFocusNode,
                      decoration: InputDecoration(
                        labelText: 'Partner Name',
                        hintText: 'Enter your partners name',
                        prefixIcon: Icon(Icons.people_outline, color: Colors.grey.shade400),
                        filled: true,
                        fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide.none),
                      ),
                      style: FlutterFlowTheme.of(context).bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _model.opponentPartnerNameTextController,
                      focusNode: _model.opponentPartnerNameFocusNode,
                      decoration: InputDecoration(
                        labelText: 'Opponent Partner Name',
                        hintText: 'Enter opponents partner name',
                        prefixIcon: Icon(Icons.people_outline, color: Colors.grey.shade400),
                        filled: true,
                        fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide.none),
                      ),
                      style: FlutterFlowTheme.of(context).bodyMedium,
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 20),
                  if (_mode == 'result') ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: primary.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: primary.withOpacity(0.15))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Enter Final Scores', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: primary)),
                          const SizedBox(height: 4),
                          Text('Game 3 only needed if match went to 3 games', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          const SizedBox(height: 12),
                          _scoreRow('Game 1', _g1pController, _g1oController),
                          _scoreRow('Game 2', _g2pController, _g2oController),
                          _scoreRow('Game 3', _g3pController, _g3oController),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // ── Mood Picker ──
                  _sectionHeader(context, Icons.sentiment_satisfied_alt_rounded, 'Mood', primary),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('How do you feel before this match?', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ['Excited', 'Confident', 'Energised', 'Focused', 'Calm', 'Nervous', 'Anxious', 'Unsure', 'Tired', 'Frustrated', 'Unwell'].map((mood) {
                            final isSelected = _selectedMood == mood;
                            final colors = {
                              'Excited': Colors.orange,
                              'Confident': Colors.green,
                              'Energised': Colors.lightBlue,
                              'Focused': Colors.blue,
                              'Calm': Colors.teal,
                              'Nervous': Colors.yellow.shade700,
                              'Anxious': Colors.red.shade300,
                              'Unsure': Colors.blueGrey,
                              'Tired': Colors.grey,
                              'Frustrated': Colors.red,
                              'Unwell': Colors.purple,
                              'Sad': Colors.indigo,
                              'Upset': Colors.red,
                            };
                            final emojis = {
                              'Excited': '🔥',
                              'Confident': '💪',
                              'Energised': '⚡',
                              'Focused': '🎯',
                              'Calm': '😌',
                              'Nervous': '😬',
                              'Anxious': '😰',
                              'Unsure': '🤔',
                              'Tired': '😴',
                              'Frustrated': '😤',
                              'Unwell': '🤢',
                              'Sad': '😔',
                              'Upset': '😤',
                            };
                            final color = colors[mood] ?? Colors.grey;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedMood = isSelected ? null : mood),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? color.withOpacity(0.2) : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
                                ),
                                child: Text('${emojis[mood]} $mood', style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? color : Colors.grey.shade700)),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _model.notesTextFieldTextController,
                    focusNode: _model.notesTextFieldFocusNode,
                    maxLines: 3,
                    decoration: InputDecoration(labelText: 'Notes', hintText: 'Anything to remember about this match', filled: true, fillColor: FlutterFlowTheme.of(context).secondaryBackground, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide.none)),
                    style: FlutterFlowTheme.of(context).bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  FFButtonWidget(
                    onPressed: () async {
                      if (_model.matchTypeValue == null || _model.matchTypeValue!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Please select a match type (Tournament or Practice)', style: TextStyle(color: FlutterFlowTheme.of(context).primaryText)),
                          duration: const Duration(milliseconds: 2500),
                          backgroundColor: Colors.red.shade400,
                        ));
                        return;
                      }
                      final g1p = int.tryParse(_g1pController.text) ?? 0;
                      final g1o = int.tryParse(_g1oController.text) ?? 0;
                      final g2p = int.tryParse(_g2pController.text) ?? 0;
                      final g2o = int.tryParse(_g2oController.text) ?? 0;
                      final g3p = int.tryParse(_g3pController.text) ?? 0;
                      final g3o = int.tryParse(_g3oController.text) ?? 0;

                      // Validate at least Game 1 is entered
                      final g1Entered = _g1pController.text.isNotEmpty && _g1oController.text.isNotEmpty;
                      if (_mode == 'result' && !g1Entered) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Please enter at least Game 1 scores', style: TextStyle(color: FlutterFlowTheme.of(context).primaryText)),
                          duration: const Duration(milliseconds: 2500),
                          backgroundColor: Colors.red.shade400,
                        ));
                        return;
                      }

                      // Determine games played
                      final g2Entered = _g2pController.text.isNotEmpty && _g2oController.text.isNotEmpty;
                      final g3Entered = _g3pController.text.isNotEmpty && _g3oController.text.isNotEmpty;
                      // Validate no tied scores
                      if (_mode == 'result') {
                        if (g1Entered && g1p == g1o) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Game 1 cannot end in a tie. Please check the score.', style: TextStyle(color: FlutterFlowTheme.of(context).primaryText)),
                            duration: const Duration(milliseconds: 2500),
                            backgroundColor: Colors.red.shade400,
                          ));
                          return;
                        }
                        if (g2Entered && g2p == g2o) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Game 2 cannot end in a tie. Please check the score.', style: TextStyle(color: FlutterFlowTheme.of(context).primaryText)),
                            duration: const Duration(milliseconds: 2500),
                            backgroundColor: Colors.red.shade400,
                          ));
                          return;
                        }
                        if (g3Entered && g3p == g3o) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Game 3 cannot end in a tie. Please check the score.', style: TextStyle(color: FlutterFlowTheme.of(context).primaryText)),
                            duration: const Duration(milliseconds: 2500),
                            backgroundColor: Colors.red.shade400,
                          ));
                          return;
                        }
                      }

                      // Calculate games won
                      int playerGames = 0;
                      int opponentGames = 0;
                      if (g1Entered) { if (g1p > g1o) playerGames++; else opponentGames++; }
                      if (g2Entered) { if (g2p > g2o) playerGames++; else opponentGames++; }
                      if (g3Entered) { if (g3p > g3o) playerGames++; else opponentGames++; }

                      // Handle 1-1 tie-breaker
                      if (_mode == 'result' && g2Entered && !g3Entered && playerGames == 1 && opponentGames == 1) {
                        final playerName = _model.playerNameTextController.text.isNotEmpty ? _model.playerNameTextController.text : 'You';
                        final opponentName = _model.opponentNameTextController.text.isNotEmpty ? _model.opponentNameTextController.text : 'Opponent';
                        final winner = await showDialog<String>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Who won the match?', style: TextStyle(fontWeight: FontWeight.bold)),
                            content: const Text('The match is level at 1-1. Please select the winner.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, 'player'), child: Text(playerName, style: const TextStyle(fontWeight: FontWeight.bold))),
                              TextButton(onPressed: () => Navigator.pop(ctx, 'opponent'), child: Text(opponentName, style: const TextStyle(fontWeight: FontWeight.bold))),
                            ],
                          ),
                        );
                        if (winner == null) return;
                        if (winner == 'player') playerGames++; else opponentGames++;
                      }

                      // Set currentGame based on games played
                      final gamesPlayed = g3Entered ? 3 : g2Entered ? 2 : 1;
                      final docRef = MatchesRecord.collection.doc();
                      await docRef.set(createMatchesRecordData(
                        ownerUid: currentUserUid,
                        playerName: _model.playerNameTextController.text,
                        opponentName: _model.opponentNameTextController.text,
                        opponentHandedness: _opponentHandedness,
                        matchDate: getCurrentTimestamp,
                        notes: _model.notesTextFieldTextController.text,
                        matchType: _model.matchTypeValue,
                        g1Player: _mode == 'result' ? g1p : 0,
                        g1Opponent: _mode == 'result' ? g1o : 0,
                        g2Player: _mode == 'result' ? g2p : 0,
                        g2Opponent: _mode == 'result' ? g2o : 0,
                        g3Player: _mode == 'result' ? g3p : 0,
                        g3Opponent: _mode == 'result' ? g3o : 0,
                        currentGame: _mode == 'live' ? 1 : gamesPlayed,
                        mood: _selectedMood,
                        partnerName: _model.partnerNameTextController.text,
                        opponentPartnerName: _model.opponentPartnerNameTextController?.text ?? '',
                        scoringFormat: _scoringFormat,
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Match Saved!', style: TextStyle(color: FlutterFlowTheme.of(context).primaryText)),
                        duration: const Duration(milliseconds: 2000),
                        backgroundColor: FlutterFlowTheme.of(context).secondary,
                      ));
                      if (_mode == 'live') {
                        context.pushNamed(MatchDetailsWidget.routeName, queryParameters: {'matchRef': serializeParam(docRef, ParamType.DocumentReference)});
                      } else {
                        context.goNamed(MatchesListWidget.routeName);
                      }
                    },
                    text: _mode == 'live' ? 'Start Match' : 'Save Result',
                    options: FFButtonOptions(
                      width: double.infinity, height: 50.0,
                      padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                      iconPadding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                      color: primary,
                      textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                        font: GoogleFonts.interTight(fontWeight: FlutterFlowTheme.of(context).titleSmall.fontWeight, fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle),
                        color: Colors.white, letterSpacing: 0.0,
                      ),
                      elevation: 0.0, borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _sectionHeader(BuildContext context, IconData icon, String title, Color color) {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: color),
      ),
      const SizedBox(width: 10),
      Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
    ],
  );
}

class _OpponentField extends StatefulWidget {
  final TextEditingController controller;
  final String ownerUid;
  final dynamic theme;

  const _OpponentField({
    required this.controller,
    required this.ownerUid,
    required this.theme,
  });

  @override
  State<_OpponentField> createState() => _OpponentFieldState();
}

class _OpponentFieldState extends State<_OpponentField> {
  List<String> _previousOpponents = [];
  bool _showSuggestions = false;
  List<String> _filtered = [];

  @override
  void initState() {
    super.initState();
    _loadOpponents();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text.toLowerCase();
    setState(() {
      _filtered = _previousOpponents
          .where((o) => o.toLowerCase().contains(text) && o.toLowerCase() != text)
          .toList();
      _showSuggestions = text.isNotEmpty && _filtered.isNotEmpty;
    });
  }

  Future<void> _loadOpponents() async {
    final matches = await FirebaseFirestore.instance
        .collection('matches')
        .where('ownerUid', isEqualTo: widget.ownerUid)
        .get();
    final opponents = matches.docs
        .map((d) => d.data()['OpponentName'] as String? ?? '')
        .where((o) => o.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    setState(() => _previousOpponents = opponents);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: 'Opponent Name',
            hintText: 'Type or select opponent',
            filled: true,
            fillColor: widget.theme.secondaryBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide.none,
            ),
            suffixIcon: _previousOpponents.isNotEmpty
                ? PopupMenuButton<String>(
                    icon: const Icon(Icons.arrow_drop_down),
                    onSelected: (val) {
                      widget.controller.text = val;
                      setState(() => _showSuggestions = false);
                    },
                    itemBuilder: (context) => _previousOpponents
                        .map((o) => PopupMenuItem(value: o, child: Text(o)))
                        .toList(),
                  )
                : null,
          ),
        ),
        if (_showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
            ),
            child: Column(
              children: _filtered.map((o) => ListTile(
                dense: true,
                leading: const Icon(Icons.person, size: 18),
                title: Text(o, style: const TextStyle(fontSize: 14)),
                onTap: () {
                  widget.controller.text = o;
                  setState(() => _showSuggestions = false);
                },
              )).toList(),
            ),
          ),
      ],
    );
  }
}
