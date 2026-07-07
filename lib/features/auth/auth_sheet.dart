import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../services/firebase/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/bw_button.dart';
import '../../widgets/section_header.dart';

/// Opens the account sheet. Returns true once the user is a real member.
Future<bool> presentAuthSheet(
  BuildContext context, {
  String? reason,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.paper,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(),
    builder: (_) => _AuthSheet(reason: reason),
  );
  return result == true || AuthService.instance.isMember;
}

class _AuthSheet extends StatefulWidget {
  const _AuthSheet({this.reason});
  final String? reason;

  @override
  State<_AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<_AuthSheet> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _humanize(e);
        });
      }
    }
  }

  String _humanize(Object e) {
    final s = e.toString();
    if (s.contains('coming-soon:google')) {
      return 'Google sign-in is coming soon — use Apple or email for now.';
    }
    if (s.contains('wrong-password') || s.contains('invalid-credential')) {
      return 'That email or password didn’t match.';
    }
    if (s.contains('email-already-in-use')) {
      return 'That email already has an account — try signing in.';
    }
    if (s.contains('weak-password')) return 'Choose a stronger password.';
    if (s.contains('invalid-email')) return 'That email doesn’t look right.';
    if (s.contains('network')) return 'Network trouble — try again.';
    return 'Something went wrong. Please try again.';
  }

  Future<void> _email_() async {
    final auth = AuthService.instance;
    if (_register) {
      await auth.registerWithEmail(
        email: _email.text.trim(),
        password: _password.text,
        name: _name.text.trim().isEmpty ? 'Friend in Christ' : _name.text.trim(),
      );
    } else {
      await auth.signInWithEmail(
        email: _email.text.trim(),
        password: _password.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.ink, width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              eyebrow: 'Join the Table',
              title: _register ? 'Create Your Account' : 'Welcome Back',
              subline: widget.reason ?? 'Save your journey and join the community.',
              titleSize: 24,
            ),
            const SizedBox(height: 18),
            if (Platform.isIOS) ...[
              _ProviderButton(
                label: 'Continue with Apple',
                icon: PhosphorIconsRegular.appleLogo,
                onTap: _busy ? null : () => _run(AuthService.instance.signInWithApple),
              ),
              const SizedBox(height: 10),
            ],
            _ProviderButton(
              label: 'Continue with Google',
              icon: PhosphorIconsRegular.googleLogo,
              onTap: _busy ? null : () => _run(AuthService.instance.signInWithGoogle),
            ),
            const SizedBox(height: 16),
            const RuleLabel('or with email'),
            const SizedBox(height: 16),
            if (_register) ...[
              _field(_name, 'Your name', cap: 60),
              const SizedBox(height: 10),
            ],
            _field(_email, 'Email',
                keyboard: TextInputType.emailAddress, cap: 120),
            const SizedBox(height: 10),
            _field(_password, 'Password', obscure: true, cap: 80),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: AppType.flourish(15, color: AppColors.accent)),
            ],
            const SizedBox(height: 16),
            BwButton(
              label: _busy
                  ? 'One moment…'
                  : (_register ? 'Create account' : 'Sign in'),
              expand: true,
              onPressed: _busy ? null : () => _run(_email_),
            ),
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: _busy ? null : () => setState(() => _register = !_register),
                child: Text(
                  (_register
                          ? 'Already have an account? Sign in'
                          : 'New here? Create an account')
                      .toUpperCase(),
                  style: AppType.mono(9, color: AppColors.inkFaded),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String hint, {
    bool obscure = false,
    TextInputType? keyboard,
    int cap = 120,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.ink, width: 1),
        color: AppColors.paperBright,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextField(
        controller: c,
        obscureText: obscure,
        keyboardType: keyboard,
        maxLength: cap,
        cursorColor: AppColors.accent,
        style: AppType.body(16, color: AppColors.ink),
        decoration: InputDecoration(
          border: InputBorder.none,
          counterText: '',
          hintText: hint,
          hintStyle: AppType.flourish(15, color: AppColors.inkGhost),
        ),
      ),
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.ink, width: 1),
          color: AppColors.paperBright,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.ink),
            const SizedBox(width: 10),
            Text(label.toUpperCase(),
                style: AppType.mono(11, color: AppColors.ink,
                    weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
