import 'dart:ui';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/services/premium_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
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
      // Check RevenueCat first for live entitlement status
      final customerInfo = await Purchases.getCustomerInfo();
      final entitlements = customerInfo.entitlements.active;
      if (mounted) {
        setState(() {
          if (entitlements.containsKey('premium')) {
            _tier = 'premium';
          } else if (entitlements.containsKey('pro')) {
            _tier = 'pro';
          } else {
            _tier = 'free';
          }
          _loadingStatus = false;
        });
      }
    } catch (_) {
      // Fallback to Firestore
      try {
        final status = await _premiumService.getSubscriptionStatus().timeout(
          const Duration(seconds: 5),
          onTimeout: () => {'status': 'free'},
        );
        if (mounted) {
          setState(() {
            final rawStatus = status['status'] as String;
            _tier = (rawStatus == 'inactive' || rawStatus == 'locked' || rawStatus == 'expired') ? 'free' : rawStatus;
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
  }

  String? _matchWinner(MatchesRecord match) {
    final target = match.scoringFormat == '15' ? 15 : 21;
    final cap = target == 15 ? 17 : 30;
    int playerGames = 0;
    int opponentGames = 0;
    final g2Played = match.g2Player > 0 || match.g2Opponent > 0;
    final g3Played = match.g3Player > 0 || match.g3Opponent > 0;
    if (!g2Played && !g3Played) {
      if (match.g1Player > match.g1Opponent) return "player";
      if (match.g1Opponent > match.g1Player) return "opponent";
      return null;
    }
    for (final pair in [
      [match.g1Player, match.g1Opponent],
      if (g2Played) [match.g2Player, match.g2Opponent],
      if (g3Played) [match.g3Player, match.g3Opponent],
    ]) {
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

  // Returns the best result across all disciplines for a tournament
  String _bestDisciplineResult(TournamentsRecord t) {
    final resultRanking = {
      'Gold': 1, 'Silver': 2, 'Bronze': 3, '4th Place': 4,
      'Semi Final': 5, 'Quarter Final': 6, 'Round of 16': 7,
      'Round of 32': 8, 'Group Stage': 9, 'Did Not Place': 10, 'Withdrew': 11
    };
    final raw = t.snapshotData['disciplines'];
    if (raw is Map) {
      final results = [
        (raw['singles'] ?? '').toString(),
        (raw['doubles'] ?? '').toString(),
        (raw['mixedDoubles'] ?? '').toString(),
      ].where((r) => r.isNotEmpty && r != 'Withdrew').toList();
      if (results.isEmpty) return t.result;
      return results.reduce((a, b) => (resultRanking[a] ?? 99) <= (resultRanking[b] ?? 99) ? a : b);
    }
    return t.result;
  }

  // Returns all discipline results for a tournament as a readable string
  String _disciplineSummary(TournamentsRecord t) {
    final raw = t.snapshotData['disciplines'];
    if (raw is Map) {
      final parts = <String>[];
      if ((raw['singles'] ?? '').toString().isNotEmpty) parts.add('Singles: ${raw['singles']}');
      if ((raw['doubles'] ?? '').toString().isNotEmpty) parts.add('Doubles: ${raw['doubles']}');
      if ((raw['mixedDoubles'] ?? '').toString().isNotEmpty) parts.add('Mixed Doubles: ${raw['mixedDoubles']}');
      if (parts.isNotEmpty) return parts.join('. ');
    }
    return t.result;
  }

  List<Map<String, dynamic>> _generateInsights(List<MatchesRecord> matches, {List<TournamentsRecord> tournaments = const []}) {
    final completed = matches.where((m) => _matchWinner(m) != null).toList();
    if (completed.isEmpty) return [];
    final insights = <Map<String, dynamic>>[];
    final wins = completed.where((m) => _matchWinner(m) == "player").length;
    final winRate = wins / completed.length;

    // ── Win Rate (free) ──
    if (completed.length < 5) {
      final remaining = 5 - completed.length;
      final remainingLabel = remaining == 1 ? "1 more match" : "$remaining more matches";
      insights.add({"icon": "🏸", "title": "Getting Started", "body": "We are learning your game. Play $remainingLabel to unlock your first coaching report.", "progress": completed.length, "tier": "free"});
    } else if (winRate >= 0.7) {
      insights.add({"icon": "🔥", "title": "Strong Results", "body": "You are winning ${(winRate * 100).round()}% of your ${completed.length} matches. That's a strong return so far — keep logging matches to build an even clearer picture of your game.", "tier": "free"});
    } else if (winRate >= 0.5) {
      insights.add({"icon": "📈", "title": "Positive Results", "body": "You are winning ${(winRate * 100).round()}% of your ${completed.length} matches — more wins than losses. A solid foundation, and there's more to learn as you keep playing and tracking.", "tier": "free"});
    } else if (winRate >= 0.3) {
      insights.add({"icon": "💪", "title": "Developing Results", "body": "You are winning ${(winRate * 100).round()}% of your ${completed.length} matches. You're building experience and results with every match you log.", "tier": "free"});
    } else {
      insights.add({"icon": "🌱", "title": "Building Results", "body": "You are winning ${(winRate * 100).round()}% of your ${completed.length} matches. Every match you log adds to the picture — keep playing and tracking to unlock more insights.", "tier": "free"});
    }

    final moodStats = <String, Map<String, int>>{};
    for (final m in completed) {
      if (m.mood.isEmpty) continue;
      moodStats[m.mood] ??= {"wins": 0, "total": 0};
      moodStats[m.mood]!["total"] = moodStats[m.mood]!["total"]! + 1;
      if (_matchWinner(m) == "player") moodStats[m.mood]!["wins"] = moodStats[m.mood]!["wins"]! + 1;
    }
    // ── Mood & Performance (free) ──
    if (moodStats.isNotEmpty) {
      String? bestMood; double bestRate = 0; int bestTotal = 0; String? worstMoodFree; double worstRateFree = 1;
      moodStats.forEach((mood, stats) {
        if (stats["total"]! >= 5) {
          final rate = stats["wins"]! / stats["total"]!;
          if (rate > bestRate) { bestRate = rate; bestMood = mood; bestTotal = stats["total"]!; }
          if (rate < worstRateFree) { worstRateFree = rate; worstMoodFree = mood; }
        }
      });
      if (bestMood != null) {
        final pct = (bestRate * 100).round();
        final moodBody = "Your strongest results have come in matches where you recorded feeling $bestMood, winning $pct% of your $bestTotal matches recorded in that mood. Think about what else was consistent before those matches, such as your preparation, warm-up or match routine. The goal isn't to recreate a feeling, but to build routines that help you perform at your best.";
        insights.add({"icon": "🧠", "title": "Mood & Performance", "body": moodBody, "tier": "free"});
        if (worstMoodFree != null && worstMoodFree != bestMood && worstRateFree < winRate) {
          insights.add({"icon": "⚡", "title": "Mood to Watch", "body": "Your results have been less successful in matches where you recorded feeling $worstMoodFree. This is worth reflecting on—not because the mood caused the result, but because it may highlight something in your preparation, routines or mindset that you can strengthen.", "tier": "free"});
        }
      } else {
        insights.add({"icon": "🧠", "title": "Mood & Performance", "body": "We need at least 5 matches recorded in the same mood before we can identify a meaningful pattern. Keep logging your pre-match mood to unlock this insight.", "tier": "free"});
      }
    }

    // ── Recent Results (free) ──
    {
      // recalculate streaks from most recent (completed is ordered descending)
      int wStreak = 0;
      int lStreak = 0;
      for (final m in completed) {
        if (wStreak == 0 && lStreak == 0) {
          if (_matchWinner(m) == "player") wStreak++;
          else lStreak++;
        } else if (wStreak > 0) {
          if (_matchWinner(m) == "player") wStreak++;
          else break;
        } else {
          if (_matchWinner(m) == "opponent") lStreak++;
          else break;
        }
      }
      if (wStreak >= 5) {
        insights.add({"icon": "🔥", "title": "Winning Run", "body": "You have won $wStreak matches in a row. Take confidence from those results, while continuing to focus on the preparation and routines that support your performance. Approach the next match one rally at a time.", "tier": "free"});
      } else if (wStreak >= 3) {
        insights.add({"icon": "🔥", "title": "Winning Run", "body": "You have won $wStreak matches in a row. Your recent results have been positive. Keep focusing on the habits and decisions that have supported those performances.", "tier": "free"});
      } else if (wStreak == 2) {
        insights.add({"icon": "📈", "title": "Back-to-Back Wins", "body": "You have won your last two matches. Take the positives from both performances and focus on what you want to repeat in your next match.", "tier": "free"});
      } else if (lStreak >= 3) {
        insights.add({"icon": "🔄", "title": "Reset Mode", "body": "Your last $lStreak results have not gone your way. This run does not define your ability. Focus on one controllable area you can improve and approach the next match as a fresh opportunity.", "tier": "free"});
      } else if (lStreak == 2) {
        insights.add({"icon": "🔄", "title": "Reset and Refocus", "body": "Your last two results have not gone your way. Look for one useful lesson, reset, and choose one clear focus for your next match.", "tier": "free"});
      } else if (lStreak == 1) {
        insights.add({"icon": "🔄", "title": "Next Match Focus", "body": "Your last match did not go your way. Take the lesson from it, then shift your attention to what you can control in your next performance.", "tier": "free"});
      } else if (wStreak == 1) {
        insights.add({"icon": "✅", "title": "Recent Win", "body": "You won your last match. Reflect on what worked well and choose one positive behaviour to carry into your next performance.", "tier": "free"});
      }
    }

    // ── Performance Across Moods (pro) ──
    if (moodStats.isNotEmpty) {
      final qualifyingMoods = moodStats.entries.where((e) => e.value["total"]! >= 5).toList();
      if (qualifyingMoods.length >= 2) {
        final rates = qualifyingMoods.map((e) => e.value["wins"]! / e.value["total"]!).toList();
        final maxRate = rates.reduce((a, b) => a > b ? a : b);
        final minRate = rates.reduce((a, b) => a < b ? a : b);
        final spread = maxRate - minRate;
        final spreadPct = (spread * 100).round();
        // Placeholder threshold — revisit once we have enough real user data to calibrate a meaningful spread.
        const stabilityThreshold = 0.15;
        String moodConsistencyBody;
        if (spread <= stabilityThreshold) {
          moodConsistencyBody = "Your recent results have been similar across different pre-match moods (a $spreadPct% spread between your strongest and weakest recorded moods, based on ${qualifyingMoods.length} moods with enough matches to compare). This suggests your performances may be becoming less dependent on how you feel before competing.";
        } else {
          moodConsistencyBody = "Your current results vary across different pre-match moods (a $spreadPct% spread between your strongest and weakest recorded moods, based on ${qualifyingMoods.length} moods with enough matches to compare). As you log more matches, we'll help you identify the preparation habits that support your most consistent performances.";
        }
        insights.add({"icon": "🧭", "title": "Performance Across Moods", "body": moodConsistencyBody, "tier": "pro"});
      }
    }

    final tMatches = completed.where((m) => m.matchType == "Tournament").toList();
    final pMatches = completed.where((m) => m.matchType == "Practice").toList();
    // ── Match Frequency (free) ──
    if (completed.length >= 2) {
      final now = DateTime.now();
      final last30 = completed.where((m) => m.matchDate != null && now.difference(m.matchDate!).inDays <= 30).length;
      final prev15 = completed.where((m) => m.matchDate != null && now.difference(m.matchDate!).inDays > 15 && now.difference(m.matchDate!).inDays <= 30).length;
      final recent15 = completed.where((m) => m.matchDate != null && now.difference(m.matchDate!).inDays <= 15).length;
      String freqBody;
      if (last30 >= 6) {
        freqBody = "You have played $last30 matches in the last 30 days. You have been competing regularly and building a useful record of your recent performances.";
      } else if (last30 >= 4) {
        freqBody = "You have played $last30 matches in the last 30 days. Good consistency. Regular play like this helps you build and maintain your level.";
      } else if (last30 >= 2) {
        freqBody = "You have played $last30 matches in the last 30 days. A steady start. Try to increase your frequency to keep your game sharp.";
      } else if (last30 == 1) {
        freqBody = "You have played 1 match in the last 30 days. Playing more regularly will help you improve faster. Even one extra match per week can make a difference.";
      } else {
        freqBody = "No matches recorded in the last 30 days. Getting back on court is the most important step to improving your game.";
      }
      String trendAdd = "";
      if (recent15 > prev15 && prev15 > 0) trendAdd = " You have played more matches in the most recent 15 days than in the previous 15.";
      else if (prev15 > recent15) trendAdd = " You have played fewer matches in the most recent 15 days than in the previous 15.";
      insights.add({
        "icon": "📅",
        "title": "Match Frequency",
        "body": freqBody + trendAdd,
        "tier": "free"
      });
    }

    // ── Match Balance (free) ──
    if (completed.length >= 3) {
      final tCount = completed.where((m) => m.matchType == "Tournament").length;
      final pCount = completed.where((m) => m.matchType == "Practice").length;
      final tPct = ((tCount / completed.length) * 100).round();
      final pPct = ((pCount / completed.length) * 100).round();
      String balanceBody;
      if (completed.length < 5) {
        balanceBody = "You have not logged many matches yet. Keep tracking to build a clearer picture of where most of your matches are taking place.";
      } else if (tCount == completed.length) {
        balanceBody = "All of your recorded matches have been tournament matches. Logging practice matches as well, where relevant, would give you a broader view of your performances across different settings.";
      } else if (pCount == completed.length) {
        balanceBody = "All of your recorded matches have been practice matches. Tournament results, when available, would help you compare how your game translates into competition.";
      } else if (tPct >= 70) {
        balanceBody = "$tPct% of your recorded matches have been tournaments. Your current match history is weighted towards competitive play.";
      } else if (pPct >= 70) {
        balanceBody = "$pPct% of your recorded matches have been practice matches. Your current match history is weighted towards practice play.";
      } else {
        balanceBody = "Your recorded matches include both practice and tournament play: $pPct% practice and $tPct% tournament. This gives you performance data from both settings.";
      }
      insights.add({
        "icon": "⚖️",
        "title": "Match Balance",
        "body": balanceBody,
        "tier": "free"
      });
    }

    // ── Close Game Performance (pro) ──
    {
      int closeGamesTotal = 0;
      int closeGamesWon = 0;
      int totalGamesPlayed = 0;
      for (final m in completed) {
        final games = [
          [m.g1Player, m.g1Opponent],
          [m.g2Player, m.g2Opponent],
          [m.g3Player, m.g3Opponent],
        ];
        for (final g in games) {
          final p = g[0]; final o = g[1];
          if (p == 0 && o == 0) continue;
          totalGamesPlayed++;
          final diff = (p - o).abs();
          if (diff <= 3) {
            closeGamesTotal++;
            if (p > o) closeGamesWon++;
          }
        }
      }
      if (closeGamesTotal >= 5) {
        final closeRate = closeGamesWon / closeGamesTotal;
        final closePct = (closeRate * 100).round();
        final addOn = totalGamesPlayed > 0 && (closeGamesTotal / totalGamesPlayed) >= 0.4
            ? " These games make up a meaningful share of your results, so they are worth reviewing when preparing for tight matches."
            : "";
        final closeBody = "You have won $closePct% of your close games (games decided by 3 points or fewer), based on $closeGamesTotal such games." + addOn;
        insights.add({"icon": "⚔️", "title": "Close Game Performance", "body": closeBody, "tier": "pro"});
      }
    }

    // ── Match-to-Match Consistency (pro) ──
    if (completed.length >= 8) {
      final sample = completed.take(10).toList();
      int switches = 0;
      for (int i = 0; i < sample.length - 1; i++) {
        final curr = _matchWinner(sample[i]) == "player";
        final next = _matchWinner(sample[i + 1]) == "player";
        if (curr != next) switches++;
      }
      final ratio = switches / (sample.length - 1);
      final timeWord = switches == 1 ? "time" : "times";
      String consBody = "Across your last ${sample.length} matches, your results switched between a win and a loss $switches $timeWord.";
      if (ratio > 0.55) {
        consBody += " Results can vary for many reasons, including opponent level, match setting and preparation. Every match you log adds another piece to the picture, helping you understand your game with greater confidence.";
      }
      // Add-on: compare recent 5 vs earlier 5 consistency
      String consAddOn = "";
      if (completed.length >= 10) {
        final recent5 = completed.take(5).toList();
        final earlier5 = completed.skip(5).take(5).toList();
        int recentSwitches = 0;
        int earlierSwitches = 0;
        for (int i = 0; i < 4; i++) {
          if (_matchWinner(recent5[i]) != _matchWinner(recent5[i+1])) recentSwitches++;
          if (_matchWinner(earlier5[i]) != _matchWinner(earlier5[i+1])) earlierSwitches++;
        }
        if (recentSwitches < earlierSwitches) consAddOn = " Your most recent matches have shown fewer swings than your earlier ones.";
      }
      insights.add({"icon": "📊", "title": "Match-to-Match Consistency", "body": consBody + consAddOn, "tier": "pro"});
    }

    // ── Tournament vs Practice Results (pro) ──
    if (tMatches.length >= 5 && pMatches.length >= 5) {
      final tRate = tMatches.where((m) => _matchWinner(m) == "player").length / tMatches.length;
      final pRate = pMatches.where((m) => _matchWinner(m) == "player").length / pMatches.length;
      final tPct = (tRate * 100).round();
      final pPct = (pRate * 100).round();
      final diff = (tRate - pRate).abs();
      String tournBody = "You have won $tPct% of your tournament matches and $pPct% of your practice matches.";
      if (diff >= 0.2) {
        tournBody += " That's an interesting pattern. As you log more matches, you'll start to see whether it becomes a consistent part of your game.";
      }
      insights.add({"icon": "🏆", "title": "Tournament vs Practice Results", "body": tournBody, "tier": "pro"});
    }

    // ── Results After Losing Game 1 (pro) ──
    final lostG1 = completed.where((m) => m.g1Player < m.g1Opponent).toList();
    if (lostG1.length >= 5) {
      final comebacks = lostG1.where((m) => _matchWinner(m) == "player").length;
      final rate = comebacks / lostG1.length;
      final pct = (rate * 100).round();
      String comebackBody = "After losing Game 1, you have won $pct% of those matches ($comebacks of ${lostG1.length}).";
      if (rate < 0.3) {
        comebackBody += " Consider what helps you reset quickly and come out strong in Game 2.";
      }
      insights.add({"icon": "🔄", "title": "Results After Losing Game 1", "body": comebackBody, "tier": "pro"});
    }

    // ── Results After Winning Game 1 (pro) ──
    final wonG1 = completed.where((m) => m.g1Player > m.g1Opponent).toList();
    if (wonG1.length >= 5) {
      final wonAfterG1 = wonG1.where((m) => _matchWinner(m) == "player").length;
      final closedRate = wonAfterG1 / wonG1.length;
      final closedPct = (closedRate * 100).round();
      String closeBody = "After winning Game 1, you have gone on to win $closedPct% of those matches ($wonAfterG1 of ${wonG1.length}).";
      if (closedRate < 0.7) {
        closeBody += " Consider what helps you stay locked in and keep your game plan once you're ahead.";
      }
      insights.add({"icon": "😤", "title": "Results After Winning Game 1", "body": closeBody, "tier": "pro"});
    }

    // ── Head-to-Head Record (pro) ──
    final opponentCount = <String, int>{};
    for (final m in completed) { if (m.opponentName.isNotEmpty) opponentCount[m.opponentName] = (opponentCount[m.opponentName] ?? 0) + 1; }
    if (opponentCount.isNotEmpty) {
      final rival = opponentCount.entries.reduce((a, b) => a.value >= b.value ? a : b);
      if (rival.value >= 3) {
        final rivalWins = completed.where((m) => m.opponentName == rival.key && _matchWinner(m) == "player").length;
        final rivalRate = rivalWins / rival.value;
        final rivalPct = (rivalRate * 100).round();
        final rivalBody = "You have played ${rival.key} ${rival.value} times and won $rivalPct% of those matches.";
        insights.add({"icon": "🆚", "title": "Head-to-Head Record", "body": rivalBody, "tier": "pro"});
      }
    }

    // ── Singles vs Doubles Results (pro) ──
    final doubles = completed.where((m) => m.partnerName.isNotEmpty).toList();
    final singles = completed.where((m) => m.partnerName.isEmpty).toList();
    if (doubles.length >= 5 && singles.length >= 5) {
      final dRate = doubles.where((m) => _matchWinner(m) == "player").length / doubles.length;
      final sRate = singles.where((m) => _matchWinner(m) == "player").length / singles.length;
      final sPct = (sRate * 100).round();
      final dPct = (dRate * 100).round();
      final fDiff = (sRate - dRate).abs();
      String formatBody = "You have won $sPct% of your singles matches and $dPct% of your doubles matches.";
      if (fDiff >= 0.2) {
        formatBody += " That's an interesting difference between the two formats. Keep tracking both to see whether the pattern continues.";
      }
      insights.add({"icon": "🏸", "title": "Singles vs Doubles Results", "body": formatBody, "tier": "pro"});
    }

    // ── Results by Opponent Handedness (pro) ──
    {
      final rightMatches = completed.where((m) => m.opponentHandedness == "Right").toList();
      final leftMatches = completed.where((m) => m.opponentHandedness == "Left").toList();
      if (rightMatches.length >= 5 && leftMatches.length >= 5) {
        final rightWins = rightMatches.where((m) => _matchWinner(m) == "player").length;
        final leftWins = leftMatches.where((m) => _matchWinner(m) == "player").length;
        final rightRate = rightWins / rightMatches.length;
        final leftRate = leftWins / leftMatches.length;
        final rightPct = (rightRate * 100).round();
        final leftPct = (leftRate * 100).round();
        final diff = (rightRate - leftRate).abs();
        String handBody = "You have won $rightPct% of matches against right-handed opponents and $leftPct% against left-handed opponents.";
        if (diff >= 0.2) {
          handBody += " That's an interesting difference between the two groups. Keep tracking opponent handedness to see whether the pattern continues.";
        }
        insights.add({"icon": "🏸", "title": "Results by Opponent Handedness", "body": handBody, "tier": "pro"});
      } else if (leftMatches.length >= 5 && rightMatches.length < 5) {
        final leftWins = leftMatches.where((m) => _matchWinner(m) == "player").length;
        final leftRate = leftWins / leftMatches.length;
        final leftPct = (leftRate * 100).round();
        insights.add({"icon": "🤚", "title": "Left-Handed Opponent Record", "body": "You have played ${leftMatches.length} matches against left-handed opponents, winning $leftPct% of them. Keep logging opponent handedness to build a fuller comparison.", "tier": "pro"});
      } else if (rightMatches.length >= 5 && leftMatches.length < 5) {
        insights.add({"icon": "🏸", "title": "Handedness Data Building", "body": "You need more matches against left-handed opponents before we can compare results by handedness. Keep logging opponent handedness when adding matches.", "tier": "pro"});
      }
    }

    // ── Winning Margins (premium) ──
    {
      int gamesWon = 0;
      int totalWinMargin = 0;
      for (final m in completed) {
        final games = [
          [m.g1Player, m.g1Opponent],
          [m.g2Player, m.g2Opponent],
          [m.g3Player, m.g3Opponent],
        ];
        for (final g in games) {
          final p = g[0]; final o = g[1];
          if (p == 0 && o == 0) continue;
          if (p > o) { gamesWon++; totalWinMargin += (p - o); }
        }
      }
      if (gamesWon >= 5) {
        final avgWinMargin = totalWinMargin / gamesWon;
        final marginStr = avgWinMargin.toStringAsFixed(1);
        final domBody = "When you win games, you do so by an average of $marginStr points.";
        insights.add({"icon": "💪", "title": "Winning Margins", "body": domBody, "tier": "premium"});
      }
    }

    

    // ── Results in Deciding Games (premium) ──
    final threeSetMatches = completed.where((m) => m.g3Player > 0 || m.g3Opponent > 0).toList();
    if (threeSetMatches.length >= 5) {
      final g3Wins = threeSetMatches.where((m) => _matchWinner(m) == "player").length;
      final g3Rate = g3Wins / threeSetMatches.length;
      final g3Pct = (g3Rate * 100).round();
      final g3Body = "When your matches have gone to a deciding game, you have won $g3Pct% of them, based on ${threeSetMatches.length} such matches. Deciding games are where matches are won and lost — worth keeping an eye on as you log more of them.";
      insights.add({"icon": "💥", "title": "Results in Deciding Games", "body": g3Body, "tier": "premium"});
    }

    // ── Recent vs Earlier Form (premium) ──
    final sortedByDate = List<MatchesRecord>.from(completed)..sort((a, b) => a.matchDate!.compareTo(b.matchDate!));
    if (sortedByDate.length >= 10) {
      final recentMatches = sortedByDate.reversed.take(5).toList();
      final earlierMatches = sortedByDate.reversed.skip(5).take(5).toList();
      final recentRate = recentMatches.where((m) => _matchWinner(m) == "player").length / recentMatches.length;
      final earlyRate = earlierMatches.where((m) => _matchWinner(m) == "player").length / earlierMatches.length;
      final trendDiff = recentRate - earlyRate;
      final recentPct = (recentRate * 100).round();
      final earlyPct = (earlyRate * 100).round();
      String trendBody = "Your win rate over your last 5 matches is $recentPct%, compared with $earlyPct% in the 5 matches before that.";
      if (trendDiff >= 0.2) {
        trendBody += " That's a noticeable positive shift in your recent results. Keep tracking to see if the trend continues.";
      } else if (trendDiff <= -0.2) {
        trendBody += " That's a noticeable change in your recent results. Your next few matches will help show whether it's a short-term dip or a developing trend.";
      }
      insights.add({"icon": "📊", "title": "Recent vs Earlier Form", "body": trendBody, "tier": "premium"});
    }

    

    // ── Points Scored vs Conceded (premium) ──
    if (completed.length >= 3) {
      int totalScored = 0, totalConceded = 0, gameCount = 0;
      for (final m in completed) {
        if (m.g1Player > 0 || m.g1Opponent > 0) { totalScored += m.g1Player; totalConceded += m.g1Opponent; gameCount++; }
        if (m.g2Player > 0 || m.g2Opponent > 0) { totalScored += m.g2Player; totalConceded += m.g2Opponent; gameCount++; }
        if (m.g3Player > 0 || m.g3Opponent > 0) { totalScored += m.g3Player; totalConceded += m.g3Opponent; gameCount++; }
      }
      if (gameCount >= 5) {
        final avgScored = totalScored / gameCount;
        final avgConceded = totalConceded / gameCount;
        final scoredStr = avgScored.toStringAsFixed(1);
        final concededStr = avgConceded.toStringAsFixed(1);
        final ptBody = "You average $scoredStr points scored and $concededStr points conceded per game.";
        insights.add({"icon": "📊", "title": "Points Scored vs Conceded", "body": ptBody, "tier": "premium"});
      }
    }

    // ── First Game Results (premium) ──
    if (completed.length >= 8) {
      final g1WonCount = completed.where((m) => m.g1Player > m.g1Opponent).length;
      final g1StyleRate = g1WonCount / completed.length;
      final g1StylePct = (g1StyleRate * 100).round();
      final styleBody = "You have won $g1StylePct% of your first games across ${completed.length} matches. Worth keeping an eye on as more matches build a fuller picture of how you play.";
      insights.add({"icon": "🧬", "title": "First Game Results", "body": styleBody, "tier": "premium"});
    }

    // ── Game-by-Game Breakdown (premium) ──
    if (completed.length >= 5) {
      final g1Won = completed.where((m) => m.g1Player > m.g1Opponent).length;
      final g2Won = completed.where((m) => m.g2Player > m.g2Opponent).length;
      final g3PlayedList = completed.where((m) => m.g3Player > 0 || m.g3Opponent > 0).toList();
      final g3WonCount = g3PlayedList.where((m) => m.g3Player > m.g3Opponent).length;
      final g1Pct = (g1Won / completed.length * 100).round();
      final g2Pct = (g2Won / completed.length * 100).round();
      final g3Pct = g3PlayedList.isNotEmpty ? (g3WonCount / g3PlayedList.length * 100).round() : null;
      final g3Str = g3Pct != null ? "$g3Pct%" : "N/A";
      String primaryLine = "Across your matches, you win $g1Pct% of first games, $g2Pct% of second games, and $g3Str of third games (${g3PlayedList.length} played).";
      // Identify weakest and strongest. Prioritise weakest
      String contextLine = "";
      final rates = {"G1": g1Pct, "G2": g2Pct};
      if (g3PlayedList.length >= 3 && g3Pct != null) rates["G3"] = g3Pct;
      final weakest = rates.entries.reduce((a, b) => a.value <= b.value ? a : b).key;
      final strongest = rates.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
      if (weakest == "G1") contextLine = "Your opening game is your weakest area. Improving your start could have a big impact.";
      else if (weakest == "G3") contextLine = "Deciding games are proving the most challenging. Focusing on fitness and concentration in the final game could help.";
      else if (strongest == "G1") contextLine = "You start strongly. Maintaining that level across the match could improve your results.";
      else if (strongest == "G2") contextLine = "You tend to grow into matches. Your second game is your strongest.";
      else if (strongest == "G3") contextLine = "You finish strongly when matches go the distance. A good sign of resilience under pressure.";
      insights.add({"icon": "🎯", "title": "Game-by-Game Breakdown", "body": "$primaryLine $contextLine".trim(), "tier": "premium"});
    }


    // ── Tournament Result Insights (pro) ──
    final resultRanking = {
      'Gold': 1, 'Silver': 2, 'Bronze': 3, '4th Place': 4,
      'Semi Final': 5, 'Quarter Final': 6, 'Round of 16': 7,
      'Round of 32': 8, 'Group Stage': 9, 'Did Not Place': 10, 'Withdrew': 11
    };

    final tournamentsWithResults = tournaments.where((t) => _bestDisciplineResult(t).isNotEmpty && _bestDisciplineResult(t) != 'Withdrew').toList();
    tournamentsWithResults.sort((a, b) => (a.date ?? DateTime(0)).compareTo(b.date ?? DateTime(0)));

    if (tournamentsWithResults.isNotEmpty) {
      // Best Result
      final bestT = tournamentsWithResults.reduce((a, b) =>
        (resultRanking[_bestDisciplineResult(a)] ?? 99) <= (resultRanking[_bestDisciplineResult(b)] ?? 99) ? a : b);
      final bestResult = _bestDisciplineResult(bestT);
      final bestCount = tournamentsWithResults.where((t) => _bestDisciplineResult(t) == bestResult).length;
      final bestCountStr = bestCount > 1 ? 'which you have reached $bestCount times' : 'your best performance so far';

      String bestBody;
      if (bestResult == 'Gold') {
        bestBody = "You have won Gold in a tournament. That is a significant achievement. The challenge now is to maintain that level and defend your title at the next opportunity.";
      } else if (bestResult == 'Silver') {
        bestBody = "Your best result is a Silver medal, $bestCountStr. You have reached a Final and performed at the highest level. One more step to Gold.";
      } else if (bestResult == 'Bronze') {
        bestBody = "Your best result is a Bronze medal, $bestCountStr. You are competing at the top end of tournaments. Keep pushing for that Final spot.";
      } else {
        bestBody = "Your best tournament result is a $bestResult, $bestCountStr. You are getting closer to a breakthrough and one more strong run could take you further.";
      }
      insights.add({"icon": "🏆", "title": "Best Result", "body": bestBody, "tier": "pro"});

      // Champion's Challenge
      final goldResults = tournamentsWithResults.where((t) => _bestDisciplineResult(t) == 'Gold').toList();
      if (goldResults.isNotEmpty) {
        final goldName = goldResults.last.name;
        insights.add({"icon": "🥇", "title": "Champion's Challenge", "body": "You won Gold at $goldName. The challenge now is repeating that performance under different opponents and conditions. Use it as the benchmark you are chasing in every tournament ahead.", "tier": "pro"});
      }

      // Finals Record
      final finals = tournamentsWithResults.where((t) => _bestDisciplineResult(t) == 'Gold' || _bestDisciplineResult(t) == 'Silver').toList();
      if (finals.length >= 2) {
        final wins = finals.where((t) => _bestDisciplineResult(t) == 'Gold').length;
        insights.add({"icon": "🏅", "title": "Finals Record", "body": "You have reached ${finals.length} Finals and won $wins of them. You perform well when competing for titles.", "tier": "pro"});
      }

      // Medal Hunter
      final medals = tournamentsWithResults.where((t) => ['Gold', 'Silver', 'Bronze'].contains(_bestDisciplineResult(t))).toList();
      final last6 = tournamentsWithResults.length >= 6 ? tournamentsWithResults.sublist(tournamentsWithResults.length - 6) : tournamentsWithResults;
      final medalsInLast6 = last6.where((t) => ['Gold', 'Silver', 'Bronze'].contains(_bestDisciplineResult(t))).length;
      if (medals.length >= 3 || medalsInLast6 >= 2) {
        insights.add({"icon": "🎯", "title": "Medal Hunter", "body": "You have earned medals in ${medals.length} of your last ${tournamentsWithResults.length} tournaments. You are regularly putting yourself in contention for the top positions.", "tier": "pro"});
      }

      if (tournamentsWithResults.length >= 3) {
        // Tournament Progression
        final last3 = tournamentsWithResults.sublist(tournamentsWithResults.length - 3);
        final r1 = _bestDisciplineResult(last3[0]); final r2 = _bestDisciplineResult(last3[1]); final r3 = _bestDisciplineResult(last3[2]);
        final rank1 = resultRanking[r1] ?? 99;
        final rank2 = resultRanking[r2] ?? 99;
        final rank3 = resultRanking[r3] ?? 99;
        if (rank3 < rank2 && rank2 < rank1) {
          insights.add({"icon": "📈", "title": "Tournament Progression", "body": "Your tournament performances are trending in the right direction. Across your last three tournaments, you progressed from the $r1 to the $r2 and then the $r3.", "tier": "pro"});
        }

        // Tournament Consistency
        final resultCounts = <String, int>{};
        for (final t in tournamentsWithResults) { final r = _bestDisciplineResult(t); resultCounts[r] = (resultCounts[r] ?? 0) + 1; }
        final mostCommon = resultCounts.entries.reduce((a, b) => a.value >= b.value ? a : b);
        final summaryParts = resultCounts.entries.toList()
          ..sort((a, b) => (resultRanking[a.key] ?? 99).compareTo(resultRanking[b.key] ?? 99));
        final summaryStr = summaryParts.map((e) => 'the ${e.key} ${e.value} time${e.value > 1 ? "s" : ""}').join(', ');
        insights.add({"icon": "📊", "title": "Tournament Consistency", "body": "Across ${tournamentsWithResults.length} tournaments, you have reached $summaryStr. The ${mostCommon.key} is currently your most common finishing stage.", "tier": "pro"});

        // Next Level Gap
        final mostCommonRank = resultRanking[mostCommon.key] ?? 99;
        final nextLevel = resultRanking.entries.where((e) => e.value == mostCommonRank - 1).map((e) => e.key).firstOrNull;
        if (nextLevel != null && mostCommonRank > 1) {
          insights.add({"icon": "🎯", "title": "Next Level Gap", "body": "You are regularly reaching the ${mostCommon.key}. Winning just one more match in each tournament would move you into the $nextLevel. Focus on the moments that decide tight matches.", "tier": "pro"});
        }

        // Tournament Form
        final last3Results = tournamentsWithResults.sublist(tournamentsWithResults.length - 3);
        final allStrongForm = last3Results.every((t) => (resultRanking[_bestDisciplineResult(t)] ?? 99) <= 5);
        if (allStrongForm) {
          insights.add({"icon": "🔥", "title": "Tournament Form", "body": "You have reached the Semi Final or better in your last 3 consecutive tournaments. Your tournament form is currently strong.", "tier": "pro"});
        }

        // Bounce Back
        for (int i = 1; i < tournamentsWithResults.length; i++) {
          final prev = resultRanking[_bestDisciplineResult(tournamentsWithResults[i-1])] ?? 99;
          final curr = resultRanking[_bestDisciplineResult(tournamentsWithResults[i])] ?? 99;
          if (prev > 7 && curr <= 6) {
            insights.add({"icon": "💪", "title": "Bounce Back Ability", "body": "After an early exit, you responded by reaching the ${_bestDisciplineResult(tournamentsWithResults[i])} or better in your next tournament. Strong players learn, adapt, and come back stronger.", "tier": "pro"});
            break;
          }
        }
      }

      // Breaking Through
      if (tournamentsWithResults.length >= 4) {
        final last4 = tournamentsWithResults.sublist(tournamentsWithResults.length - 4);
        final stuckAtQF = last4.every((t) => _bestDisciplineResult(t) == 'Quarter Final');
        if (stuckAtQF) {
          insights.add({"icon": "🚀", "title": "Breaking Through", "body": "You have exited at the Quarter Final stage in your last 4 tournaments. The Semi Final is the next milestone to target in your progression. Focus on what changes in those deciding matches.", "tier": "pro"});
        }
      }

      // Consistent Contender
      if (tournamentsWithResults.length >= 7) {
        final last7 = tournamentsWithResults.sublist(tournamentsWithResults.length - 7);
        final qfOrBetter = last7.where((t) => (resultRanking[_bestDisciplineResult(t)] ?? 99) <= 6).length;
        if (qfOrBetter >= 6) {
          insights.add({"icon": "⭐", "title": "Consistent Contender", "body": "You have reached at least the Quarter Final in $qfOrBetter of your last 7 tournaments. You are becoming a consistently competitive tournament player.", "tier": "pro"});
        }
      }
    }
    // ── Top Improvement Area (free, inserted at front) ──
    if (completed.length >= 5) {
      String topTitle = "Top Improvement Area";
      String topBody = "";
      String topIcon = "🎯";

      // Find the biggest weakness
      final winRate2 = completed.isNotEmpty ? completed.where((m) => _matchWinner(m) == "player").length / completed.length : 0.0;
      final closeGames = completed.where((m) {
        final g1diff = (m.g1Player - m.g1Opponent).abs();
        final g2diff = (m.g2Player - m.g2Opponent).abs();
        final g3diff = (m.g3Player - m.g3Opponent).abs();
        return g1diff <= 3 || g2diff <= 3 || (g3diff <= 3 && (m.g3Player > 0 || m.g3Opponent > 0));
      }).toList();
      final closeWins = closeGames.where((m) => _matchWinner(m) == "player").length;
      final closeRate = closeGames.isNotEmpty ? closeWins / closeGames.length : 1.0;

      final comebackMatches = completed.where((m) => m.g1Player < m.g1Opponent).toList();
      final comebackWins = comebackMatches.where((m) => _matchWinner(m) == "player").length;
      final comebackRate = comebackMatches.isNotEmpty ? comebackWins / comebackMatches.length : 1.0;

      if (closeRate < 0.35 && closeGames.length >= 3) {
        final currentWinPct = (winRate2 * 100).round();
        final projectedWins = (closeGames.length * 0.5).round();
        final projectedRate = ((completed.where((m) => _matchWinner(m) == "player").length + projectedWins - closeWins) / completed.length * 100).round();
        topBody = "Improve your performance in close games. Winning just a few more tight matches would increase your overall win rate from $currentWinPct% to around $projectedRate%.";
      } else if (comebackRate < 0.2 && comebackMatches.length >= 3) {
        topBody = "Improve your comeback rate after losing Game 1. You currently recover to win only ${(comebackRate * 100).round()}% of those matches. Stronger starts and better between-game adjustments could make a big difference.";
      } else if (winRate2 < 0.4) {
        topBody = "Focus on converting your close losses into wins. Identifying patterns in your defeats and adjusting your tactics could significantly improve your overall results.";
      } else {
        topBody = "Push yourself against stronger opponents. Your consistency is a strength. Testing yourself at a higher level will accelerate your improvement.";
      }

      insights.insert(0, {"icon": topIcon, "title": topTitle, "body": topBody, "tier": "free"});
    }

    // ── Current Strength (free) ──
    if (completed.length >= 5) {
      String strengthTitle = "Current Strength";
      String strengthBody = "";
      String strengthIcon = "⭐";

      final winRate3 = completed.isNotEmpty ? completed.where((m) => _matchWinner(m) == "player").length / completed.length : 0.0;
      final g1WonCount = completed.where((m) => m.g1Player > m.g1Opponent).length;
      final g1WinPct = (g1WonCount / completed.length * 100).round();

      final comebackMatches2 = completed.where((m) => m.g1Player < m.g1Opponent).toList();
      final comebackWins2 = comebackMatches2.where((m) => _matchWinner(m) == "player").length;
      final comebackRate2 = comebackMatches2.isNotEmpty ? comebackWins2 / comebackMatches2.length : 0.0;

      if (g1WinPct >= 60) {
        strengthBody = "You win $g1WinPct% of matches when taking the first game. Strong starts are becoming a key strength of your game. Keep applying pressure early.";
      } else if (comebackRate2 >= 0.5 && comebackMatches2.length >= 3) {
        strengthBody = "You recover to win ${(comebackRate2 * 100).round()}% of matches after losing Game 1. Your resilience under pressure is a genuine competitive strength.";
      } else if (winRate3 >= 0.6) {
        strengthBody = "You win ${(winRate3 * 100).round()}% of your matches. Your overall consistency is your biggest strength right now. Keep building on it.";
      } else {
        strengthBody = "You are tracking and analysing your game. Players who measure their performance improve faster. That discipline is already a strength.";
      }

      insights.insert(1, {"icon": strengthIcon, "title": strengthTitle, "body": strengthBody, "tier": "free"});
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
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PremiumWidget()),
              );
              if (mounted) {
                await Future.delayed(const Duration(seconds: 2));
                _loadStatus();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: accentColor, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: Text("Start building my coaching report", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          )),
        ],
        if (isLocked && !isGettingStarted) ...[
        ],
      ]),
    );
    if (!isLocked) return card;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(children: [
            ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4), child: card),
            Positioned.fill(child: Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)))),
          ]),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PremiumWidget()),
              );
              if (mounted) {
                await Future.delayed(const Duration(seconds: 2));
                _loadStatus();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              "See this insight →",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
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
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PremiumWidget()),
              );
              if (mounted) {
                await Future.delayed(const Duration(seconds: 2));
                _loadStatus();
              }
            },
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
  Widget _buildSignUpPrompt(BuildContext context, Color primary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.psychology_rounded, size: 40, color: primary),
            ),
            const SizedBox(height: 24),
            Text(
              "Unlock Your AI Coach",
              style: GoogleFonts.interTight(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Your matches are building a picture of your game. Create a free account to unlock your personal AI Coach and access your data across multiple devices.",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.goNamed("RegisterPage"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                ),
                child: Text("Create Free Account", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Your match history will carry over when you sign up.",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

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
        child: !loggedIn
            ? _buildSignUpPrompt(context, primary)
            : _loadingStatus
            ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primary)))
            : StreamBuilder<List<TournamentsRecord>>(
                stream: queryTournamentsRecord(queryBuilder: (q) => q.where("ownerUid", isEqualTo: currentUserUid).orderBy("date", descending: true)),
                builder: (context, tournamentSnapshot) {
                  return StreamBuilder<List<MatchesRecord>>(
                stream: queryMatchesRecord(queryBuilder: (q) => q.where("ownerUid", isEqualTo: currentUserUid).orderBy("matchDate", descending: true)),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primary)));
                  final matches = snapshot.data!;
                  final completed = matches.where((m) => _matchWinner(m) != null).toList();
                  final insights = _generateInsights(matches, tournaments: tournamentSnapshot.data ?? []);
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
                      ...( isFree ? freeInsights.take(5).toList() : freeInsights).map((i) => _buildInsightCard(i, false)),
                      if (proInsights.isNotEmpty) ...[const SizedBox(height: 4), ...proInsights.map((i) => _buildInsightCard(i, isFree))],
                      if (premiumInsights.isNotEmpty) ...[const SizedBox(height: 4), ...premiumInsights.map((i) => _buildInsightCard(i, !isPremium))],
                      if (isFree) ...[const SizedBox(height: 8), _buildBlurredPreviewBanner(blurredInsights, completed.length)],
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F0FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD4C5F9), width: 1),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('📈', style: TextStyle(fontSize: 22)),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isFree ? 'Unlock more insights' : 'More matches, more insights',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF3D1F7A)),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      isFree
                                        ? 'You have 5 free insights. Upgrade to Pro or Premium to unlock up to 21 personalised insights.'
                                        : isPremium
                                          ? 'You are getting the full picture. Keep logging to sharpen your insights.'
                                          : 'Keep logging matches to get more personalised coaching from your data.',
                                      style: TextStyle(fontSize: 12, color: Color(0xFF5A4080), height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  );
                },
              );
                },
              ),
      ),
    );
  }
}
