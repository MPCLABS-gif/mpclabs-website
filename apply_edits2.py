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

# 1. Developing Results: remove causal "logging builds results" claim
old1 = '''insights.add({"icon": "💪", "title": "Developing Results", "body": "You are winning ${(winRate * 100).round()}% of your ${completed.length} matches. You're building experience and results with every match you log.", "tier": "free"});'''
new1 = '''insights.add({"icon": "💪", "title": "Developing Results", "body": "You have won ${(winRate * 100).round()}% of your ${completed.length} recorded matches. Every match adds to the picture of your performance and gives you more to learn from.", "tier": "free"});'''
text = flexible_replace(text, old1, new1, "Developing Results wording")

# 2. Merge Mood & Performance + Mood to Watch into one card, same qualification logic
old2 = '''if (bestMood != null) {
        final pct = (bestRate * 100).round();
        final moodBody = "Your strongest results have come in matches where you recorded feeling $bestMood, winning $pct% of your $bestTotal matches recorded in that mood. Think about what else was consistent before those matches, such as your preparation, warm-up or match routine. The goal isn't to recreate a feeling, but to build routines that help you perform at your best.";
        insights.add({"icon": "🧠", "title": "Mood & Performance", "body": moodBody, "tier": "free"});
        if (worstMoodFree != null && worstMoodFree != bestMood && worstRateFree < winRate) {
          insights.add({"icon": "⚡", "title": "Mood to Watch", "body": "Your results have been less successful in matches where you recorded feeling $worstMoodFree. This is worth reflecting on—not because the mood caused the result, but because it may highlight something in your preparation, routines or mindset that you can strengthen.", "tier": "free"});
        }
      }'''
new2 = '''if (bestMood != null) {
        final pct = (bestRate * 100).round();
        String moodBody;
        if (worstMoodFree != null && worstMoodFree != bestMood && worstRateFree < winRate) {
          moodBody = "Your strongest results have come when you recorded feeling $bestMood — winning $pct% of those matches. Your results have been lower when you recorded feeling $worstMoodFree. That doesn't mean either feeling caused the result. Look at what else differed in your preparation, warm-up or routine between the two.";
        } else {
          moodBody = "Your strongest results have come when you recorded feeling $bestMood — winning $pct% of those matches. Rather than trying to recreate a feeling, look for what else was consistent: your preparation, warm-up or routine.";
        }
        insights.add({"icon": "🧠", "title": "Mood & Performance", "body": moodBody, "tier": "free"});
      }'''
text = flexible_replace(text, old2, new2, "Merge Mood & Performance / Mood to Watch")

with open(path, "w", encoding="utf-8") as f:
    f.write(text)

print("Both edits applied successfully.")
