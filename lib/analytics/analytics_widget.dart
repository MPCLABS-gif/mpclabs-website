import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'analytics_model.dart';
export 'analytics_model.dart';

class AnalyticsWidget extends StatefulWidget {
  const AnalyticsWidget({super.key});
  static String routeName = 'Analytics';
  static String routePath = '/analytics';

  @override
  State<AnalyticsWidget> createState() => _AnalyticsWidgetState();
}

class _AnalyticsWidgetState extends State<AnalyticsWidget> {
  late AnalyticsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AnalyticsModel());
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

  bool _isMatchComplete(MatchesRecord match) => _matchWinner(match) != null;

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
        title: Text("Analytics", style: GoogleFonts.interTight(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        elevation: 2.0,
      ),
      body: SafeArea(
        top: true,
        child: StreamBuilder<List<MatchesRecord>>(
          stream: queryMatchesRecord(
            queryBuilder: (q) => q
                .where("ownerUid", isEqualTo: currentUserUid)
                .orderBy("matchDate", descending: true),
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primary)));
            }

            final allMatches = snapshot.data!;
            final completed = allMatches.where(_isMatchComplete).toList();

            if (completed.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text("No completed matches yet", style: TextStyle(fontSize: 18, color: Colors.grey.shade500)),
                    const SizedBox(height: 8),
                    Text("Complete some matches to see analytics", style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
                  ],
                ),
              );
            }

            // ── Calculate Stats ──
            final wins = completed.where((m) => _matchWinner(m) == "player").toList();
            final losses = completed.where((m) => _matchWinner(m) == "opponent").toList();
            final winRate = completed.isEmpty ? 0.0 : wins.length / completed.length;

            // Tournament vs Practice
            final tournamentMatches = completed.where((m) => m.matchType == "Tournament").toList();
            final practiceMatches = completed.where((m) => m.matchType == "Practice").toList();
            final tournamentWins = tournamentMatches.where((m) => _matchWinner(m) == "player").length;
            final practiceWins = practiceMatches.where((m) => _matchWinner(m) == "player").length;
            final tournamentWinRate = tournamentMatches.isEmpty ? 0.0 : tournamentWins / tournamentMatches.length;
            final practiceWinRate = practiceMatches.isEmpty ? 0.0 : practiceWins / practiceMatches.length;

            // Win streak
            int currentStreak = 0;
            int bestStreak = 0;
            int tempStreak = 0;
            for (final match in completed) {
              if (_matchWinner(match) == "player") {
                tempStreak++;
                if (tempStreak > bestStreak) bestStreak = tempStreak;
              } else {
                tempStreak = 0;
              }
            }
            // Current streak (from most recent)
            for (final match in completed) {
              if (_matchWinner(match) == "player") {
                currentStreak++;
              } else {
                break;
              }
            }

            // Game 3 record
            final game3Matches = completed.where((m) {
              return m.g3Player > 0 || m.g3Opponent > 0;
            }).toList();
            final game3Wins = game3Matches.where((m) => _matchWinner(m) == "player").length;

            // Comeback rate (lost game 1, won match)
            final lostGame1 = completed.where((m) {
              final g1Winner = m.g1Player > m.g1Opponent ? "player" : "opponent";
              return g1Winner == "opponent" && _matchWinner(m) == "player";
            }).toList();
            final hadGame1Loss = completed.where((m) {
              return m.g1Player < m.g1Opponent;
            }).length;

            // Head to head
            final Map<String, Map<String, int>> h2h = {};
            for (final match in completed) {
              final opp = match.opponentName;
              h2h[opp] ??= {"wins": 0, "losses": 0};
              if (_matchWinner(match) == "player") {
                h2h[opp]!["wins"] = h2h[opp]!["wins"]! + 1;
              } else {
                h2h[opp]!["losses"] = h2h[opp]!["losses"]! + 1;
              }
            }

            // Points per game average
            int totalPlayerPoints = 0;
            int totalOpponentPoints = 0;
            int totalGames = 0;
            for (final match in completed) {
              if (match.g1Player > 0 || match.g1Opponent > 0) {
                totalPlayerPoints += match.g1Player + match.g2Player + match.g3Player;
                totalOpponentPoints += match.g1Opponent + match.g2Opponent + match.g3Opponent;
                totalGames++;
              }
            }
            final avgPlayerPoints = totalGames > 0 ? (totalPlayerPoints / totalGames).toStringAsFixed(1) : "0";
            final avgOpponentPoints = totalGames > 0 ? (totalOpponentPoints / totalGames).toStringAsFixed(1) : "0";

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [

                // ── Overall Performance ──
                _sectionTitle("Overall Performance", icon: Icons.emoji_events_rounded, iconColor: Colors.amber.shade700),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _bigStatCard(context, "${wins.length}", "Wins", Colors.green),
                    const SizedBox(width: 10),
                    _bigStatCard(context, "${losses.length}", "Losses", Colors.red),
                    const SizedBox(width: 10),
                    _bigStatCard(context, "${(winRate * 100).round()}%", "Win Rate", primary),
                  ],
                ),
                const SizedBox(height: 10),
                _progressBar(context, "Win Rate", winRate, primary, subtitle: "${wins.length} wins from ${completed.length} completed matches"),
                const SizedBox(height: 24),

                // ── Win Streaks ──
                _sectionTitle("Win Streaks", icon: Icons.local_fire_department_rounded, iconColor: Colors.deepOrange, iconBg: Colors.orange),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _bigStatCard(context, "$currentStreak", "Current Streak", currentStreak > 0 ? Colors.green : Colors.grey, subtitle: currentStreak >= 3 ? "🔥 On a roll!" : currentStreak > 0 ? "Keep it up!" : ""),
                    const SizedBox(width: 16),
                    _bigStatCard(context, "$bestStreak", "Best Streak", Colors.amber.shade700, subtitle: "🏆 Personal best"),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Tournament vs Practice ──
                _sectionTitle("Tournament vs Practice", icon: Icons.compare_arrows_rounded, iconColor: Colors.blueGrey),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _comparisonCard(
                        context,
                        "Tournament",
                        "${(tournamentWinRate * 100).round()}%",
                        Colors.orange,
                        wins: tournamentWins,
                        total: tournamentMatches.length,
                        rateValue: tournamentWinRate,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _comparisonCard(
                        context,
                        "Practice",
                        "${(practiceWinRate * 100).round()}%",
                        Colors.blue,
                        wins: practiceWins,
                        total: practiceMatches.length,
                        rateValue: practiceWinRate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Game 3 & Comebacks ──
                _sectionTitle("Performance Under Pressure", icon: Icons.psychology_rounded, iconColor: Colors.purple),
                const SizedBox(height: 4),
                Text("How you perform in deciding games and comeback situations",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _infoCard(
                        context,
                        "Game 3 Record",
                        game3Matches.isEmpty ? "No G3 yet" : "$game3Wins / ${game3Matches.length}",
                        game3Matches.isEmpty ? "Play more matches" : "${game3Matches.isEmpty ? 0 : (game3Wins / game3Matches.length * 100).round()}% win rate in deciders",
                        Icons.sports_tennis,
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _infoCard(
                        context,
                        "Comebacks",
                        "${lostGame1.length}",
                        lostGame1.isEmpty ? "No comebacks yet" : "Won after losing G1 ${hadGame1Loss > 0 ? (lostGame1.length / hadGame1Loss * 100).round() : 0}% of the time",
                        Icons.trending_up,
                        Colors.teal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Points Average ──
                _sectionTitle("Points Per Match", icon: Icons.bar_chart_rounded, iconColor: Colors.indigo),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text(avgPlayerPoints, style: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.bold, color: primary)),
                              Text("Your avg", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                            ],
                          ),
                          Text("vs", style: TextStyle(fontSize: 18, color: Colors.grey.shade400)),
                          Column(
                            children: [
                              Text(avgOpponentPoints, style: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                              Text("Opp avg", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                            ],
                          ),
                        ],
                      ),
                      if (totalGames > 0) ...[
                        const SizedBox(height: 12),
                        Builder(builder: (context) {
                          final playerAvg = totalPlayerPoints / totalGames;
                          final oppAvg = totalOpponentPoints / totalGames;
                          final diff = (playerAvg - oppAvg).abs().toStringAsFixed(1);
                          final isAhead = playerAvg >= oppAvg;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isAhead ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isAhead ? "You score $diff more points per match 💪" : "Opponent scores $diff more points per match",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isAhead ? Colors.green.shade600 : Colors.red.shade500),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Head to Head ──
                if (h2h.isNotEmpty) ...[
                  _sectionTitle("Head to Head", icon: Icons.people_alt_rounded, iconColor: Colors.indigo),
                  const SizedBox(height: 10),
                  ...h2h.entries.map((entry) {
                    final opp = entry.key;
                    final w = entry.value["wins"]!;
                    final l = entry.value["losses"]!;
                    final total = w + l;
                    final rate = total > 0 ? w / total : 0.0;
                    final borderColor = w > l ? Colors.green.shade400 : w < l ? Colors.red.shade400 : Colors.grey.shade300;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border(left: BorderSide(color: borderColor, width: 4)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(opp, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: (w > l ? Colors.green : w < l ? Colors.red : Colors.grey).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                  child: Text("$w W — $l L", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: w > l ? Colors.green.shade700 : w < l ? Colors.red.shade700 : Colors.grey)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: rate,
                                backgroundColor: Colors.red.shade50,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade400),
                                minHeight: 10,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text("${(rate * 100).round()}% win rate against $opp", style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],

                // ── Mood Performance ──
                _sectionTitle("Performance by Mood", icon: Icons.sentiment_satisfied_alt_rounded, iconColor: Colors.pink),
                const SizedBox(height: 10),
                Builder(builder: (context) {
                  final Map<String, Map<String, int>> moodStats = {};
                  for (final match in completed) {
                    if (match.mood.isEmpty) continue;
                    moodStats[match.mood] ??= {"wins": 0, "total": 0};
                    moodStats[match.mood]!["total"] = moodStats[match.mood]!["total"]! + 1;
                    if (_matchWinner(match) == "player") {
                      moodStats[match.mood]!["wins"] = moodStats[match.mood]!["wins"]! + 1;
                    }
                  }
                  if (moodStats.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: FlutterFlowTheme.of(context).secondaryBackground, borderRadius: BorderRadius.circular(12)),
                      child: Text("No mood data yet — select your mood when adding matches!", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                    );
                  }
                  final emojis = {"Excited": "🔥", "Confident": "💪", "Nervous": "😬", "Focused": "🎯", "Tired": "😴", "Anxious": "😰", "Sad": "😔", "Upset": "😤"};
                  return Column(
                    children: moodStats.entries.map((entry) {
                      final mood = entry.key;
                      final wins = entry.value["wins"]!;
                      final total = entry.value["total"]!;
                      final rate = total > 0 ? wins / total : 0.0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: FlutterFlowTheme.of(context).secondaryBackground, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("${emojis[mood] ?? ""} $mood", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text("$wins/$total  •  ${(rate * 100).round()}%", style: TextStyle(fontWeight: FontWeight.w600, color: rate >= 0.5 ? Colors.green : Colors.red)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: rate,
                                backgroundColor: Colors.red.shade50,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade400),
                                minHeight: 10,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                }),
                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {IconData? icon, Color? iconColor, Color? iconBg}) {
    if (icon == null) return Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16));
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: (iconBg ?? iconColor ?? Colors.grey).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor ?? Colors.grey),
        ),
        const SizedBox(width: 10),
        Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _bigStatCard(BuildContext context, String value, String label, Color color, {String? subtitle}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.12)),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade500), textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }

  Widget _progressBar(BuildContext context, String label, double value, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              Text("${(value * 100).round()}%", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ],
      ),
    );
  }

  Widget _comparisonCard(BuildContext context, String title, String rate, Color color, {required int wins, required int total, required double rateValue}) {
    final icon = title == "Tournament" ? Icons.emoji_events_rounded : Icons.fitness_center_rounded;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
          ]),
          const SizedBox(height: 10),
          Text(rate, style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          Text("win rate", style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rateValue,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text("$wins wins from $total ${total == 1 ? 'match' : 'matches'}", style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _infoCard(BuildContext context, String title, String value, String subtitle, IconData icon, Color color) {
    return IntrinsicHeight(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: color)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}
