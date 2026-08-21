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

# 1. Mood & Performance: remove empty-state else branch (hide until qualified)
old1 = '''if (bestMood != null) {
        final pct = (bestRate * 100).round();
        final moodBody = "Your strongest results have come in matches where you recorded feeling $bestMood, winning $pct% of your $bestTotal matches recorded in that mood. Think about what else was consistent before those matches, such as your preparation, warm-up or match routine. The goal isn't to recreate a feeling, but to build routines that help you perform at your best.";
        insights.add({"icon": "🧠", "title": "Mood & Performance", "body": moodBody, "tier": "free"});
        if (worstMoodFree != null && worstMoodFree != bestMood && worstRateFree < winRate) {
          insights.add({"icon": "⚡", "title": "Mood to Watch", "body": "Your results have been less successful in matches where you recorded feeling $worstMoodFree. This is worth reflecting on—not because the mood caused the result, but because it may highlight something in your preparation, routines or mindset that you can strengthen.", "tier": "free"});
        }
      } else {
        insights.add({"icon": "🧠", "title": "Mood & Performance", "body": "We need at least 5 matches recorded in the same mood before we can identify a meaningful pattern. Keep logging your pre-match mood to unlock this insight.", "tier": "free"});
      }'''
new1 = '''if (bestMood != null) {
        final pct = (bestRate * 100).round();
        final moodBody = "Your strongest results have come in matches where you recorded feeling $bestMood, winning $pct% of your $bestTotal matches recorded in that mood. Think about what else was consistent before those matches, such as your preparation, warm-up or match routine. The goal isn't to recreate a feeling, but to build routines that help you perform at your best.";
        insights.add({"icon": "🧠", "title": "Mood & Performance", "body": moodBody, "tier": "free"});
        if (worstMoodFree != null && worstMoodFree != bestMood && worstRateFree < winRate) {
          insights.add({"icon": "⚡", "title": "Mood to Watch", "body": "Your results have been less successful in matches where you recorded feeling $worstMoodFree. This is worth reflecting on—not because the mood caused the result, but because it may highlight something in your preparation, routines or mindset that you can strengthen.", "tier": "free"});
        }
      }'''
text = flexible_replace(text, old1, new1, "Mood & Performance hide empty state")

# 2. Match Frequency: rewrite lower tiers to remove prescriptive/unsupported claims
old2 = '''if (last30 >= 6) {
        freqBody = "You have played $last30 matches in the last 30 days. You have been competing regularly and building a useful record of your recent performances.";
      } else if (last30 >= 4) {
        freqBody = "You have played $last30 matches in the last 30 days. Good consistency. Regular play like this helps you build and maintain your level.";
      } else if (last30 >= 2) {
        freqBody = "You have played $last30 matches in the last 30 days. A steady start. Try to increase your frequency to keep your game sharp.";
      } else if (last30 == 1) {
        freqBody = "You have played 1 match in the last 30 days. Playing more regularly will help you improve faster. Even one extra match per week can make a difference.";
      } else {
        freqBody = "No matches recorded in the last 30 days. Getting back on court is the most important step to improving your game.";
      }'''
new2 = '''if (last30 >= 6) {
        freqBody = "You have played $last30 matches in the last 30 days. You have been competing regularly and building a useful record of your recent performances.";
      } else if (last30 >= 4) {
        freqBody = "You have played $last30 matches in the last 30 days — a solid recent sample for your AI Coach to work with.";
      } else if (last30 >= 2) {
        freqBody = "You have played $last30 matches in the last 30 days. Every match you log adds to what your AI Coach can tell you.";
      } else if (last30 == 1) {
        freqBody = "You have played 1 match in the last 30 days.";
      } else {
        freqBody = "No matches recorded in the last 30 days.";
      }'''
text = flexible_replace(text, old2, new2, "Match Frequency tier rewrite")

# 3. Locked-card headline
old3 = '''Text("See exactly why you win and lose", style: GoogleFonts.interTight(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),'''
new3 = '''Text("Discover the patterns behind your performance", style: GoogleFonts.interTight(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),'''
text = flexible_replace(text, old3, new3, "Locked-card headline")

# 4. Locked-card subline
old4 = '''child: Text("Most players never realise this about their game", style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11, fontStyle: FontStyle.italic)),'''
new4 = '''child: Text("Your match data can reveal patterns that are easy to miss", style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11, fontStyle: FontStyle.italic)),'''
text = flexible_replace(text, old4, new4, "Locked-card subline")

with open(path, "w", encoding="utf-8") as f:
    f.write(text)

print("All 4 edits applied successfully.")
