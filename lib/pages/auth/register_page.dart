import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/auth/firebase_auth/email_auth.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  static String routeName = 'RegisterPage';
  static String routePath = '/register';

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _ageConfirmed = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMessage = null; });
    try {
      await registerWithEmail(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) context.goNamed(HomePageWidget.routeName);
    } on Exception catch (e) {
      setState(() { _errorMessage = _friendlyError(e.toString()); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() { _loading = true; _errorMessage = null; });
    try {
      await signInAsGuest();
      if (mounted) context.goNamed(HomePageWidget.routeName);
    } on Exception catch (e) {
      setState(() { _errorMessage = _friendlyError(e.toString()); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String e) {
    if (e.contains('email-already-in-use')) return 'An account with this email already exists.';
    if (e.contains('invalid-email')) return 'Please enter a valid email address.';
    if (e.contains('weak-password')) return 'Password must be at least 6 characters.';
    if (e.contains('network-request-failed')) return 'No internet connection. Please try again.';
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final primary = FlutterFlowTheme.of(context).primary;

    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Row(
                  children: [
                    const Text('🏸', style: TextStyle(fontSize: 32)),
                    const SizedBox(width: 10),
                    Text('MatchPoint Coach',
                        style: GoogleFonts.interTight(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: primary)),
                  ],
                ),
                const SizedBox(height: 32),
                Text('Create your account',
                    style: GoogleFonts.interTight(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800)),
                const SizedBox(height: 8),
                Text('Track your badminton journey',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                const SizedBox(height: 32),

                // Name field
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
                  decoration: _inputDecoration('Full name', Icons.person_outline),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 16),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
                  decoration: _inputDecoration('Email address', Icons.email_outlined),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter your email';
                    if (!v.contains('@') || !v.contains('.')) return 'Please enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
                  decoration: _inputDecoration('Password', Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey.shade400),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter a password';
                    if (v.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Error message
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

                // Age confirmation checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _ageConfirmed,
                      onChanged: (val) => setState(() => _ageConfirmed = val ?? false),
                      activeColor: primary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 11),
                        child: Text(
                          'I confirm I am 13 or older, or a parent/guardian creating this account',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Create account button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (_loading || !_ageConfirmed) ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : Text('Create Account',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),

                // Guest button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _loading ? null : _continueAsGuest,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Continue as Guest',
                        style: GoogleFonts.inter(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text('Guest data is stored on this device only',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                ),
                const SizedBox(height: 32),

                // Already have account
                Center(
                  child: GestureDetector(
                    onTap: () => context.pushNamed(LoginPage.routeName),
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                        children: [
                          TextSpan(
                            text: 'Log in',
                            style: TextStyle(
                                color: primary,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      filled: true,
      fillColor: FlutterFlowTheme.of(context).secondaryBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
