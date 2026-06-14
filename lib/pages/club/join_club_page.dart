import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/club_service.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/index.dart';

class JoinClubPage extends StatefulWidget {
  const JoinClubPage({super.key});
  static String routeName = 'JoinClubPage';
  static String routePath = '/joinClub';

  @override
  State<JoinClubPage> createState() => _JoinClubPageState();
}

class _JoinClubPageState extends State<JoinClubPage> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;
  Map<String, dynamic>? _foundClub;
  String? _joinType;
  bool _joined = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _findClub() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() { _loading = true; _errorMessage = null; _foundClub = null; _joinType = null; });
    try {
      Map<String, dynamic>? club;
      String? joinType;
      club = await ClubService().findClubByPlayerCode(code);
      if (club != null) {
        joinType = 'player';
      } else {
        club = await ClubService().findClubByCoachCode(code);
        if (club != null) joinType = 'coach';
      }
      if (club == null) {
        setState(() { _errorMessage = 'No club found with that code. Please check and try again.'; });
      } else {
        setState(() { _foundClub = club; _joinType = joinType; });
      }
    } catch (e) {
      setState(() { _errorMessage = 'Something went wrong. Please try again.'; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinClub() async {
    if (_foundClub == null || _joinType == null) return;
    setState(() { _loading = true; });
    try {
      if (_joinType == 'player') {
        await ClubService().joinClubAsPlayer(clubId: _foundClub!['clubId']);
      } else {
        await ClubService().joinClubAsCoach(clubId: _foundClub!['clubId']);
      }
      setState(() { _joined = true; });
    } catch (e) {
      setState(() { _errorMessage = 'Something went wrong. Please try again.'; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = FlutterFlowTheme.of(context).primary;

    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Join Club',
            style: GoogleFonts.interTight(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _joined ? _buildSuccessState(primary) : _buildJoinState(primary),
        ),
      ),
    );
  }

  Widget _buildJoinState(Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Enter your club code',
            style: GoogleFonts.interTight(fontSize: 24, fontWeight: FontWeight.bold,
                color: FlutterFlowTheme.of(context).primaryText)),
        const SizedBox(height: 8),
        Text('Ask your coach for the code to join your club.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        const SizedBox(height: 32),
        TextField(
          controller: _codeController,
          textCapitalization: TextCapitalization.characters,
          style: GoogleFonts.inter(
              fontSize: 20, fontWeight: FontWeight.bold,
              color: FlutterFlowTheme.of(context).primaryText, letterSpacing: 1.5),
          decoration: InputDecoration(
            hintText: 'MPC-0000',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 20, letterSpacing: 1.5),
            prefixIcon: Icon(Icons.tag, color: Colors.grey.shade400, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primary, width: 2),
            ),
            filled: true,
            fillColor: FlutterFlowTheme.of(context).secondaryBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (_) => setState(() { _foundClub = null; _errorMessage = null; }),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _loading ? null : _findClub,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : Text('Find Club',
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(_errorMessage!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
          ),
        ],
        if (_foundClub != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: primary.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(Icons.shield_outlined, color: primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_foundClub!['clubName'] ?? '',
                              style: GoogleFonts.interTight(fontSize: 16, fontWeight: FontWeight.bold,
                                  color: FlutterFlowTheme.of(context).primaryText)),
                          if ((_foundClub!['location'] ?? '').isNotEmpty)
                            Text(_foundClub!['location'],
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_joinType == 'player') ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: primary.withOpacity(0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('What your coach will see',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                color: primary, letterSpacing: 0.3)),
                        const SizedBox(height: 8),
                        _consentRow(Icons.person_outline, 'Your name and age group'),
                        _consentRow(Icons.bar_chart, 'Your match results and win rate'),
                        _consentRow(Icons.psychology_outlined, 'Your AI coaching summary'),
                        const SizedBox(height: 8),
                        Text('Your email, phone and personal details are never shared.',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _joinClub,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : Text(
                            _joinType == 'player' ? 'Join Club' : 'Join as Coach',
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _consentRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildSuccessState(Color primary) {
    final isCoach = _joinType == 'coach';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
              child: Icon(Icons.check_circle, color: Colors.green.shade600, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('You have joined ${_foundClub!['clubName']}',
                  style: GoogleFonts.interTight(fontSize: 20, fontWeight: FontWeight.bold,
                      color: FlutterFlowTheme.of(context).primaryText)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          isCoach
              ? 'You now have access to the Coach Dashboard for this club.'
              : 'Your coach can now see your match performance data.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.5),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => context.goNamed(HomePageWidget.routeName),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Go to Home',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }
}
