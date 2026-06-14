import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/club_service.dart';
import '/index.dart';

class CreateClubPage extends StatefulWidget {
  const CreateClubPage({super.key});
  static String routeName = 'CreateClubPage';
  static String routePath = '/createClub';

  @override
  State<CreateClubPage> createState() => _CreateClubPageState();
}

class _CreateClubPageState extends State<CreateClubPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;
  Map<String, dynamic>? _createdClub;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _createClub() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMessage = null; });
    try {
      final club = await ClubService().createClub(
        clubName: _nameController.text.trim(),
        location: _locationController.text.trim(),
      );
      setState(() { _createdClub = club; });
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
        title: Text('Create Club',
            style: GoogleFonts.interTight(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _createdClub != null ? _buildSuccessState(primary) : _buildFormState(primary),
        ),
      ),
    );
  }

  Widget _buildFormState(Color primary) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Set up your club',
              style: GoogleFonts.interTight(fontSize: 24, fontWeight: FontWeight.bold,
                  color: FlutterFlowTheme.of(context).primaryText)),
          const SizedBox(height: 8),
          Text('Players and coaches will join using your club codes.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          const SizedBox(height: 32),
          TextFormField(
            controller: _nameController,
            style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
            decoration: _inputDecoration('Club name', Icons.shield_outlined),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a club name' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _locationController,
            style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
            decoration: _inputDecoration('Location (optional)', Icons.location_on_outlined),
          ),
          const SizedBox(height: 32),
          if (_errorMessage != null) ...[
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
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _createClub,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : Text('Create Club',
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(Color primary) {
    final playerCode = _createdClub!['playerCode'] as String;
    final coachCode = _createdClub!['coachCode'] as String;
    final clubName = _createdClub!['clubName'] as String;

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
              child: Text(clubName,
                  style: GoogleFonts.interTight(fontSize: 22, fontWeight: FontWeight.bold,
                      color: FlutterFlowTheme.of(context).primaryText)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Your club has been created. Share the codes below.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        const SizedBox(height: 32),
        _codeCard(
          title: 'Player code',
          subtitle: 'Share with players so they can join your club.',
          code: playerCode,
          primary: primary,
        ),
        const SizedBox(height: 16),
        _codeCard(
          title: 'Coach code',
          subtitle: 'Share with assistant coaches only.',
          code: coachCode,
          primary: Colors.orange.shade700,
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primary.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Keep your coach code private. Only share it with coaches you trust.',
                  style: TextStyle(fontSize: 13, color: primary.withOpacity(0.8), height: 1.4),
                ),
              ),
            ],
          ),
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
            child: Text('Go to Dashboard',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _codeCard({
    required String title,
    required String subtitle,
    required String code,
    required Color primary,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(code,
                    style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold, color: primary,
                        letterSpacing: 1.5)),
              ),
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$title copied.'), duration: const Duration(seconds: 2)),
                  );
                },
                icon: Icon(Icons.copy, color: Colors.grey.shade400, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary, width: 2),
      ),
      filled: true,
      fillColor: FlutterFlowTheme.of(context).secondaryBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
