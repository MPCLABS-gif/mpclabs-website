import 'dart:ui';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/services/premium_service.dart';
import '/premium/premium_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ai_coach_model.dart';
export 'ai_coach_model.dart';

class AiCoachWidget extends StatefulWidget {
  const AiCoachWidget({super.key});
  static String routeName = 'AiCoach';
  static String routePath = '/aiCoach';
  @override
  State<AiCoachWidget> createState() => _AiCoachWidgetState();
}

class _AiCoachWidgetState extends State<AiCoachWidget> {
  late AiCoachModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _premiumService = PremiumService();
  String _tier = 'free';
  bool _loadingStatus = true;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AiCoachModel());
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final status = await _premiumService.getSubscriptionStatus().timeout(
        const Duration(seconds: 5),
        onTimeout: () => {'tier': 'free'},
      );
      if (mounted) {
        setState(() {
          _tier = status['tier'] as String;
          _loadingStatus = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _tier = 'free';
          _loadingStatus = false;
        });
      }
    }
  }

  String? _matchWinner(MatchesRecord match) {
    final target = match.scoringFormat == '15' ? 15 : 21;
    final cap = target == 15 ? 17 : 30;
    int playerGames = 0;
    int opponentGames = 0;
    for (final pair in [[match.g1Player, match.g1Opponent],[match.g2Player, match.g2Opponent],[match.g3Player, match.g3Opponent]]) {
      final p = pair[0]; final o = pair[1];
      if ((p >= target && (p - o) >= 2) || p >= cap) playerGames++;
      else if ((o >= target && (o - p) >= 2) || o >= cap) opponentGames++;
    }
    if (playerGames >= 2) return "player";
    if (opponentGames >= 2) return "opponent";
    return null;
  }

  Map<String, String> _computeBlurredInsights(List<MatchesRecord> completed) {
    final hasEnoughData = completed.length >= 5;
    String slowStart = completed.length >= 5 ? () { final lostG1 = completed.where((m) => m.g1Player < m.g1Opponent).length; final pct = ((lostG1 / completed.length) * 100).round(); return "You start slow in ${pct}% of matches"; }() : "We are building your performance profile";
    if (completed.isNotEmpty) {
      final lostG1 = completed.where((m) => m.g1Player < m.g1Opponent).length;
      final pct = ((lostG1 / completed.length) * 100).round();
    // handled above
    }
    String tiredStat = "Your win rate drops when tired";
    final tiredMatches = completed.where((m) => m.mood.toLowerCase().contains('tired')).toList();
    if (tiredMatches.length >= 2) {
      final tiredWins = tiredMatches.where((m) => _matchWinner(m) == "player").length;
      final pct = ((tiredWins / tiredMatches.length) * 100).round();
      tiredStat = "Your win rate drops to ${pct}% when tired";
    }
    String ledLost = "You sometimes lose matches after leading";
    final wonG1 = completed.where((m) => m.g1Player > m.g1Opponent).toList();
    if (wonG1.isNotEmpty) {
      final ledThenLost = wonG1.where((m) => _matchWinner(m) == "opponent").length;
      if (ledThenLost > 0) ledLost = "You have lost \$ledThenLost match${ledThenLost == 1 ? '' : 'es'} after winning Game 1";
    }
    return {'slowStart': slowStart, 'tiredStat': tiredStat, 'ledLost': ledLost};
  }

  List<Map<String, dynamic>> _generateInsights(List<MatchesRecord> matches) {
    final completed = matches.where((m) => _matchWinner(m) != null).toList();
    if (completed.isEmpty) return [];
    final insights = <Map<String, dynamic>>[];
    final wins = completed.where((m) => _matchWinner(m) == "player").length;
    final winRate = wins / completed.length;

    if (completed.length < 5) {
      final remaining = 5 - completed.length;
      final remainingLabel = remaining == 1 ? "1 more match" : "$remaining more matches";
      insights.add({"icon": "🏸", "title": "Getting Started", "body": "We are learning your game. Play $remainingLabel to unlock your first coaching report.", "progress": completed.length, "tier": "free"});
    } else if (winRate >= 0.7) {
      insights.add({"icon": "🔥", "title": "Excellent Win Rate", "body": "Across ${completed.length} matches, you are winning ${(winRate * 100).round()}%. That is a strong record — keep the consistency.", "tier": "free"});
    } else if (winRate >= 0.5) {
      insights.add({"icon": "📈", "title": "Positive Win Rate", "body": "You are winning ${(winRate * 100).round()}% of your matches. You are on the right track — focus on closing out tight games.", "tier": "free"});
    } else {
      insights.add({"icon": "💪", "title": "Room to Grow", "body": "You are winning ${(winRate * 100).round()}% of matches so far. Every loss is a lesson — focus on one improvement at a time.", "tier": "free"});
    }

    final moodStats = <String, Map<String, int>>{};
    for (final m in completed) {
      if (m.mood.isEmpty) continue;
      moodStats[m.mood] ??= {"wins": 0, "total": 0};
      moodStats[m.mood]!["total"] = moodStats[m.mood]!["total"]! + 1;
      if (_matchWinner(m) == "player") moodStats[m.mood]!["wins"] = moodStats[m.mood]!["wins"]! + 1;
    }
    if (moodStats.isNotEmpty) {
      String? bestMood; double bestRate = 0;
      moodStats.forEach((mood, stats) {
        if (stats["total"]! >= 2) { final rate = stats["wins"]! / stats["total"]!; if (rate > bestRate) { bestRate = rate; bestMood = mood; } }
      });
      if (bestMood != null) insights.add({"icon": "🧠", "title": "Peak Performance Mood", "body": "You perform best when feeling ${bestMood} — winning ${(bestRate * 100).round()}% of those matches.", "tier": "free"});
    }

    int streak = 0;
    for (final m in completed) { if (_matchWinner(m) == "player") streak++; else break; }
    if (streak >= 3) insights.add({"icon": "🔥", "title": "On Fire!", "body": "You are on a ${streak} match winning streak. Ride this momentum.", "tier": "free"});
    else if (streak == 0 && completed.length >= 3) insights.add({"icon": "🔄", "title": "Reset Mode", "body": "Your last match was a loss. Review what happened and come back sharper.", "tier": "free"});

    if (moodStats.isNotEmpty) {
      String? worstMood; double worstRate = 1;
      moodStats.forEach((mood, stats) {
        if (stats["total"]! >= 2) { final rate = stats["wins"]! / stats["total"]!; if (rate < worstRate) { worstRate = rate; worstMood = mood; } }
      });
      if (worstMood != null && worstRate < 0.5) insights.add({"icon": "⚠️", "title": "Danger Mood Warning", "body": "You only win ${(worstRate * 100).round()}% when feeling ${worstMood}. Focus on mental reset before matches.", "tier": "pro"});
    }

    final tMatches = completed.where((m) => m.matchType == "Tournament").toList();
    final pMatches = completed.where((m) => m.matchType == "Practice").toList();
    // ── Match Frequency (free) ──
    if (completed.length >= 2) {
      final now = DateTime.now();
      final last30 = completed.where((m) => m.matchDate != null && now.difference(m.matchDate!).inDays <= 30).length;
      final freq = last30 >= 4 ? "great" : last30 >= 2 ? "steady" : "low";
      insights.add({
        "icon": "📅",
        "title": "Match Frequency",
        "body": "You have played $last30 ${last30 == 1 ? 'match' : 'matches'} in the last 30 days. ${freq == 'great' ? 'Great consistency — keep it up.' : freq == 'steady' ? 'Steady rhythm. Try to play more regularly.' : 'Playing more often will accelerate your improvement.'}",
        "tier": "free"
      });
    }

    // ── Match Balance (free) ──
    if (completed.length >= 3) {
      final tCount = completed.where((m) => m.matchType == "Tournament").length;
      final pCount = completed.where((m) => m.matchType == "Practice").length;
      final tPct = ((tCount / completed.length) * 100).round();
      final pPct = ((pCount / completed.length) * 100).round();
      insights.add({
        "icon": "⚖️",
        "title": "Match Balance",
        "body": "Your matches are $tPct% Tournament and $pPct% Practice. ${tPct > 70 ? 'More practice sessions will help you refine your game.' : pPct > 70 ? 'Great training base — start entering more tournaments.' : 'Good balance between competition and training.'}",
        "tier": "free"
      });
    }

    if (tMatches.isNotEmpty && pMatches.isNotEmpty) {
      final tRate = tMatches.where((m) => _matchWinner(m) == "player").length / tMatches.length;
      final pRate = pMatches.where((m) => _matchWinner(m) == "player").length / pMatches.length;
      if (tRate < pRate - 0.2) insights.add({"icon": "🏆", "title": "Tournament Pressure", "body": "Tournament win rate ${(tRate * 100).round()}% vs practice ${(pRate * 100).round()}%. Work on mental toughness.", "tier": "pro"});
      else if (tRate >= pRate) insights.add({"icon": "🏆", "title": "Tournament Beast", "body": "You perform better in tournaments ${(tRate * 100).round()}% than practice ${(pRate * 100).round()}%. You rise to the occasion.", "tier": "pro"});
    }

    final lostG1 = completed.where((m) => m.g1Player < m.g1Opponent).toList();
    if (lostG1.length >= 2) {
      final comebacks = lostG1.where((m) => _matchWinner(m) == "player").length;
      final rate = comebacks / lostG1.length;
      if (rate >= 0.5) insights.add({"icon": "🔄", "title": "Comeback King", "body": "You win ${(rate * 100).round()}% of matches after losing Game 1. Your resilience is a weapon.", "tier": "pro"});
      else insights.add({"icon": "🎯", "title": "Start Strong", "body": "When you lose Game 1 you rarely recover (${(rate * 100).round()}% comeback rate). Start with intensity.", "tier": "pro"});
    }

    final wonG1 = completed.where((m) => m.g1Player > m.g1Opponent).toList();
    if (wonG1.length >= 2) {
      final ledLost = wonG1.where((m) => _matchWinner(m) == "opponent").length;
      final ledRate = ledLost / wonG1.length;
      if (ledRate >= 0.3) insights.add({"icon": "😤", "title": "Closing Problem", "body": "You lose ${(ledRate * 100).round()}% of matches despite winning Game 1. Work on sustaining pressure.", "tier": "pro"});
    }

    final opponentCount = <String, int>{};
    for (final m in completed) { if (m.opponentName.isNotEmpty) opponentCount[m.opponentName] = (opponentCount[m.opponentName] ?? 0) + 1; }
    if (opponentCount.isNotEmpty) {
      final rival = opponentCount.entries.reduce((a, b) => a.value >= b.value ? a : b);
      if (rival.value >= 2) {
        final rivalWins = completed.where((m) => m.opponentName == rival.key && _matchWinner(m) == "player").length;
        insights.add({"icon": "🆚", "title": "Main Rival", "body": "You have played ${rival.key} ${rival.value} times — winning \$rivalWins of those.", "tier": "pro"});
      }
    }

    final doubles = completed.where((m) => m.partnerName.isNotEmpty).toList();
    final singles = completed.where((m) => m.partnerName.isEmpty).toList();
    if (doubles.length >= 2 && singles.length >= 2) {
      final dRate = doubles.where((m) => _matchWinner(m) == "player").length / doubles.length;
      final sRate = singles.where((m) => _matchWinner(m) == "player").length / singles.length;
      if ((dRate - sRate).abs() >= 0.2) {
        final better = dRate > sRate ? "doubles" : "singles";
        insights.add({"icon": "🏸", "title": "Format Strength", "body": "You perform significantly better in \$better. Focus your training time accordingly.", "tier": "pro"});
      }
    }

    final threeSetMatches = completed.where((m) => m.g3Player > 0 || m.g3Opponent > 0).toList();
    if (threeSetMatches.length >= 2) {
      final g3Wins = threeSetMatches.where((m) => _matchWinner(m) == "player").length;
      final g3Rate = g3Wins / threeSetMatches.length;
      if (g3Rate >= 0.6) insights.add({"icon": "💥", "title": "Decider Specialist", "body": "You win ${(g3Rate * 100).round()}% of Game 3 deciders. Mental strength is your biggest asset.", "tier": "premium"});
      else if (g3Rate < 0.4) insights.add({"icon": "💥", "title": "Game 3 Struggles", "body": "You only win ${(g3Rate * 100).round()}% of deciding games. Fitness and focus drills should be a priority.", "tier": "premium"});
    }

    final sortedByDate = List<MatchesRecord>.from(completed)..sort((a, b) => a.matchDate!.compareTo(b.matchDate!));
    if (sortedByDate.length >= 6) {
      final half = sortedByDate.length ~/ 2;
      final earlyRate = sortedByDate.take(half).where((m) => _matchWinner(m) == "player").length / half;
      final recentRate = sortedByDate.skip(half).where((m) => _matchWinner(m) == "player").length / (sortedByDate.length - half);
      if (recentRate > earlyRate + 0.1) insights.add({"icon": "📈", "title": "Improving Trend", "body": "Recent win rate ${(recentRate * 100).round()}% is up from earlier ${(earlyRate * 100).round()}%. You are getting better.", "tier": "premium"});
      else if (recentRate < earlyRate - 0.1) insights.add({"icon": "📉", "title": "Dip in Form", "body": "Recent win rate ${(recentRate * 100).round()}% is down from earlier ${(earlyRate * 100).round()}%. Review what has changed.", "tier": "premium"});
    }

    if (completed.length >= 5) {
      final last5Rate = completed.take(5).where((m) => _matchWinner(m) == "player").length / 5;
      if ((last5Rate - winRate).abs() >= 0.2) {
        final trend = last5Rate > winRate ? "above" : "below";
        insights.add({"icon": "🕐", "title": "Recent Form", "body": "Last 5 matches: ${(last5Rate * 100).round()}% win rate — \$trend your career average of ${(winRate * 100).round()}%.", "tier": "premium"});
      }
    }

    if (completed.length >= 3) {
      int totalScored = 0, totalConceded = 0, gameCount = 0;
      for (final m in completed) {
        if (m.g1Player > 0 || m.g1Opponent > 0) { totalScored += m.g1Player; totalConceded += m.g1Opponent; gameCount++; }
        if (m.g2Player > 0 || m.g2Opponent > 0) { totalScored += m.g2Player; totalConceded += m.g2Opponent; gameCount++; }
        if (m.g3Player > 0 || m.g3Opponent > 0) { totalScored += m.g3Player; totalConceded += m.g3Opponent; gameCount++; }
      }
      if (gameCount > 0) insights.add({"icon": "📊", "title": "Points Profile", "body": "Average ${(totalScored / gameCount).toStringAsFixed(1)} scored vs ${(totalConceded / gameCount).toStringAsFixed(1)} conceded per game.", "tier": "premium"});
    }

    if (completed.length >= 4) {
      final g1WonCount = completed.where((m) => m.g1Player > m.g1Opponent).length;
      final aggressiveRate = g1WonCount / completed.length;
      final style = aggressiveRate >= 0.6 ? "aggressive starter" : aggressiveRate <= 0.4 ? "slow builder" : "balanced player";
      insights.add({"icon": "🧬", "title": "Playing Style", "body": "Based on your Game 1 patterns, you play as a ${style}. Use this to prepare the right game plan.", "tier": "premium"});
      final g2Win = completed.where((m) => m.g2Player > m.g2Opponent).length;
      final g3Played = completed.where((m) => m.g3Player > 0 || m.g3Opponent > 0).toList();
      final g3Win = g3Played.where((m) => m.g3Player > m.g3Opponent).length;
      insights.add({"icon": "🎯", "title": "Game-by-Game Breakdown", "body": "G1: ${(g1WonCount / completed.length * 100).round()}% win rate. G2: ${(g2Win / completed.length * 100).round()}%. G3: ${g3Played.isNotEmpty ? (g3Win / g3Played.length * 100).round() : 'N/A'}% (${g3Played.length} played).", "tier": "premium"});
    }

    return insights;
  }

  Widget _buildInsightCard(Map<String, dynamic> insight, bool isLocked) {
    final tier = insight["tier"] as String;
    final isGettingStarted = insight["title"] == "Getting Started";
    final Color accentColor = tier == "premium" ? const Color(0xFF7B2FBE) : tier == "pro" ? const Color(0xFFD4A017) : FlutterFlowTheme.of(context).primary;
    final progress = insight["progress"] as int? ?? 0;
    final card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.2), width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(insight["icon"] as String, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(child: Text(insight["title"] as String, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: accentColor))),
          if (isLocked) Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(10)),
            child: Text(tier == "premium" ? "PREMIUM" : "PRO", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(insight["body"] as String, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5)),
        if (isGettingStarted) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress / 5,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            )),
            const SizedBox(width: 10),
            Text("$progress / 5", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: accentColor)),
          ]),
          const SizedBox(height: 4),
          Text("Your AI coach unlocks after 5 matches", style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () => context.goNamed(PremiumWidget.routeName),
            style: ElevatedButton.styleFrom(backgroundColor: accentColor, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: Text("Start building my coaching report", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          )),
        ],
        if (isLocked && !isGettingStarted) ...[
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () => context.goNamed(PremiumWidget.routeName),
            style: ElevatedButton.styleFrom(backgroundColor: accentColor, padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: Text(tier == "premium" ? "Unlock Premium" : "Unlock Pro", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          )),
        ],
      ]),
    );
    if (!isLocked) return card;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(children: [
        ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4), child: card),
        Positioned.fill(child: Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)))),
      ]),
    );
  }

  Widget _buildBlurredPreviewBanner(Map<String, String> insights, int matchCount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF1a0a2e), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("See exactly why you win and lose", style: GoogleFonts.interTight(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              matchCount >= 5
                  ? "Based on your ${matchCount} ${matchCount == 1 ? 'match' : 'matches'}"
                  : "AI-powered coaching based on your real match data",
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
            ),
          ]),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
          child: Stack(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                const Icon(Icons.lock, size: 14, color: Color(0xFFD4A017)),
                const SizedBox(width: 8),
                Expanded(child: Text(matchCount >= 5 ? insights["slowStart"]! : "Your first performance insight will appear soon", style: const TextStyle(fontSize: 13, color: Colors.white), maxLines: 1, overflow: TextOverflow.clip)),
              ]),
            ),
            Positioned(right: 0, top: 0, bottom: 0, width: 110,
              child: Container(decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Colors.transparent, Color(0xFF1a0a2e)]),
                borderRadius: BorderRadius.horizontal(right: Radius.circular(10)),
              )),
            ),
          ]),
        ),
        const SizedBox(height: 6),
        ClipRRect(borderRadius: BorderRadius.circular(10), child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4), child: Container(
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              const Icon(Icons.lock, size: 14, color: Color(0xFFD4A017)),
              const SizedBox(width: 8),
              Text(insights["tiredStat"]!, style: const TextStyle(fontSize: 13, color: Colors.white)),
            ]),
          )),
        )),
        const SizedBox(height: 6),
        ClipRRect(borderRadius: BorderRadius.circular(10), child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4), child: Container(
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              const Icon(Icons.lock, size: 14, color: Color(0xFFD4A017)),
              const SizedBox(width: 8),
              Text(insights["ledLost"]!, style: const TextStyle(fontSize: 13, color: Colors.white)),
            ]),
          )),
        )),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text("Most players never realise this about their game", style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11, fontStyle: FontStyle.italic)),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            matchCount >= 5
                ? "Your coaching report is ready"
                : "Play ${5 - matchCount} more ${(5 - matchCount) == 1 ? 'match' : 'matches'} to unlock your first coaching report",
            style: TextStyle(
              color: matchCount >= 5 ? const Color(0xFFD4A017) : Colors.white.withOpacity(0.55),
              fontSize: 13,
              fontWeight: matchCount >= 5 ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: ElevatedButton(
            onPressed: () => context.goNamed(PremiumWidget.routeName),
            style: ElevatedButton.styleFrom(
              backgroundColor: matchCount >= 5 ? const Color(0xFF7B2FBE) : const Color(0xFF3d1a6e),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              matchCount >= 5 ? "Get my coaching report" : "Unlock your coaching report",
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ]),
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
        title: Text("AI Coach", style: GoogleFonts.interTight(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        elevation: 2.0,
      ),
      body: SafeArea(
        top: true,
        child: _loadingStatus
            ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primary)))
            : StreamBuilder<List<MatchesRecord>>(
                stream: queryMatchesRecord(queryBuilder: (q) => q.where("ownerUid", isEqualTo: currentUserUid).orderBy("matchDate", descending: true)),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primary)));
                  final matches = snapshot.data!;
                  final completed = matches.where((m) => _matchWinner(m) != null).toList();
                  final insights = _generateInsights(matches);
                  final blurredInsights = _computeBlurredInsights(completed);
                  if (completed.isEmpty) {
                    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.psychology, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text("No insights yet", style: TextStyle(fontSize: 18, color: Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      Text("Complete some matches to get AI coaching insights", style: TextStyle(fontSize: 14, color: Colors.grey.shade400), textAlign: TextAlign.center),
                    ]));
                  }
                  final freeInsights = insights.where((i) => i["tier"] == "free").toList();
                  final proInsights = insights.where((i) => i["tier"] == "pro").toList();
                  final premiumInsights = insights.where((i) => i["tier"] == "premium").toList();
                  final isFree = _tier == "free";
                  final isPremium = _tier == "premium";
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [primary, primary.withOpacity(0.75)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(children: [
                          const Text("🤖", style: TextStyle(fontSize: 32)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text("Your Personal Coach", style: GoogleFonts.interTight(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text("Based on ${completed.length} ${completed.length == 1 ? 'match' : 'matches'} analysed", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                          ])),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                            child: Text(isPremium ? "✨ Premium" : _tier == "pro" ? "⭐ Pro" : "Starter", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 20),
                      if (isFree) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: primary.withOpacity(0.2)),
                          ),
                          child: Row(children: [
                            Icon(Icons.info_outline, color: primary, size: 16),
                            const SizedBox(width: 10),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                                  children: [
                                    const TextSpan(text: 'You have access to '),
                                    TextSpan(text: '5 free insights', style: TextStyle(fontWeight: FontWeight.w700, color: primary)),
                                    const TextSpan(text: '. Upgrade to Pro to unlock 13 personalised insights.'),
                                  ],
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ],
                      ...freeInsights.map((i) => _buildInsightCard(i, false)),
                      if (proInsights.isNotEmpty) ...[const SizedBox(height: 4), ...proInsights.map((i) => _buildInsightCard(i, isFree))],
                      if (premiumInsights.isNotEmpty) ...[const SizedBox(height: 4), ...premiumInsights.map((i) => _buildInsightCard(i, !isPremium))],
                      if (isFree) ...[const SizedBox(height: 8), _buildBlurredPreviewBanner(blurredInsights, completed.length)],
                      const SizedBox(height: 32),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
