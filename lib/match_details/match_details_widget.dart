import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/share/share_card_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'match_details_model.dart';
export 'match_details_model.dart';

class MatchDetailsWidget extends StatefulWidget {
  const MatchDetailsWidget({
    super.key,
    required this.matchRef,
  });

  final DocumentReference? matchRef;

  static String routeName = 'MatchDetails';
  static String routePath = '/matchDetails';

  @override
  State<MatchDetailsWidget> createState() => _MatchDetailsWidgetState();
}

class _MatchDetailsWidgetState extends State<MatchDetailsWidget> {
  late MatchDetailsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MatchDetailsModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  bool _isGameWon(int p, int o, {int target = 21}) {
    final cap = target == 15 ? 17 : 30;
    if (p >= cap) return true;
    if (o >= cap) return true;
    if (p >= target && (p - o) >= 2) return true;
    if (o >= target && (o - p) >= 2) return true;
    return false;
  }

  String? _gameWinner(int p, int o, {int target = 21}) {
    if (!_isGameWon(p, o, target: target)) return null;
    return p > o ? 'player' : 'opponent';
  }

  int _scoringTarget(MatchesRecord match) =>
      match.scoringFormat == '15' ? 15 : 21;

  Map<String, int> _gamesWon(MatchesRecord match) {
    final target = _scoringTarget(match);
    int playerGames = 0;
    int opponentGames = 0;
    for (final pair in [
      [match.g1Player, match.g1Opponent],
      [match.g2Player, match.g2Opponent],
      [match.g3Player, match.g3Opponent],
    ]) {
      final w = _gameWinner(pair[0], pair[1], target: target);
      if (w == 'player') playerGames++;
      if (w == 'opponent') opponentGames++;
    }
    return {'player': playerGames, 'opponent': opponentGames};
  }

  bool _isMatchOver(MatchesRecord match) {
    final gw = _gamesWon(match);
    return gw['player']! >= 2 || gw['opponent']! >= 2;
  }

  String _playerField(int currentGame) {
    switch (currentGame) {
      case 2: return 'g2Player';
      case 3: return 'g3Player';
      default: return 'g1Player';
    }
  }

  String _opponentField(int currentGame) {
    switch (currentGame) {
      case 2: return 'g2Opponent';
      case 3: return 'g3Opponent';
      default: return 'g1Opponent';
    }
  }

  List<int> _currentScores(MatchesRecord match) {
    switch (match.currentGame) {
      case 2: return [match.g2Player, match.g2Opponent];
      case 3: return [match.g3Player, match.g3Opponent];
      default: return [match.g1Player, match.g1Opponent];
    }
  }

  Future<void> _incrementScore(MatchesRecord match, bool isPlayer) async {
    if (_isMatchOver(match)) return;
    final currentGame = match.currentGame == 0 ? 1 : match.currentGame;
    final scores = _currentScores(match);
    final p = scores[0];
    final o = scores[1];
    final target = _scoringTarget(match);
    if (_isGameWon(p, o, target: target)) return;

    final field = isPlayer ? _playerField(currentGame) : _opponentField(currentGame);
    await widget.matchRef!.update({
      ...mapToFirestore({field: FieldValue.increment(1)}),
    });

    final newP = isPlayer ? p + 1 : p;
    final newO = isPlayer ? o : o + 1;

    if (_isGameWon(newP, newO, target: target)) {
      final gamesWon = _gamesWon(match);
      final playerTotal = gamesWon['player']! + (isPlayer ? 1 : 0);
      final opponentTotal = gamesWon['opponent']! + (isPlayer ? 0 : 1);

      if (playerTotal >= 2 || opponentTotal >= 2) {
        final winner = playerTotal >= 2 ? match.playerName : match.opponentName;
        await widget.matchRef!.update(mapToFirestore({
          'matchWinner': winner,
          'matchCompleted': true,
        }));
      } else {
        await widget.matchRef!.update(mapToFirestore({'currentGame': currentGame + 1}));
      }
    }
  }

  void _showEditScoresDialog(BuildContext context, MatchesRecord match) {
    final g1p = TextEditingController(text: match.g1Player.toString());
    final g1o = TextEditingController(text: match.g1Opponent.toString());
    final g2p = TextEditingController(text: match.g2Player.toString());
    final g2o = TextEditingController(text: match.g2Opponent.toString());
    final g3p = TextEditingController(text: match.g3Player.toString());
    final g3o = TextEditingController(text: match.g3Opponent.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Scores'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _scoreRow('Game 1', g1p, g1o),
              const SizedBox(height: 12),
              _scoreRow('Game 2', g2p, g2o),
              const SizedBox(height: 12),
              _scoreRow('Game 3', g3p, g3o),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await widget.matchRef!.update({
                  'g1Player': int.tryParse(g1p.text) ?? match.g1Player,
                  'g1Opponent': int.tryParse(g1o.text) ?? match.g1Opponent,
                  'g2Player': int.tryParse(g2p.text) ?? match.g2Player,
                  'g2Opponent': int.tryParse(g2o.text) ?? match.g2Opponent,
                  'g3Player': int.tryParse(g3p.text) ?? match.g3Player,
                  'g3Opponent': int.tryParse(g3o.text) ?? match.g3Opponent,
                });
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _scoreRow(String label, TextEditingController player, TextEditingController opponent) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        const SizedBox(width: 8),
        Expanded(child: TextField(controller: player, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'You', border: OutlineInputBorder(), isDense: true))),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('–')),
        Expanded(child: TextField(controller: opponent, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Opp', border: OutlineInputBorder(), isDense: true))),
      ],
    );
  }

  Future<void> _decrementScore(MatchesRecord match, bool isPlayer) async {
    if (_isMatchOver(match)) return;
    final currentGame = match.currentGame == 0 ? 1 : match.currentGame;
    final scores = _currentScores(match);
    final p = scores[0];
    final o = scores[1];
    if (isPlayer && p <= 0) return;
    if (!isPlayer && o <= 0) return;

    final field = isPlayer ? _playerField(currentGame) : _opponentField(currentGame);
    await widget.matchRef!.update({
      ...mapToFirestore({field: FieldValue.increment(-1)}),
    });
  }

  Widget _buildGameRow(BuildContext context, String label, int playerScore,
      int opponentScore, bool isActive, MatchesRecord match) {
    final winner = _gameWinner(playerScore, opponentScore);
    final Color activeColor = FlutterFlowTheme.of(context).primary;
    final Color rowColor = isActive ? activeColor : Colors.grey.shade400;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: isActive
            ? FlutterFlowTheme.of(context).primary.withOpacity(0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isActive ? activeColor : Colors.grey.shade300,
            width: isActive ? 2 : 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight:
                      isActive ? FontWeight.bold : FontWeight.normal,
                  color: rowColor,
                  fontSize: 14)),
          Row(
            children: [
              Text('$playerScore',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: winner == 'player' ? Colors.green : rowColor)),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('–',
                      style: TextStyle(fontSize: 18, color: rowColor))),
              Text('$opponentScore',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color:
                          winner == 'opponent' ? Colors.green : rowColor)),
            ],
          ),
          if (winner != null)
            Icon(winner == 'player' ? Icons.person : Icons.group,
                color: Colors.green, size: 18)
          else
            const SizedBox(width: 18),
        ],
      ),
    );
  }

  Widget _buildScoreButton({
    required String label,
    required VoidCallback? onTap,
    required VoidCallback? onUndo,
    required Color color,
    required bool disabled,
  }) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: disabled ? null : onTap,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: disabled ? Colors.grey.shade300 : color,
              boxShadow: disabled
                  ? []
                  : [
                      BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
            ),
            child: Center(
                child: Text('+1',
                    style: TextStyle(
                        color: disabled ? Colors.grey : Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold))),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: disabled ? null : onUndo,
          icon: const Icon(Icons.undo, size: 14),
          label: const Text('Undo', style: TextStyle(fontSize: 12)),
          style: TextButton.styleFrom(
              foregroundColor:
                  disabled ? Colors.grey : Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 30)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MatchesRecord>(
      stream: MatchesRecord.getDocument(widget.matchRef!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor:
                FlutterFlowTheme.of(context).primaryBackground,
            body: Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        FlutterFlowTheme.of(context).primary))),
          );
        }

        final match = snapshot.data!;
        final currentGame =
            match.currentGame == 0 ? 1 : match.currentGame;
        final matchOver = _isMatchOver(match);
        final gamesWon = _gamesWon(match);
        final scores = _currentScores(match);
        final currentGameLocked = _isGameWon(scores[0], scores[1], target: _scoringTarget(match));
        final buttonsDisabled = matchOver || currentGameLocked;
        final playerWon = gamesWon['player']! >= 2;

        String matchStatusText = 'Game $currentGame';
        if (matchOver) {
          final winner = playerWon ? match.playerName : match.opponentName;
          matchStatusText = playerWon ? '${match.playerName} wins the match! 🏆' : 'Tough match — ${match.opponentName} won this one';
        }

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor:
                FlutterFlowTheme.of(context).primaryBackground,
            appBar: AppBar(
              backgroundColor: FlutterFlowTheme.of(context).primary,
              automaticallyImplyLeading: true,
              title: Text('MatchPoint Coach',
                  style: GoogleFonts.interTight(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              elevation: 2.0,
              // ── Share button in app bar (only when match is over) ──
              actions: matchOver
                  ? [
                      IconButton(
                        icon: const Icon(Icons.share_rounded,
                            color: Colors.white),
                        tooltip: 'Share result',
                        onPressed: () => showShareSheet(
                          context,
                          match,
                          playerWon,
                          gamesWon['player']!,
                          gamesWon['opponent']!,
                        ),
                      ),
                    ]
                  : null,
            ),
            body: SafeArea(
              top: true,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                  child: Text(match.playerName,
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18),
                                      overflow: TextOverflow.ellipsis)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: match.matchType == 'Tournament'
                                      ? Colors.orange.shade100
                                      : Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(match.matchType,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: match.matchType ==
                                                'Tournament'
                                            ? Colors.orange.shade800
                                            : Colors.blue.shade800)),
                              ),
                              Expanded(
                                  child: Text(match.opponentName,
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18),
                                      textAlign: TextAlign.right,
                                      overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                  children: List.generate(
                                      gamesWon['player']!,
                                      (_) => const Padding(
                                          padding:
                                              EdgeInsets.only(right: 4),
                                          child: Icon(Icons.circle,
                                              size: 12,
                                              color: Colors.green)))),
                              Text('Games',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500)),
                              Row(
                                  children: List.generate(
                                      gamesWon['opponent']!,
                                      (_) => const Padding(
                                          padding:
                                              EdgeInsets.only(left: 4),
                                          child: Icon(Icons.circle,
                                              size: 12,
                                              color: Colors.green)))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    _buildGameRow(context, 'Game 1', match.g1Player,
                        match.g1Opponent, currentGame == 1, match),
                    _buildGameRow(context, 'Game 2', match.g2Player,
                        match.g2Opponent, currentGame == 2, match),
                    _buildGameRow(context, 'Game 3', match.g3Player,
                        match.g3Opponent, currentGame == 3, match),
                    const SizedBox(height: 16),
                    Container(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16),
                      decoration: BoxDecoration(
                        color: matchOver
                            ? (playerWon ? Colors.green.shade50 : Colors.grey.shade100)
                            : FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                          child: Text(matchStatusText,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: matchOver
                                      ? (playerWon ? Colors.green.shade700 : Colors.grey.shade600)
                                      : FlutterFlowTheme.of(context).primary))),
                    ),
                    const SizedBox(height: 24),
                    if (!matchOver) ...[
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 32),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildScoreButton(
                              label: match.playerName.isNotEmpty
                                  ? match.playerName.split(' ')[0]
                                  : 'Player',
                              onTap: () =>
                                  _incrementScore(match, true),
                              onUndo: () =>
                                  _decrementScore(match, true),
                              color:
                                  FlutterFlowTheme.of(context).primary,
                              disabled: buttonsDisabled,
                            ),
                            _buildScoreButton(
                              label: match.opponentName.isNotEmpty
                                  ? match.opponentName.split(' ')[0]
                                  : 'Opponent',
                              onTap: () =>
                                  _incrementScore(match, false),
                              onUndo: () =>
                                  _decrementScore(match, false),
                              color: Colors.deepOrange,
                              disabled: buttonsDisabled,
                            ),
                          ],
                        ),
                      ),
                      if (currentGameLocked && !matchOver)
                        const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Text('Game complete — advancing...',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 13))),
                    ] else ...[
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: playerWon ? Colors.amber.shade50 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: playerWon ? Colors.amber.shade200 : Colors.grey.shade300,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: playerWon
                                  ? Colors.amber.withOpacity(0.15)
                                  : Colors.grey.withOpacity(0.1),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // ── Icon ──
                            playerWon
                                ? const Icon(Icons.emoji_events, size: 84, color: Colors.amber)
                                : Icon(Icons.bar_chart_rounded, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),

                            // ── Title ──
                            Text(
                              playerWon ? 'You Won!' : 'Match Lost',
                              style: GoogleFonts.interTight(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: playerWon ? Colors.amber.shade800 : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // ── Score ──
                            Text(
                              '${gamesWon['player']} – ${gamesWon['opponent']}',
                              style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text('in games won',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),

                            // ── Recovery line for loss ──
                            if (!playerWon) ...[
                              const SizedBox(height: 10),
                              Text(
                                'Review your performance and improve',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],

                            const SizedBox(height: 20),

                            // ── Saved confirmation ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline, color: Colors.green.shade400, size: 14),
                                const SizedBox(width: 4),
                                Text('Match saved to your history',
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400)),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // ── Notes ──
                            if (match.notes.isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Icon(Icons.notes, size: 14, color: Colors.grey.shade600),
                                      const SizedBox(width: 6),
                                      Text('Match Notes',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                                    ]),
                                    const SizedBox(height: 6),
                                    Text(match.notes, style: const TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                            if (match.notes.isNotEmpty) const SizedBox(height: 24),

                            // ── Edit Scores ──
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _showEditScoresDialog(context, match),
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Edit Scores'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey.shade700,
                                  side: BorderSide(color: Colors.grey.shade400),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // ── Primary CTA: win=Share, loss=Get Insights ──
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => playerWon
                                    ? showShareSheet(context, match, playerWon, gamesWon['player']!, gamesWon['opponent']!)
                                    : context.pushNamed('AiCoach'),
                                icon: Icon(
                                  playerWon ? Icons.share_rounded : Icons.psychology_rounded,
                                  color: Colors.white, size: 18,
                                ),
                                label: Text(
                                  playerWon ? 'Share Your Win' : 'Get Insights',
                                  style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: playerWon
                                      ? const Color(0xFF4B39EF)
                                      : Colors.grey.shade700,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // ── Secondary: Done ──
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => context.goNamed('HomePage'),
                                icon: Icon(Icons.home,
                                    color: playerWon ? Colors.green.shade700 : Colors.grey.shade600,
                                    size: 18),
                                label: Text('Done — Go to Home',
                                    style: GoogleFonts.inter(
                                        color: playerWon ? Colors.green.shade700 : Colors.grey.shade600,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(
                                      color: playerWon ? Colors.green.shade400 : Colors.grey.shade400,
                                      width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
