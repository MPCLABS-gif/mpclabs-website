import 'package:flutter/material.dart';
import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';

import '/backend/schema/matches_record.dart';
import '/services/premium_service.dart';

class PremiumWidget extends StatefulWidget {
  const PremiumWidget({super.key, this.initialTier = 'premium'});

  static String routeName = 'PremiumWidget';
  static String routePath = '/premiumWidget';

  final String initialTier;

  @override
  State<PremiumWidget> createState() => _PremiumWidgetState();
}

class _PremiumWidgetState extends State<PremiumWidget>
    with SingleTickerProviderStateMixin {
  late String _selectedTier;
  bool _isYearly = false;
  bool _isLoading = false;
  bool _isRestoring = false;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _heroFade;
  late Animation<double> _ctaFade;

  final TextEditingController _referralController = TextEditingController();
  bool _showReferralField = false;
  bool _referralApplied = false;
  String? _referralError;
  double _discountPercent = 0;

  int _totalMatches = 0;
  String _blurredStat1 = '';
  String _blurredStat2 = '';
  String _blurredStat3 = '';

  @override
  void initState() {
    super.initState();
    _selectedTier = widget.initialTier;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _heroFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _ctaFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _animController.forward();
    });
    _loadMatchData();
  }

  @override
  void dispose() {
    _animController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _loadMatchData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('matches')
          .where('ownerUid', isEqualTo: user.uid)
          .get();
      final matches =
          snapshot.docs.map((d) => MatchesRecord.fromSnapshot(d)).toList();
      final total = matches.length;
      String stat1 = '', stat2 = '', stat3 = '';
      if (total >= 5) {
        int slowStarts = 0;
        for (final m in matches) {
          if (m.g1Opponent > m.g1Player && m.g1Opponent - m.g1Player >= 5) {
            slowStarts++;
          }
        }
        final slowPct = ((slowStarts / total) * 100).round();
        stat1 = slowPct == 0 ? 'No slow starts detected — you begin matches well' : 'You start slow in $slowPct% of your matches';

        final tiredMatches =
            matches.where((m) => m.mood?.toLowerCase() == 'tired').toList();
        if (tiredMatches.isNotEmpty) {
          final tiredWins =
              tiredMatches.where((m) => _matchWinner(m) == 'player').length;
          final tiredWinRate =
              ((tiredWins / tiredMatches.length) * 100).round();
          stat2 = 'When Tired, your win rate drops to $tiredWinRate%';
        } else {
          stat2 = 'Mood tracking reveals hidden win patterns';
        }

        final ledThenLost = matches
            .where((m) =>
                m.g1Player > m.g1Opponent && _matchWinner(m) == 'opponent')
            .length;
        if (ledThenLost > 0) {
          final plural = ledThenLost == 1 ? 'match' : 'matches';
          stat3 = 'You led then lost in $ledThenLost $plural';
        } else {
          stat3 = 'Your closing rate tells a story';
        }
      } else {
        final remaining = 5 - total;
        final plural = remaining == 1 ? 'match' : 'matches';
        stat1 = 'Play $remaining more $plural to unlock your report';
        stat2 = 'Hidden win patterns waiting to be revealed';
        stat3 = 'Your coaching report is almost ready';
      }
      if (mounted) {
        setState(() {
          _totalMatches = total;
          _blurredStat1 = stat1;
          _blurredStat2 = stat2;
          _blurredStat3 = stat3;
        });
      }
    } catch (e) {
      // Silent fail
    }
  }

  String _matchWinner(MatchesRecord m) {
    int pg = 0, og = 0;
    final int ws = int.tryParse(m.scoringFormat) ?? 21;
    void count(int p, int o) {
      if (p == 0 && o == 0) return;
      if (p >= ws || p > o) {
        pg++;
      } else {
        og++;
      }
    }
    count(m.g1Player, m.g1Opponent);
    count(m.g2Player, m.g2Opponent);
    count(m.g3Player, m.g3Opponent);
    return pg > og ? 'player' : 'opponent';
  }

  Future<void> _purchase(String productId) async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) throw Exception('No offerings');
      Package? package;
      for (final pkg in current.availablePackages) {
        if (pkg.storeProduct.identifier == productId) {
          package = pkg;
          break;
        }
      }
      if (package == null) throw Exception('Product not found');
      await Purchases.purchasePackage(package);
      if (mounted) Navigator.of(context).pop(true);
    } on PurchasesErrorCode catch (e) {
      if (e != PurchasesErrorCode.purchaseCancelledError) {
        setState(() => _errorMessage = 'Purchase failed. Please try again.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restorePurchases() async {
    setState(() { _isRestoring = true; _errorMessage = null; });
    try {
      final info = await Purchases.restorePurchases();
      if (mounted) {
        if (info.entitlements.active.containsKey('pro') ||
            info.entitlements.active.containsKey('premium')) {
          Navigator.of(context).pop(true);
        } else {
          setState(() =>
              _errorMessage = 'No active subscription found to restore.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Restore failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  Future<void> _applyReferral() async {
    final code = _referralController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() => _referralError = null);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('referral_codes')
          .doc(code)
          .get();
      if (!doc.exists) {
        setState(() => _referralError = 'Invalid code. Please check and try again.');
        return;
      }
      final data = doc.data()!;
      if (!(data['active'] as bool? ?? false)) {
        setState(() => _referralError = 'This code has expired.');
        return;
      }
      final maxUses = (data['maxUses'] as num?)?.toInt() ?? 0;
      final usedCount = (data['usedCount'] as num?)?.toInt() ?? 0;
      if (maxUses > 0 && usedCount >= maxUses) {
        setState(() => _referralError = 'This code has reached its maximum uses.');
        return;
      }
      final tier = (data['tier'] as String?) ?? 'any';
      if (tier != 'any' && tier != _selectedTier) {
        setState(() => _referralError = 'This code is only valid for ${tier == 'pro' ? 'Pro' : 'Premium'} plans.');
        return;
      }
      final discount = (data['discountPercent'] as num?)?.toDouble() ?? 0;
      await FirebaseFirestore.instance
          .collection('referral_codes')
          .doc(code)
          .update({'usedCount': usedCount + 1});
      setState(() {
        _referralApplied = true;
        _discountPercent = discount;
        _referralError = null;
      });
    } catch (e) {
      setState(() => _referralError = 'Could not apply code. Please try again.');
    }
  }

  double _applyDiscount(double price) =>
      _discountPercent > 0 ? price * (1 - _discountPercent / 100) : price;

  String _fmtPrice(double price) =>
      '£${_applyDiscount(price).toStringAsFixed(2)}';

  String _currentProductId() {
    if (_selectedTier == 'pro') {
      return _isYearly ? PremiumService.proYearlyId : PremiumService.proMonthlyId;
    }
    return _isYearly
        ? PremiumService.premiumYearlyId
        : PremiumService.premiumMonthlyId;
  }

  String _currentPrice() {
    if (_selectedTier == 'pro') {
      return _isYearly
          ? '${_fmtPrice(24.99)}/year'
          : '${_fmtPrice(3.99)}/month';
    }
    return _isYearly
        ? '${_fmtPrice(49.99)}/year'
        : '${_fmtPrice(7.99)}/month';
  }

  String _ctaLabel() =>
      _selectedTier == 'pro' ? 'Unlock Pro coaching' : 'Unlock Premium coaching';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d0d0d),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: FadeTransition(
              opacity: _heroFade,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeroHeader(),
                  _buildBlurredPreview(),
                  _buildTierSelector(),
                  if (_totalMatches >= 5) _buildTriggerBanner(),
                  FadeTransition(
                    opacity: _ctaFade,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildBillingToggle(),
                        _buildCTASection(),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading || _isRestoring)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Color(0xFF7B2FBE)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      color: const Color(0xFF1a0a2e),
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            GestureDetector(
              onTap: () { if (Navigator.of(context).canPop()) { Navigator.of(context).pop(); } else { context.go('/'); } },
              child: const Icon(Icons.close, color: Colors.white54, size: 24),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'UPGRADE',
                style: TextStyle(
                  color: Color(0xFF1a0a2e),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          const Text(
            'Understand exactly\nwhy you win and lose',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'AI-powered coaching based on your match data',
            style: TextStyle(color: Colors.white60, fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurredPreview() {
    return Container(
      color: const Color(0xFF1a0a2e),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR INSIGHTS',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Colors.white, Colors.transparent],
              stops: [0.6, 1.0],
            ).createShader(b),
            blendMode: BlendMode.dstIn,
            child: _buildInsightRow(
              _blurredStat1.isNotEmpty
                  ? _blurredStat1
                  : 'Play more matches to reveal this insight',
              Icons.trending_down,
              const Color(0xFFFF6B6B),
            ),
          ),
          const SizedBox(height: 8),
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: _buildInsightRow(
              _blurredStat2.isNotEmpty ? _blurredStat2 : 'Mood pattern hidden',
              Icons.mood,
              const Color(0xFFFFD700),
            ),
          ),
          const SizedBox(height: 8),
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: _buildInsightRow(
              _blurredStat3.isNotEmpty
                  ? _blurredStat3
                  : 'Closing pattern hidden',
              Icons.analytics,
              const Color(0xFF4FC3F7),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Most players never realise this about their game',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white38,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String text, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
        ),
      ]),
    );
  }

  Widget _buildTierSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What you get for free',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                _buildFreeBullet('Match tracking'),
                _buildFreeBullet('Core performance analytics'),
                _buildFreeBullet('5 AI insights'),
              ],
            ),
          ),
          const Text(
            'CHOOSE YOUR PLAN',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildTierCard(
            tier: 'pro',
            badge: 'PRO',
            badgeColor: const Color(0xFF4FC3F7),
            title: 'Pro Coach',
            subtitle: '13 personalised insights',
            bullets: [
              'Danger Mood analysis',
              'Tournament vs Practice breakdown',
              'Rival & format strengths',
              'Comeback & closing patterns',
            ],
          ),
          const SizedBox(height: 12),
          _buildTierCard(
            tier: 'premium',
            badge: 'PREMIUM',
            badgeColor: const Color(0xFFFFD700),
            title: 'Premium Coach',
            subtitle: 'All 21 insights + Weekly AI Report',
            bullets: [
              'Everything in Pro',
              'Game-by-game breakdown',
              'Improving trend & recent form',
              'Weekly AI coaching report',
              '* Unlocks after free trial',
            ],
            isRecommended: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFreeBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check, color: Colors.white30, size: 13),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard({
    required String tier,
    required String badge,
    required Color badgeColor,
    required String title,
    required String subtitle,
    required List<String> bullets,
    bool isRecommended = false,
  }) {
    final isSelected = _selectedTier == tier;
    final borderColor = isSelected
        ? const Color(0xFF7B2FBE)
        : Colors.white.withOpacity(0.12);
    final bgColor = isSelected
        ? const Color(0xFF1a0a2e)
        : Colors.white.withOpacity(0.04);
    final borderWidth = isSelected ? 2.5 : 1.0;

    return GestureDetector(
      onTap: () => setState(() => _selectedTier = tier),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF7B2FBE).withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Color(0xFF1a0a2e),
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              if (isRecommended) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B2FBE).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF7B2FBE).withOpacity(0.5)),
                  ),
                  child: const Text(
                    'MOST POPULAR',
                    style: TextStyle(
                      color: Color(0xFFB57BFF),
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (isSelected)
                const Icon(Icons.check_circle,
                    color: Color(0xFF7B2FBE), size: 22),
            ]),
            const SizedBox(height: 10),
            Text(title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.w800,
                  fontSize: isRecommended ? 18 : 16,
                )),
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(
                  color: isSelected ? Colors.white60 : Colors.white38,
                  fontSize: 13,
                )),
            const SizedBox(height: 12),
            ...bullets.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check,
                          color: isSelected
                              ? const Color(0xFF7B2FBE)
                              : Colors.white30,
                          size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(b,
                            style: TextStyle(
                              color:
                                  isSelected ? Colors.white70 : Colors.white38,
                              fontSize: 13,
                            )),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTriggerBanner() {
    final plural = _totalMatches == 1 ? 'match' : 'matches';
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            "You've played $_totalMatches $plural — your first coaching report is ready",
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildBillingToggle() {
    final proMonthly = _fmtPrice(3.99);
    final proYearly = _fmtPrice(24.99);
    final premMonthly = _fmtPrice(7.99);
    final premYearly = _fmtPrice(49.99);
    final monthlyLabel =
        _selectedTier == 'pro' ? '$proMonthly/month' : '$premMonthly/month';
    final yearlyLabel =
        _selectedTier == 'pro' ? '$proYearly/year' : '$premYearly/year';
    final savingLabel =
        _selectedTier == 'pro' ? 'SAVE 48% (£2.08/mo)' : 'SAVE 48% (£4.17/mo)';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Start improving your game today',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isYearly = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: !_isYearly
                          ? const Color(0xFF7B2FBE)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(children: [
                      Text('Monthly',
                          style: TextStyle(
                            color:
                                !_isYearly ? Colors.white : Colors.white54,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          )),
                      Text(monthlyLabel,
                          style: TextStyle(
                            color:
                                !_isYearly ? Colors.white70 : Colors.white38,
                            fontSize: 12,
                          )),
                    ]),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isYearly = true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _isYearly
                          ? const Color(0xFF7B2FBE)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Yearly',
                              style: TextStyle(
                                color: _isYearly
                                    ? Colors.white
                                    : Colors.white54,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              )),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              savingLabel,
                              style: const TextStyle(
                                color: Color(0xFF1a0a2e),
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(yearlyLabel,
                          style: TextStyle(
                            color:
                                _isYearly ? Colors.white70 : Colors.white38,
                            fontSize: 12,
                          )),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildCTASection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(children: [
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(_errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _purchase(_currentProductId()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B2FBE),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 4,
            ),
            child: Text(
              _ctaLabel(),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          Platform.isIOS ? '3-day free trial • Cancel anytime' : '5-day free trial • Cancel anytime',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ]),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(children: [
        GestureDetector(
          onTap: () =>
              setState(() => _showReferralField = !_showReferralField),
          child: const Text(
            'Have a promo or referral code?',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 13,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white38,
            ),
          ),
        ),
        if (_showReferralField) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _referralController,
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Enter code',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _referralApplied ? null : _applyReferral,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B2FBE),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                _referralApplied ? '✓ Applied' : 'Apply',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ]),
          if (_referralError != null) ...[
            const SizedBox(height: 8),
            Text(_referralError!,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
          if (_referralApplied) ...[
            const SizedBox(height: 8),
            Text(
              '${_discountPercent.round()}% discount applied!',
              style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ],
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _isRestoring ? null : _restorePurchases,
          child: Text(
            _isRestoring ? 'Restoring…' : 'Restore purchases',
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Subscriptions auto-renew unless cancelled 24 hours before the end of the current period. Manage in your device settings.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white24, fontSize: 11, height: 1.5),
        ),
      ]),
    );
  }
}
