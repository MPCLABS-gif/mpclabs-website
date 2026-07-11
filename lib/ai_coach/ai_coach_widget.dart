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
      insights.add({"icon": "🔥", "title": "Strong Win Rate", "body": "You are winning ${(winRate * 100).round()}% of your ${completed.length} matches. Your consistency is producing strong results. Keep challenging yourself and looking for ways to keep improving.", "tier": "free"});
    } else if (winRate >= 0.5) {
      insights.add({"icon": "📈", "title": "Positive Win Rate", "body": "You are winning ${(winRate * 100).round()}% of your ${completed.length} matches. You win more than you lose. But the margins are tight. The next step is improving how you close out matches when you are in a winning position.", "tier": "free"});
    } else if (winRate > 0.2) {
      insights.add({"icon": "💪", "title": "Developing Win Rate", "body": "You are winning ${(winRate * 100).round()}% of your ${completed.length} matches. You are still building your results and gaining valuable match experience. Every match adds to your picture.", "tier": "free"});
    } else {
      insights.add({"icon": "🌱", "title": "Building Your Profile", "body": "We have analysed ${completed.length} matches so far. Keep tracking your results to unlock more accurate coaching insights and personalised recommendations.", "tier": "free"});
    }

    final moodStats = <String, Map<String, int>>{};
    for (final m in completed) {
      if (m.mood.isEmpty) continue;
      moodStats[m.mood] ??= {"wins": 0, "total": 0};
      moodStats[m.mood]!["total"] = moodStats[m.mood]!["total"]! + 1;
      if (_matchWinner(m) == "player") moodStats[m.mood]!["wins"] = moodStats[m.mood]!["wins"]! + 1;
    }
    // ── Peak Performance Mood (free) ──
    if (moodStats.isNotEmpty) {
      String? bestMood; double bestRate = 0;
      String? worstMoodFree; double worstRateFree = 1;
      moodStats.forEach((mood, stats) {
        if (stats["total"]! >= 2) {
          final rate = stats["wins"]! / stats["total"]!;
          if (rate > bestRate) { bestRate = rate; bestMood = mood; }
          if (rate < worstRateFree) { worstRateFree = rate; worstMoodFree = mood; }
        }
      });
      if (bestMood != null) {
        final pct = (bestRate * 100).round();
        String moodBody;
        if (bestRate >= 0.7) {
          moodBody = "You perform very strongly when feeling $bestMood, winning $pct% of those matches. Try to bring that mindset into every match.";
        } else if (bestRate >= 0.4) {
          moodBody = "You perform best when feeling $bestMood, winning $pct% of those matches. Try to recreate that mindset before your next game.";
        } else {
          moodBody = "You perform slightly better when feeling $bestMood, but results are still building. Focus on consistency across all matches.";
        }
        insights.add({"icon": "🧠", "title": "Peak Performance Mood", "body": moodBody, "tier": "free"});
        if (worstMoodFree != null && worstMoodFree != bestMood && worstRateFree < 0.5) {
          insights.add({"icon": "⚡", "title": "Mood to Watch", "body": "When feeling $worstMoodFree, your results tend to drop. Being aware of this can help you manage your mindset during matches.", "tier": "free"});
        }
      } else {
        insights.add({"icon": "🧠", "title": "Peak Performance Mood", "body": "We need at least 5 matches recorded in the same mood before identifying your strongest mental state. Keep logging your pre-match mood to unlock this insight.", "tier": "free"});
      }
    }

    // ── On Fire / Reset Mode (free) ──
    {
      int winStreak = 0;
      int loseStreak = 0;
      for (final m in completed) {
        if (_matchWinner(m) == "player") { winStreak++; loseStreak = 0; }
        else { loseStreak++; winStreak = 0; }
      }
      // completed is ordered descending so first entry = most recent
      // recalculate streaks from most recent
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
        insights.add({"icon": "🔥", "title": "On Fire!", "body": "$wStreak wins in a row. You are in top form right now. This is a great time to push yourself against stronger opponents.", "tier": "free"});
      } else if (wStreak >= 3) {
        insights.add({"icon": "🔥", "title": "On Fire!", "body": "$wStreak match winning streak. Your game is in a good place. Keep the momentum going.", "tier": "free"});
      } else if (wStreak == 2) {
        insights.add({"icon": "📈", "title": "Early Momentum", "body": "You have won two matches in a row. Momentum is starting to build. Keep it going.", "tier": "free"});
      } else if (lStreak >= 3) {
        insights.add({"icon": "🔄", "title": "Losing Streak", "body": "$lStreak matches have not gone your way. Small adjustments and continued effort can help turn things around.", "tier": "free"});
      } else if (lStreak >= 1) {
        insights.add({"icon": "🔄", "title": "Bounce Back Time", "body": "Your last match was a loss. One result does not define your form. Focus on your next match.", "tier": "free"});
      } else if (wStreak == 1) {
        insights.add({"icon": "✅", "title": "Winning Momentum", "body": "You won your last match. A good result. Build on this in your next game.", "tier": "free"});
      }
    }

    // ── Danger Mood Warning (pro) ──
    if (moodStats.isNotEmpty) {
      String? worstMoodPro; double worstRatePro = 1;
      moodStats.forEach((mood, stats) {
        if (stats["total"]! >= 3) {
          final rate = stats["wins"]! / stats["total"]!;
          if (rate < worstRatePro) { worstRatePro = rate; worstMoodPro = mood; }
        }
      });
      final bestMoodForCheck = moodStats.entries.where((e) => e.value["total"]! >= 2).fold<String?>(null, (prev, e) { final r = e.value["wins"]! / e.value["total"]!; return (prev == null || r > (moodStats[prev]!["wins"]! / moodStats[prev]!["total"]!)) ? e.key : prev; });
      if (worstMoodPro != null && worstMoodPro != bestMoodForCheck && worstRatePro < winRate) {
        final pct = (worstRatePro * 100).round();
        String dangerBody;
        if (worstRatePro < 0.2) {
          dangerBody = "When you feel $worstMoodPro, your win rate drops to $pct%. This mood appears to be making matches more challenging. Being aware of it is the first step to managing it.";
        } else if (worstRatePro < 0.4) {
          dangerBody = "Your win rate is $pct% when feeling $worstMoodPro. This is a pattern worth noting. Finding ways to manage this mindset before matches could help your performance.";
        } else {
          dangerBody = "You win $pct% when feeling $worstMoodPro, which is lower than your usual level. Being aware of this pattern is a useful first step.";
        }
        insights.add({"icon": "⚠️", "title": "Performance Mood Alert", "body": dangerBody, "tier": "pro"});
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
        freqBody = "You have played $last30 matches in the last 30 days. You are playing regularly. This level of consistency supports steady improvement. Make sure you are recovering well between matches.";
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
      if (recent15 > prev15 && prev15 > 0) trendAdd = " You have been more active recently. Keep this rhythm going.";
      else if (prev15 > recent15 && recent15 < prev15) trendAdd = " Your recent activity has dropped. Getting back into a routine will help.";
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
      if (tCount == completed.length) {
        balanceBody = "All your recorded matches are tournaments. Adding practice sessions will help you refine your game between competitions.";
      } else if (pCount == completed.length) {
        balanceBody = "All your recorded matches are practice. Competition is where your game gets tested. Consider entering a tournament to challenge yourself.";
      } else if (tPct >= 70) {
        balanceBody = "Your matches are $tPct% tournaments and $pPct% practice. You are getting strong competitive exposure. Make sure you balance it with practice to keep improving your game.";
      } else if (pPct >= 70) {
        balanceBody = "Your matches are $pPct% practice and $tPct% tournaments. You are building a solid base. Start testing your game more in competition.";
      } else if (completed.length < 5) {
        balanceBody = "You have not logged many matches yet. Keep tracking to get a clearer view of your playing patterns.";
      } else {
        balanceBody = "Your matches are well balanced between practice and tournaments. You are developing your game and testing it. Keep this balance going.";
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
        String closeBody; String closeTitle;
        if (closeRate >= 0.6) {
          closeTitle = "Close Game Specialist";
          closeBody = "In close games decided by 3 points or fewer, you win $closePct% of them. You handle tight situations well. This is a strong competitive edge.";
        } else if (closeRate >= 0.4) {
          closeTitle = "Competitive in Close Games";
          closeBody = "In close games decided by 3 points or fewer, you win $closePct% of them. You are competitive in tight moments. Small improvements in key points could push this higher.";
        } else {
          closeTitle = "Close Games Need Work";
          closeBody = "In close games decided by 3 points or fewer, you win $closePct% of them. Tight moments are a good opportunity for growth. Improving focus on key points could make a real difference.";
        }
        final addOn = totalGamesPlayed > 0 && (closeGamesTotal / totalGamesPlayed) >= 0.4
            ? " A large portion of your games are decided by small margins. Improving performance in these moments could significantly impact your results."
            : "";
        insights.add({"icon": "⚔️", "title": closeTitle, "body": closeBody + addOn, "tier": "pro"});
      }
    }

    // ── Consistency Score (pro) ──
    if (completed.length >= 8) {
      final sample = completed.take(10).toList();
      int switches = 0;
      for (int i = 0; i < sample.length - 1; i++) {
        final curr = _matchWinner(sample[i]) == "player";
        final next = _matchWinner(sample[i + 1]) == "player";
        if (curr != next) switches++;
      }
      final ratio = switches / (sample.length - 1);
      String consBody; String consTitle;
      if (ratio <= 0.3) {
        consTitle = "Performance Stability";
        consBody = "Your performances are generally consistent from match to match. Consistency is a strong foundation for long-term improvement.";
      } else if (ratio <= 0.55) {
        consTitle = "Performance Stability";
        consBody = "Your results show some variation between matches. Working on your pre-match routine and preparation could help you perform at your best more often.";
      } else {
        consTitle = "Inconsistent Results";
        consBody = "Your results vary significantly between matches. Your results vary significantly between matches. Building a consistent routine and preparation could help unlock better results.";
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
        if (recentSwitches < earlierSwitches) consAddOn = " Your recent matches are becoming more consistent. Keep building on this.";
      }
      insights.add({"icon": "📊", "title": consTitle, "body": consBody + consAddOn, "tier": "pro"});
    }

    // ── Tournament Performance (pro) ──

    if (tMatches.length >= 3 && pMatches.length >= 3) {
      final tRate = tMatches.where((m) => _matchWinner(m) == "player").length / tMatches.length;
      final pRate = pMatches.where((m) => _matchWinner(m) == "player").length / pMatches.length;
      final tPct = (tRate * 100).round();
      final pPct = (pRate * 100).round();
      final diff = tRate - pRate;
      String tournBody;
      String tournTitle;
      String tournIcon;
      if (diff >= 0.2) {
        tournTitle = "Tournament Advantage"; tournIcon = "🏆";
        tournBody = "You win $tPct% of your tournament matches compared to $pPct% in practice. You perform strongly in competition. Keep building on this edge.";
      } else if (diff >= 0.1) {
        tournTitle = "Slight Tournament Edge"; tournIcon = "🏆";
        tournBody = "Your tournament win rate is $tPct% compared to $pPct% in practice. Competition brings out a little extra in your game. Keep building on it.";
      } else if (diff <= -0.2) {
        tournTitle = "Tournament Pressure"; tournIcon = "⚡";
        tournBody = "Your win rate drops from $pPct% in practice to $tPct% in tournaments. Tournament matches seem more challenging right now. Building your preparation and pre-match routine could help close the gap.";
      } else if (diff <= -0.1) {
        tournTitle = "Slight Tournament Pressure"; tournIcon = "⚡";
        tournBody = "You win $tPct% in tournaments compared to $pPct% in practice. There is a small gap. Focusing on consistency could help close it.";
      } else {
        tournTitle = ""; tournIcon = ""; tournBody = "";
      }
      if (tournBody.isNotEmpty) insights.add({"icon": tournIcon, "title": tournTitle, "body": tournBody, "tier": "pro"});
    }

    // ── Comeback Performance (pro) ──
    final lostG1 = completed.where((m) => m.g1Player < m.g1Opponent).toList();
    if (lostG1.length >= 3) {
      final comebacks = lostG1.where((m) => _matchWinner(m) == "player").length;
      final rate = comebacks / lostG1.length;
      final pct = (rate * 100).round();
      String comebackBody; String comebackTitle; String comebackIcon;
      if (rate >= 0.7) {
        comebackTitle = "Comeback King"; comebackIcon = "🔄";
        comebackBody = "You win $pct% of matches after losing Game 1. You handle pressure well and find ways to turn matches around. A strong competitive edge.";
      } else if (rate >= 0.5) {
        comebackTitle = "Strong Comeback"; comebackIcon = "💪";
        comebackBody = "You recover to win $pct% of matches after losing Game 1. Your resilience is a strength. Keep trusting your game when you fall behind.";
      } else if (rate >= 0.2) {
        comebackTitle = "Developing Comebacks"; comebackIcon = "🎯";
        comebackBody = "When you lose Game 1, you recover $pct% of the time. Improving your reset between games could help turn more matches around.";
      } else {
        comebackTitle = "Start Strong"; comebackIcon = "⚡";
        comebackBody = "After losing Game 1, there is an opportunity to improve how you reset and respond. Your comeback rate is $pct%. Focusing on strong starts and between-game adjustments could make a difference.";
      }
      insights.add({"icon": comebackIcon, "title": comebackTitle, "body": comebackBody, "tier": "pro"});
    }

    // ── Closing Out Matches (pro) ──
    final wonG1 = completed.where((m) => m.g1Player > m.g1Opponent).toList();
    if (wonG1.length >= 3) {
      final ledLost = wonG1.where((m) => _matchWinner(m) == "opponent").length;
      final ledRate = ledLost / wonG1.length;
      final ledPct = (ledRate * 100).round();
      String closeBody; String closeTitle;
      if (ledRate >= 0.5) {
        closeTitle = "Closing Challenge";
        closeBody = "You are losing $ledPct% of matches after winning Game 1. Closing out matches is proving difficult. Maintaining focus and intensity when ahead could make a big difference.";
      } else if (ledRate >= 0.3) {
        closeTitle = "Closing Needs Work";
        closeBody = "You lose $ledPct% of matches after winning Game 1. This is a pattern worth improving. Sustaining pressure when you are ahead could help you win more matches.";
      } else if (ledRate >= 0.15) {
        closeTitle = "Slight Closing Issue";
        closeBody = "You occasionally lose matches after winning Game 1. $ledPct% of the time. Small lapses when ahead can be costly.";
      } else {
        closeTitle = ""; closeBody = "";
      }
      if (closeBody.isNotEmpty) insights.add({"icon": "😤", "title": closeTitle, "body": closeBody, "tier": "pro"});
    }

    // ── Main Rival (pro) ──
    final opponentCount = <String, int>{};
    for (final m in completed) { if (m.opponentName.isNotEmpty) opponentCount[m.opponentName] = (opponentCount[m.opponentName] ?? 0) + 1; }
    if (opponentCount.isNotEmpty) {
      final rival = opponentCount.entries.reduce((a, b) => a.value >= b.value ? a : b);
      if (rival.value >= 3) {
        final rivalWins = completed.where((m) => m.opponentName == rival.key && _matchWinner(m) == "player").length;
        final rivalRate = rivalWins / rival.value;
        final rivalPct = (rivalRate * 100).round();
        String rivalBody;
        if (rivalRate >= 0.7) {
          rivalBody = "You have played ${rival.key} ${rival.value} times and won $rivalPct% of those matches. You have a strong record in this matchup. Keep the consistency.";
        } else if (rivalRate >= 0.4) {
          rivalBody = "${rival.key} is your most frequent opponent. You have played ${rival.value} matches and won $rivalPct%. It is a close rivalry. Small adjustments could give you the edge.";
        } else {
          rivalBody = "${rival.key} has had the better results so far. Your record in this matchup is $rivalPct%. Every match gives you more information for next time.";
        }
        insights.add({"icon": "🆚", "title": "Toughest Opponent", "body": rivalBody, "tier": "pro"});
      }
    }

    // ── Format Strength (pro) ──
    final doubles = completed.where((m) => m.partnerName.isNotEmpty).toList();
    final singles = completed.where((m) => m.partnerName.isEmpty).toList();
    if (doubles.length >= 3 && singles.length >= 3) {
      final dRate = doubles.where((m) => _matchWinner(m) == "player").length / doubles.length;
      final sRate = singles.where((m) => _matchWinner(m) == "player").length / singles.length;
      final sPct = (sRate * 100).round();
      final dPct = (dRate * 100).round();
      final fDiff = sRate - dRate;
      String formatBody; String formatTitle;
      if (fDiff >= 0.2) {
        formatTitle = "Singles Specialist";
        formatBody = "You win $sPct% of your singles matches compared to $dPct% in doubles. Singles is your stronger format. Keep building on this advantage.";
      } else if (fDiff >= 0.1) {
        formatTitle = "Slight Singles Edge";
        formatBody = "Your singles win rate is $sPct% compared to $dPct% in doubles. You perform slightly better in singles. Continue developing both formats.";
      } else if (fDiff <= -0.2) {
        formatTitle = "Doubles Specialist";
        formatBody = "You win $dPct% of your doubles matches compared to $sPct% in singles. Doubles is your stronger format. Keep building on this advantage.";
      } else if (fDiff <= -0.1) {
        formatTitle = "Slight Doubles Edge";
        formatBody = "Your doubles win rate is $dPct% compared to $sPct% in singles. You perform slightly better in doubles. Continue building across both formats.";
      } else {
        formatTitle = ""; formatBody = "";
      }
      if (formatBody.isNotEmpty) insights.add({"icon": "🏸", "title": formatTitle, "body": formatBody, "tier": "pro"});
    }

    // ── Opponent Handedness (pro) ──
    {
      final rightMatches = completed.where((m) => m.opponentHandedness == "Right").toList();
      final leftMatches = completed.where((m) => m.opponentHandedness == "Left").toList();
      if (rightMatches.length >= 3 && leftMatches.length >= 3) {
        final rightWins = rightMatches.where((m) => _matchWinner(m) == "player").length;
        final leftWins = leftMatches.where((m) => _matchWinner(m) == "player").length;
        final rightRate = rightWins / rightMatches.length;
        final leftRate = leftWins / leftMatches.length;
        final rightPct = (rightRate * 100).round();
        final leftPct = (leftRate * 100).round();
        final diff = rightRate - leftRate;
        String handBody; String handTitle; String handIcon;
        if (diff >= 0.2) {
          handTitle = "Left-Handers Are a Challenge";
          handIcon = "🤚";
          handBody = "You win $rightPct% against right-handed opponents but only $leftPct% against left-handers. Left-handed opponents present a different challenge. Their angles and shot patterns are different. Practising against left-handers or working on reading their play could make a real difference.";
        } else if (diff >= 0.1) {
          handTitle = "Slight Weakness vs Left-Handers";
          handIcon = "🤚";
          handBody = "Your win rate is $rightPct% against right-handers and $leftPct% against left-handers. There is a small gap. Left-handed players bring different angles. Being more aware of this could help.";
        } else if (diff <= -0.2) {
          handTitle = "Strong vs Left-Handers";
          handIcon = "💪";
          handBody = "You win $leftPct% against left-handed opponents compared to $rightPct% against right-handers. You handle left-handers well. Their angles and patterns do not seem to trouble you.";
        } else if (diff <= -0.1) {
          handTitle = "Slight Edge vs Left-Handers";
          handIcon = "💪";
          handBody = "You perform slightly better against left-handed opponents, winning $leftPct% compared to $rightPct% against right-handers. Keep building on this.";
        } else {
          handTitle = "Consistent vs Both Hands";
          handIcon = "🏸";
          handBody = "Your win rate is $rightPct% against right-handers and $leftPct% against left-handers. You perform consistently regardless of handedness. A good sign of all-round ability.";
        }
        insights.add({"icon": handIcon, "title": handTitle, "body": handBody, "tier": "pro"});
      } else if (leftMatches.length >= 3 && rightMatches.length < 3) {
        final leftWins = leftMatches.where((m) => _matchWinner(m) == "player").length;
        final leftRate = leftWins / leftMatches.length;
        final leftPct = (leftRate * 100).round();
        insights.add({"icon": "🤚", "title": "Left-Hander Record", "body": "You have played ${leftMatches.length} matches against left-handed opponents, winning $leftPct% of them. Keep logging opponent handedness to unlock a full comparison.", "tier": "pro"});
      } else if (rightMatches.length >= 3 && leftMatches.length < 3) {
        insights.add({"icon": "🏸", "title": "Handedness Data Building", "body": "You need at least 3 matches against left-handed opponents to unlock your handedness insight. Keep logging opponent handedness when adding matches.", "tier": "pro"});
      }
    }

    // ── Match Dominance Profile (premium) ──
    {
      int gamesWon = 0;
      int gamesLost = 0;
      int totalWinMargin = 0;
      int totalLossMargin = 0;
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
          else if (o > p) { gamesLost++; totalLossMargin += (o - p); }
        }
      }
      if (gamesWon >= 5) {
        final avgWinMargin = totalWinMargin / gamesWon;
        final avgLossMargin = gamesLost > 0 ? totalLossMargin / gamesLost : 0.0;
        final marginStr = avgWinMargin.toStringAsFixed(1);
        String domBody; String domTitle;
        if (avgWinMargin >= 6) {
          domTitle = "Match Dominator";
          domBody = "When you win games, you win them by an average of $marginStr points. Your victories are comfortable. You tend to control games.";
        } else if (avgWinMargin >= 3) {
          domTitle = "Controlled Winner";
          domBody = "When you win games, you win them by an average of $marginStr points. Your wins are solid. You stay in control without always dominating.";
        } else {
          domTitle = "Narrow Winner";
          domBody = "When you win games, you win them by an average of $marginStr points. Your wins are tight. Improving how you close out games could help you take more control.";
        }
        final addOnDom = avgLossMargin >= avgWinMargin
            ? " You are also losing games by similar or larger margins. Reducing errors in those moments could improve your results."
            : "";
        insights.add({"icon": "💪", "title": domTitle, "body": domBody + addOnDom, "tier": "premium"});
      }
    }

    // ── Performance Under Pressure (premium) ──
    {
      int pressureTotal = 0;
      int pressureWon = 0;
      for (final m in completed) {
        final g3Played = m.g3Player > 0 || m.g3Opponent > 0;
        if (!g3Played) continue;
        final g3Diff = (m.g3Player - m.g3Opponent).abs();
        if (g3Diff <= 3) {
          pressureTotal++;
          if (_matchWinner(m) == "player") pressureWon++;
        }
      }
      if (pressureTotal >= 3) {
        final pressRate = pressureWon / pressureTotal;
        final pressPct = (pressRate * 100).round();
        String pressBody; String pressTitle;
        if (pressRate >= 0.6) {
          pressTitle = "Clutch Performer";
          pressBody = "In matches decided by tight final games, you win $pressPct% of the time. You perform well in decisive moments. A strong competitive edge.";
        } else if (pressRate >= 0.4) {
          pressTitle = "Competitive Under Pressure";
          pressBody = "In matches decided by tight final games, you win $pressPct% of the time. You compete well under pressure. Small improvements in key moments could make a difference.";
        } else {
          pressTitle = "Pressure Needs Work";
          pressBody = "In matches decided by tight final games, you win $pressPct% of the time. Tight matches are a great opportunity to develop your decision-making under pressure. Small improvements in key moments could help.";
        }
        insights.add({"icon": "🎯", "title": pressTitle, "body": pressBody, "tier": "premium"});
      }
    }

    // ── Deciding Game Performance (premium) ──

    final threeSetMatches = completed.where((m) => m.g3Player > 0 || m.g3Opponent > 0).toList();
    if (threeSetMatches.length >= 3) {
      final g3Wins = threeSetMatches.where((m) => _matchWinner(m) == "player").length;
      final g3Rate = g3Wins / threeSetMatches.length;
      final g3Pct = (g3Rate * 100).round();
      String g3Body; String g3Title; String g3Icon;
      if (g3Rate >= 0.7) {
        g3Title = "Decider Specialist"; g3Icon = "💥";
        g3Body = "You win $g3Pct% of your deciding games. When matches go the distance, you consistently find a way to come out on top. A strong competitive edge.";
      } else if (g3Rate >= 0.5) {
        g3Title = "Strong in Deciders"; g3Icon = "💪";
        g3Body = "You win $g3Pct% of your deciding games. You handle pressure well. Keep building your consistency in close matches.";
      } else if (g3Rate >= 0.3) {
        g3Title = "Decider Needs Work"; g3Icon = "🎯";
        g3Body = "You win $g3Pct% of your deciding games. Deciding games are a valuable opportunity for growth. Stronger focus and consistency could help.";
      } else {
        g3Title = "Struggling in Deciders"; g3Icon = "⚡";
        g3Body = "You win $g3Pct% of your deciding games. When matches go to a final game, there is an opportunity to improve how you finish strongly. Focusing on fitness and between-game resets could help.";
      }
      insights.add({"icon": g3Icon, "title": g3Title, "body": g3Body, "tier": "premium"});
    }

    // ── Performance Trend (premium) ──
    final sortedByDate = List<MatchesRecord>.from(completed)..sort((a, b) => a.matchDate!.compareTo(b.matchDate!));
    if (sortedByDate.length >= 6) {
      final recentMatches = sortedByDate.reversed.take(5).toList();
      final earlierMatches = sortedByDate.reversed.skip(5).take(5).toList();
      if (earlierMatches.isNotEmpty) {
        final recentRate = recentMatches.where((m) => _matchWinner(m) == "player").length / recentMatches.length;
        final earlyRate = earlierMatches.where((m) => _matchWinner(m) == "player").length / earlierMatches.length;
        final trendDiff = recentRate - earlyRate;
        final recentPct = (recentRate * 100).round();
        final earlyPct = (earlyRate * 100).round();
        String trendBody; String trendTitle; String trendIcon;
        if (trendDiff >= 0.2) {
          trendTitle = "Strong Improvement"; trendIcon = "📈";
          trendBody = "Your recent win rate is $recentPct%, up from $earlyPct% earlier. You are improving quickly. Keep building on what is working.";
        } else if (trendDiff >= 0.1) {
          trendTitle = "Improving Trend"; trendIcon = "📈";
          trendBody = "Your recent win rate is $recentPct%, slightly ahead of $earlyPct% earlier. You are trending in the right direction. Consistency will be key.";
        } else if (trendDiff <= -0.2) {
          trendTitle = "Significant Dip"; trendIcon = "📉";
          trendBody = "Your recent win rate is $recentPct%, down from $earlyPct% earlier. Something has changed. Reviewing your recent matches could help identify what to adjust.";
        } else if (trendDiff <= -0.1) {
          trendTitle = "Slight Dip in Form"; trendIcon = "📉";
          trendBody = "Your recent win rate is $recentPct%, slightly down from $earlyPct% earlier. A small dip. Reflecting on recent matches could help you get back on track.";
        } else {
          trendTitle = ""; trendIcon = ""; trendBody = "";
        }
        if (trendBody.isNotEmpty) insights.add({"icon": trendIcon, "title": trendTitle, "body": trendBody, "tier": "premium"});
      }
    }

    // ── Recent Form (premium) ──
    if (completed.length >= 5) {
      final last5Rate = completed.take(5).where((m) => _matchWinner(m) == "player").length / 5;
      final formDiff = last5Rate - winRate;
      final last5Pct = (last5Rate * 100).round();
      final careerPct = (winRate * 100).round();
      String formBody; String formTitle; String formIcon;
      if (formDiff >= 0.2) {
        formTitle = "Excellent Recent Form"; formIcon = "🔥";
        formBody = "Your last 5 matches show a $last5Pct% win rate. Well above your overall average of $careerPct%. You are in strong form right now. Keep building on it.";
      } else if (formDiff >= 0.1) {
        formTitle = "Good Recent Form"; formIcon = "📈";
        formBody = "Your last 5 matches show a $last5Pct% win rate. Ahead of your overall average of $careerPct%. Your recent form is encouraging. Keep the momentum going.";
      } else if (formDiff <= -0.2) {
        formTitle = "Poor Recent Form"; formIcon = "📉";
        formBody = "Your last 5 matches show a $last5Pct% win rate. Below your overall average of $careerPct%. Your recent form needs attention. Reviewing recent matches could help identify what to adjust.";
      } else if (formDiff <= -0.1) {
        formTitle = "Slight Dip in Form"; formIcon = "📉";
        formBody = "Your last 5 matches show a $last5Pct% win rate. Slightly below your overall average of $careerPct%. A small dip. Focus on getting back to your usual level.";
      } else {
        formTitle = ""; formIcon = ""; formBody = "";
      }
      if (formBody.isNotEmpty) insights.add({"icon": formIcon, "title": formTitle, "body": formBody, "tier": "premium"});
    }

    // ── Points Profile (premium) ──
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
        final ptDiff = avgScored - avgConceded;
        final scoredStr = avgScored.toStringAsFixed(1);
        final concededStr = avgConceded.toStringAsFixed(1);
        String ptBody; String ptTitle;
        if (ptDiff >= 5) {
          ptTitle = "Points Dominant";
          ptBody = "You average $scoredStr points scored vs $concededStr conceded per game. You are controlling the points consistently. Your game is in a strong place.";
        } else if (ptDiff >= 2) {
          ptTitle = "Competitive Edge";
          ptBody = "You average $scoredStr points scored vs $concededStr conceded per game. You have a small edge. Maintaining consistency in key moments can turn this into more wins.";
        } else if (ptDiff >= -1) {
          ptTitle = "Tight Matches";
          ptBody = "You average $scoredStr points scored vs $concededStr conceded per game. Matches are very close. Small moments are deciding the outcome.";
        } else if (ptDiff >= -4) {
          ptTitle = "Slightly Behind";
          ptBody = "You average $scoredStr points scored vs $concededStr conceded per game. Opponents have a slight edge. Tightening key areas could help close the gap.";
        } else {
          ptTitle = "Points Gap";
          ptBody = "You average $scoredStr points scored vs $concededStr conceded per game. There is a clear gap. Focusing on reducing errors and building consistency could help improve results.";
        }
        if (ptDiff.abs() >= 2) insights.add({"icon": "📊", "title": ptTitle, "body": ptBody, "tier": "premium"});
      }
    }

    // ── Playing Style (premium) ──
    if (completed.length >= 3) {
      final g1WonCount = completed.where((m) => m.g1Player > m.g1Opponent).length;
      final g1StyleRate = g1WonCount / completed.length;
      final g1StylePct = (g1StyleRate * 100).round();
      String styleBody; String styleTitle;
      if (g1StyleRate >= 0.6) {
        styleTitle = "Aggressive Starter";
        styleBody = "Based on your match data, you tend to start strongly. Winning $g1StylePct% of first games. You set the tone early and apply pressure from the start. Maintaining that level across the match will be key.";
      } else if (g1StyleRate >= 0.4) {
        styleTitle = "Balanced Player";
        styleBody = "Based on your match data, you have a balanced start. Winning $g1StylePct% of first games. Matches are often shaped by how you perform in the middle and later stages.";
      } else {
        styleTitle = "Slow Builder";
        styleBody = "Based on your match data, you tend to start slowly. Winning $g1StylePct% of first games. Falling behind early can put you under pressure, so improving your opening game could make a difference.";
      }
      insights.add({"icon": "🧬", "title": styleTitle, "body": styleBody, "tier": "premium"});
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
        insights.add({"icon": "🥇", "title": "Champion's Challenge", "body": "You won Gold at $goldName. That is a significant achievement. The challenge now is to maintain that level and defend your title at the next opportunity.", "tier": "pro"});
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
