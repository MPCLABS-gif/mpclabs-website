import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'matches_list_model.dart';
export 'matches_list_model.dart';

class MatchesListWidget extends StatefulWidget {
  const MatchesListWidget({super.key});
  static String routeName = 'MatchesList';
  static String routePath = '/matchesList';
  @override
  State<MatchesListWidget> createState() => _MatchesListWidgetState();
}

class _MatchesListWidgetState extends State<MatchesListWidget> {
  late MatchesListModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MatchesListModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  String? _matchWinner(MatchesRecord match) {
    int playerGames = 0;
    int opponentGames = 0;
    for (final pair in [
      [match.g1Player, match.g1Opponent],
      [match.g2Player, match.g2Opponent],
      [match.g3Player, match.g3Opponent],
    ]) {
      final p = pair[0];
      final o = pair[1];
      if ((p >= 21 && (p - o) >= 2) || p >= 30) {
        playerGames++;
      } else if ((o >= 21 && (o - p) >= 2) || o >= 30) opponentGames++;
    }
    if (playerGames >= 2) return 'player';
    if (opponentGames >= 2) return 'opponent';
    return null;
  }

  bool _isG3(MatchesRecord match) => match.g3Player > 0 || match.g3Opponent > 0;

  void _showDeleteDialog(BuildContext context, MatchesRecord match) {
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
            Text('${match.playerName} vs ${match.opponentName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Match', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                await match.reference.delete();
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Match deleted')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
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
        leading: IconButton(icon: const Icon(Icons.home, color: Colors.white), onPressed: () => context.goNamed(HomePageWidget.routeName)),
        title: Text('My Matches', style: GoogleFonts.interTight(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: () => context.pushNamed(AddMatchWidget.routeName))],
        elevation: 2.0,
      ),
      body: SafeArea(
        top: true,
        child: StreamBuilder<List<MatchesRecord>>(
          stream: queryMatchesRecord(
            queryBuilder: (q) => q.where('ownerUid', isEqualTo: currentUserUid).orderBy('matchDate', descending: true),
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primary)));

            final allMatches = snapshot.data!;

            if (allMatches.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sports_tennis, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('No matches yet', style: TextStyle(fontSize: 18, color: Colors.grey.shade500)),
                    const SizedBox(height: 8),
                    Text('Tap + to add your first match', style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
                  ],
                ),
              );
            }

            final totalMatches = allMatches.length;
            final wins = allMatches.where((m) => _matchWinner(m) == 'player').length;
            final losses = allMatches.where((m) => _matchWinner(m) == 'opponent').length;
            final winRate = totalMatches > 0 ? ((wins / totalMatches) * 100).round() : 0;

            final filtered = allMatches.where((m) {
              final winner = _matchWinner(m);
              if (_filter == 'Wins') return winner == 'player';
              if (_filter == 'Losses') return winner == 'opponent';
              if (_filter == 'Tournament') return m.matchType == 'Tournament';
              if (_filter == 'Practice') return m.matchType == 'Practice';
              return true;
            }).toList();

            return Column(
              children: [
                Container(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      _statPill('$totalMatches', 'Total', Colors.grey.shade700),
                      _divider(),
                      _statPill('$wins', 'Wins', Colors.green.shade600),
                      _divider(),
                      _statPill('$losses', 'Losses', Colors.red.shade500),
                      _divider(),
                      _statPill('$winRate%', 'Win Rate', primary),
                    ],
                  ),
                ),
                Container(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Wins', 'Losses', 'Tournament', 'Practice'].map((f) {
                        final isSelected = _filter == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _filter = f),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isSelected ? primary : Colors.grey.shade300),
                              ),
                              child: Text(f, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Colors.grey.shade600)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(child: Text('No matches found', style: TextStyle(color: Colors.grey.shade400, fontSize: 15)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final match = filtered[index];
                            final winner = _matchWinner(match);
                            final isWin = winner == 'player';
                            final isLoss = winner == 'opponent';
                            final isG3 = _isG3(match);
                            final borderColor = isWin ? Colors.green.shade400 : isLoss ? Colors.red.shade400 : Colors.grey.shade300;
                            final dateStr = match.matchDate != null ? DateFormat('dd MMM yyyy').format(match.matchDate!) : '';

                            return GestureDetector(
                              onTap: () => context.pushNamed(MatchDetailsWidget.routeName, queryParameters: {'matchRef': serializeParam(match.reference, ParamType.DocumentReference)}),
                              onLongPress: () => _showDeleteDialog(context, match),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context).secondaryBackground,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border(left: BorderSide(color: borderColor, width: 4)),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 36, height: 36,
                                            decoration: BoxDecoration(shape: BoxShape.circle, color: isWin ? Colors.green.shade500 : isLoss ? Colors.red.shade400 : Colors.grey.shade300),
                                            child: Center(child: Text(isWin ? 'W' : isLoss ? 'L' : '–', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(child: Text(match.playerName, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
                                          if (isG3) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.amber.shade300)),
                                              child: Text('G3', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade800)),
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(color: match.matchType == 'Tournament' ? Colors.orange.shade100 : Colors.blue.shade100, borderRadius: BorderRadius.circular(20)),
                                            child: Text(match.matchType, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: match.matchType == 'Tournament' ? Colors.orange.shade800 : Colors.blue.shade800)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 46),
                                        child: Text('vs ${match.opponentName}', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                                      ),
                                      const SizedBox(height: 4),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 46),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${match.g1Player}-${match.g1Opponent}  ${match.g2Player}-${match.g2Opponent}${isG3 ? '  ${match.g3Player}-${match.g3Opponent}' : ''}',
                                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                                            ),
                                            Text(dateStr, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _statPill(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 30, color: Colors.grey.shade200);
}
