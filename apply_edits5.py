import re

def flexible_replace(text, old, new, label):
    tokens = old.split()
    pattern = r'\s+'.join(re.escape(t) for t in tokens)
    matches = list(re.finditer(pattern, text))
    assert len(matches) == 1, f"{label}: found {len(matches)} matches, expected 1"
    m = matches[0]
    return text[:m.start()] + new + text[m.end():]

path = "lib/ai_coach/ai_coach_widget.dart"
with open(path, "r", encoding="utf-8") as f:
    text = f.read()

# 1. Generalized dedup suppression across close / comeback / firstGame candidates
old1 = '''Map<String, dynamic>? focusCandidate;
      bool focusIsFirstGame = false;
      if (focusCandidate == null && closeRateF != null && closeRateF < 0.35) {
        final pct = (closeRateF * 100).round();
        focusCandidate = {"icon": "🎯", "title": "Performance Focus", "body": "You have won $pct% of your close games (decided by 3 points or fewer), based on $closeGamesTotalF such games. That's a pattern worth exploring — what could help you feel clearer and more decisive in those tight moments?", "tier": "free"};
      }
      if (focusCandidate == null && comebackRateF != null && comebackRateF < 0.3) {
        final pct = (comebackRateF * 100).round();
        focusCandidate = {"icon": "🎯", "title": "Performance Focus", "body": "After losing Game 1, you have won $pct% of those matches (${lostG1F.length} qualifying). That's worth exploring — what helps you reset and start Game 2 with a clear plan?", "tier": "free"};
      }
      if (focusCandidate == null && firstGameRateF != null && firstGameRateF < 0.4) {
        final pct = (firstGameRateF * 100).round();
        focusCandidate = {"icon": "🎯", "title": "Performance Focus", "body": "You have won $pct% of your first games across ${completed.length} matches. That's a pattern worth exploring — what could help you feel sharper from the very first point?", "tier": "free"};
        focusIsFirstGame = true;
      }
      Map<String, dynamic>? positiveCandidate;
      bool positiveIsFirstGame = false;
      if (positiveCandidate == null && closeRateF != null && closeRateF >= 0.6) {
        final pct = (closeRateF * 100).round();
        positiveCandidate = {"icon": "⭐", "title": "Positive Pattern", "body": "You have won $pct% of your close games (decided by 3 points or fewer), based on $closeGamesTotalF such games. That's a positive pattern — you're finding ways to come through when matches get tight.", "tier": "free"};
      }
      if (positiveCandidate == null && comebackRateF != null && comebackRateF >= 0.5) {
        final pct = (comebackRateF * 100).round();
        positiveCandidate = {"icon": "⭐", "title": "Positive Pattern", "body": "After losing Game 1, you have recovered to win $pct% of those matches (${lostG1F.length} qualifying). That's a positive pattern — worth noticing what helps you reset and respond.", "tier": "free"};
      }
      if (positiveCandidate == null && firstGameRateF != null && firstGameRateF >= 0.6) {
        final pct = (firstGameRateF * 100).round();
        positiveCandidate = {"icon": "⭐", "title": "Positive Pattern", "body": "You have won $pct% of your first games across ${completed.length} matches. That's a positive pattern — worth noticing what helps you start matches well.", "tier": "free"};
        positiveIsFirstGame = true;
      }
      if (focusIsFirstGame || positiveIsFirstGame) {
        insights.removeWhere((i) => i["title"] == "First Game Results");
      }
      final frontInsights = <Map<String, dynamic>>[];
      if (focusCandidate != null) frontInsights.add(focusCandidate);
      if (positiveCandidate != null) frontInsights.add(positiveCandidate);
      for (int i = frontInsights.length - 1; i >= 0; i--) {
        insights.insert(0, frontInsights[i]);
      }'''
new1 = '''Map<String, dynamic>? focusCandidate;
      String? focusCandidateType;
      if (focusCandidate == null && closeRateF != null && closeRateF < 0.35) {
        final pct = (closeRateF * 100).round();
        focusCandidate = {"icon": "🎯", "title": "Performance Focus", "body": "You have won $pct% of your close games (decided by 3 points or fewer), based on $closeGamesTotalF such games. That's a pattern worth exploring — what could help you feel clearer and more decisive in those tight moments?", "tier": "free"};
        focusCandidateType = "close";
      }
      if (focusCandidate == null && comebackRateF != null && comebackRateF < 0.3) {
        final pct = (comebackRateF * 100).round();
        focusCandidate = {"icon": "🎯", "title": "Performance Focus", "body": "After losing Game 1, you have won $pct% of those matches (${lostG1F.length} qualifying). That's worth exploring — what helps you reset and start Game 2 with a clear plan?", "tier": "free"};
        focusCandidateType = "comeback";
      }
      if (focusCandidate == null && firstGameRateF != null && firstGameRateF < 0.4) {
        final pct = (firstGameRateF * 100).round();
        focusCandidate = {"icon": "🎯", "title": "Performance Focus", "body": "You have won $pct% of your first games across ${completed.length} matches. That's a pattern worth exploring — what could help you feel sharper from the very first point?", "tier": "free"};
        focusCandidateType = "firstGame";
      }
      Map<String, dynamic>? positiveCandidate;
      String? positiveCandidateType;
      if (positiveCandidate == null && closeRateF != null && closeRateF >= 0.6) {
        final pct = (closeRateF * 100).round();
        positiveCandidate = {"icon": "⭐", "title": "Positive Pattern", "body": "You have won $pct% of your close games (decided by 3 points or fewer), based on $closeGamesTotalF such games. That's a positive pattern — you're finding ways to come through when matches get tight.", "tier": "free"};
        positiveCandidateType = "close";
      }
      if (positiveCandidate == null && comebackRateF != null && comebackRateF >= 0.5) {
        final pct = (comebackRateF * 100).round();
        positiveCandidate = {"icon": "⭐", "title": "Positive Pattern", "body": "After losing Game 1, you have recovered to win $pct% of those matches (${lostG1F.length} qualifying). That's a positive pattern — worth noticing what helps you reset and respond.", "tier": "free"};
        positiveCandidateType = "comeback";
      }
      if (positiveCandidate == null && firstGameRateF != null && firstGameRateF >= 0.6) {
        final pct = (firstGameRateF * 100).round();
        positiveCandidate = {"icon": "⭐", "title": "Positive Pattern", "body": "You have won $pct% of your first games across ${completed.length} matches. That's a positive pattern — worth noticing what helps you start matches well.", "tier": "free"};
        positiveCandidateType = "firstGame";
      }
      const candidateTypeToTitle = {
        "close": "Close Game Performance",
        "comeback": "Results After Losing Game 1",
        "firstGame": "First Game Results",
      };
      final suppressTitles = <String>{};
      if (focusCandidateType != null) suppressTitles.add(candidateTypeToTitle[focusCandidateType]!);
      if (positiveCandidateType != null) suppressTitles.add(candidateTypeToTitle[positiveCandidateType]!);
      if (suppressTitles.isNotEmpty) {
        insights.removeWhere((i) => suppressTitles.contains(i["title"]));
      }
      final frontInsights = <Map<String, dynamic>>[];
      if (focusCandidate != null) frontInsights.add(focusCandidate);
      if (positiveCandidate != null) frontInsights.add(positiveCandidate);
      for (int i = frontInsights.length - 1; i >= 0; i--) {
        insights.insert(0, frontInsights[i]);
      }'''
text = flexible_replace(text, old1, new1, "Generalized dedup suppression")

# 2. Match-to-Match Consistency: zero-switch special states
old2 = '''final ratio = switches / (sample.length - 1);
      final timeWord = switches == 1 ? "time" : "times";
      String consBody = "Across your last ${sample.length} matches, your results switched between a win and a loss $switches $timeWord.";
      if (ratio > 0.55) {
        consBody += " Results can vary for many reasons, including opponent level, match setting and preparation. Every match you log adds another piece to the picture, helping you understand your game with greater confidence.";
      }'''
new2 = '''final ratio = switches / (sample.length - 1);
      final timeWord = switches == 1 ? "time" : "times";
      String consBody;
      if (switches == 0) {
        final allWon = _matchWinner(sample[0]) == "player";
        if (allWon) {
          consBody = "Your recent results have been highly consistent — your last ${sample.length} matches were all wins.";
        } else {
          consBody = "Your last ${sample.length} matches have all ended in losses. That's a clear recent pattern, and your next few matches will help show how it develops.";
        }
      } else {
        consBody = "Across your last ${sample.length} matches, your results switched between a win and a loss $switches $timeWord.";
        if (ratio > 0.55) {
          consBody += " Results can vary for many reasons, including opponent level, match setting and preparation. Every match you log adds another piece to the picture, helping you understand your game with greater confidence.";
        }
      }'''
text = flexible_replace(text, old2, new2, "Match-to-Match Consistency zero-switch states")

# 3. Results After Winning Game 1: icon swap
old3 = '''insights.add({"icon": "😤", "title": "Results After Winning Game 1", "body": closeBody, "tier": "pro"});'''
new3 = '''insights.add({"icon": "🔒", "title": "Results After Winning Game 1", "body": closeBody, "tier": "pro"});'''
text = flexible_replace(text, old3, new3, "Results After Winning Game 1 icon")

# 4. Recent vs Earlier Form: exact-equality branch
old4 = '''final recentRate = recentMatches.where((m) => _matchWinner(m) == "player").length / recentMatches.length;
      final earlyRate = earlierMatches.where((m) => _matchWinner(m) == "player").length / earlierMatches.length;
      final trendDiff = recentRate - earlyRate;
      final recentPct = (recentRate * 100).round();
      final earlyPct = (earlyRate * 100).round();
      String trendBody = "Your win rate over your last 5 matches is $recentPct%, compared with $earlyPct% in the 5 matches before that.";
      if (trendDiff >= 0.2) {
        trendBody += " That's a noticeable positive shift in your recent results. Keep tracking to see if the trend continues.";
      } else if (trendDiff <= -0.2) {
        trendBody += " That's a noticeable change in your recent results. Your next few matches will help show whether it's a short-term dip or a developing trend.";
      }'''
new4 = '''final recentWins = recentMatches.where((m) => _matchWinner(m) == "player").length;
      final earlyWins = earlierMatches.where((m) => _matchWinner(m) == "player").length;
      final recentRate = recentWins / recentMatches.length;
      final earlyRate = earlyWins / earlierMatches.length;
      final trendDiff = recentRate - earlyRate;
      final recentPct = (recentRate * 100).round();
      final earlyPct = (earlyRate * 100).round();
      String trendBody;
      if (recentPct == earlyPct) {
        if (recentWins == 5) {
          trendBody = "Your recent form has held steady — you won all 5 of your latest matches and all 5 of the 5 before that.";
        } else if (recentWins == 0) {
          trendBody = "Your recent form has held steady — you lost all 5 of your latest matches and all 5 of the 5 before that. Worth reflecting on what's consistent across these results and choosing one area to focus on.";
        } else {
          trendBody = "Your recent form has held steady, winning $recentWins of your last 5 matches and $recentWins of the 5 before that.";
        }
      } else {
        trendBody = "Your win rate over your last 5 matches is $recentPct%, compared with $earlyPct% in the 5 matches before that.";
        if (trendDiff >= 0.2) {
          trendBody += " That's a noticeable positive shift in your recent results. Keep tracking to see if the trend continues.";
        } else if (trendDiff <= -0.2) {
          trendBody += " That's a noticeable change in your recent results. Your next few matches will help show whether it's a short-term dip or a developing trend.";
        }
      }'''
text = flexible_replace(text, old4, new4, "Recent vs Earlier Form equality branch")

with open(path, "w", encoding="utf-8") as f:
    f.write(text)

print("All 4 edits applied successfully.")
