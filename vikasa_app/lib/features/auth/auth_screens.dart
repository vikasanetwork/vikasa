import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.child});
  final Widget child;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final StreamSubscription<AuthState> _sub;
  Session? _session = Supabase.maybeGetInstance()?.client.auth.currentSession;

  @override
  void initState() {
    super.initState();
    final supa = Supabase.maybeGetInstance();
    if (supa != null) {
      _sub = supa.client.auth.onAuthStateChange.listen((event) {
        setState(() => _session = event.session);
      });
    } else {
      _sub = const Stream<AuthState>.empty().listen((_) {});
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = _session != null;
    return signedIn ? widget.child : const _AuthLanding();
  }
}

class _AuthLanding extends StatelessWidget {
  const _AuthLanding();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VIKASA – Sign in')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage())),
              child: const Text('Login'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterPage())),
              child: const Text('Create account'),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  Future<void> _login() async {
    setState(() => _busy = true);
    try {
      final supa = Supabase.instance.client;
      final res = await supa.auth.signInWithPassword(email: _email.text.trim(), password: _password.text);
      if (res.session != null) {
        if (!mounted) return;
        Navigator.of(context).pop();
      } else {
        _show('Login failed');
      }
    } catch (e) {
      _show('Error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _busy ? null : _login, child: Text(_busy ? 'Please wait…' : 'Login')),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPasswordPage())),
              child: const Text('Forgot password?'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const RegisterPage())),
              child: const Text('Create a new account'),
            ),
          ],
        ),
      ),
    );
  }

  void _show(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _referral = TextEditingController();
  bool _busy = false;

  Future<void> _register() async {
    setState(() => _busy = true);
    try {
      final supa = Supabase.instance.client;
      final authRes = await supa.auth.signUp(email: _email.text.trim(), password: _password.text);
      final user = authRes.user;
      if (user == null) {
        _show('Signup failed');
        return;
      }

      // Insert profile
      final myReferralCode = await _generateUniqueReferralCode(supa);
      final insertRes = await supa.from('profiles').insert({
        'id': user.id,
        'full_name': _fullName.text.trim(),
        'username': _username.text.trim(),
        'phone': _mobile.text.trim(),
        'referral_code': myReferralCode,
      });
      if (insertRes.error != null) {
        _show('Profile save failed: ${insertRes.error!.message}');
        return;
      }

      // Resolve referred_by: use provided or default from config
      String? code = _referral.text.trim().isNotEmpty ? _referral.text.trim() : await _getDefaultReferralCode(supa);
      if (code != null && code.isNotEmpty) {
        final ref = await supa.from('profiles').select('id').eq('referral_code', code).maybeSingle();
        if (ref != null && ref['id'] != null) {
          await supa.from('profiles').update({'referred_by': ref['id']}).eq('id', user.id);
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      _show('Signup complete. Check your email for verification link.');
    } catch (e) {
      _show('Error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String> _generateUniqueReferralCode(SupabaseClient supa) async {
    String code;
    int attempts = 0;
    do {
      attempts++;
      code = _randomCode(8);
      final existing = await supa.from('profiles').select('id').eq('referral_code', code).maybeSingle();
      if (existing == null) break;
    } while (attempts < 5);
    return code;
  }

  String _randomCode(int length) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final now = DateTime.now().microsecondsSinceEpoch;
    int x = now;
    final buf = StringBuffer();
    for (int i = 0; i < length; i++) {
      x = (x * 1103515245 + 12345) & 0x7fffffff;
      buf.write(chars[x % chars.length]);
    }
    return buf.toString();
  }

  Future<String?> _getDefaultReferralCode(SupabaseClient supa) async {
    final row = await supa.from('config').select('value').eq('key', 'default_referral_code').maybeSingle();
    if (row != null && row['value'] != null) {
      final v = row['value'];
      // value is JSON: {"value":"VIKASA2025"}
      return v['value'] as String?;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _fullName, decoration: const InputDecoration(labelText: 'Full Name')),
            const SizedBox(height: 12),
            TextField(controller: _username, decoration: const InputDecoration(labelText: 'Username')),
            const SizedBox(height: 12),
            TextField(controller: _mobile, decoration: const InputDecoration(labelText: 'Mobile Number')),
            const SizedBox(height: 12),
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 12),
            TextField(controller: _referral, decoration: const InputDecoration(labelText: 'Referral ID (optional)')),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _busy ? null : _register, child: Text(_busy ? 'Please wait…' : 'Create account')),
          ],
        ),
      ),
    );
  }

  void _show(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _email = TextEditingController();
  bool _busy = false;

  Future<void> _reset() async {
    setState(() => _busy = true);
    try {
      final supa = Supabase.instance.client;
      await supa.auth.resetPasswordForEmail(_email.text.trim());
      _show('Reset link sent if the email exists.');
    } catch (e) {
      _show('Error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _busy ? null : _reset, child: Text(_busy ? 'Please wait…' : 'Send reset email')),
        ]),
      ),
    );
  }

  void _show(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}
