import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_messenger.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegistering = false;
  bool _isBusy = false;
  bool _verificationPending = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  FirebaseAuth get _auth => FirebaseAuth.instance;

  Future<void> _syncUserProfile(User user) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final existing = await ref.get();
    if (existing.exists && existing.data()?['status'] == 'suspended') {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'account-suspended',
        message: 'บัญชีนี้ถูกระงับการใช้งาน กรุณาติดต่อผู้ดูแลระบบ',
      );
    }
    final profile = <String, dynamic>{
      'email': user.email,
      'displayName': user.displayName,
      'lastSeenAt': FieldValue.serverTimestamp(),
    };
    if (existing.exists) {
      await ref.set(profile, SetOptions(merge: true));
    } else {
      await ref.set({
        ...profile,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  String _authError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'อีเมลนี้มีบัญชีอยู่แล้ว กรุณาเข้าสู่ระบบ';
      case 'invalid-email':
        return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'weak-password':
        return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
      case 'too-many-requests':
        return 'มีการลองหลายครั้งเกินไป กรุณารอสักครู่';
      case 'network-request-failed':
        return 'เชื่อมต่ออินเทอร์เน็ตไม่ได้ กรุณาลองใหม่';
      case 'operation-not-allowed':
        return 'Firebase ยังไม่ได้เปิดใช้ Email/Password';
      case 'account-suspended':
        return 'บัญชีนี้ถูกระงับการใช้งาน กรุณาติดต่อผู้ดูแลระบบ';
      default:
        return 'ดำเนินการไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isBusy = true;
      _message = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      if (_isRegistering) {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        // Create the Firestore member profile only after email verification,
        // when the user signs in successfully. Registration should not fail
        // because a profile write is unavailable before verification.
        await credential.user?.sendEmailVerification();
        if (mounted) {
          setState(() {
            _verificationPending = true;
            _message = 'ส่งลิงก์ยืนยันไปที่ $email แล้ว กรุณาเปิดอีเมลเพื่อยืนยันบัญชี';
          });
        }
      } else {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        await credential.user?.reload();
        final user = _auth.currentUser;
        if (user != null && !user.emailVerified) {
          if (mounted) {
            setState(() {
              _verificationPending = true;
              _message = 'บัญชีนี้ยังไม่ได้ยืนยันอีเมล กรุณาตรวจสอบกล่องจดหมาย';
            });
          }
        } else if (mounted) {
          if (user != null) await _syncUserProfile(user);
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
            (route) => false,
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showAuthPopup('เข้าสู่ระบบสำเร็จ');
          });
        }
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _message = _authError(error));
    } catch (_) {
      if (mounted) setState(() => _message = 'เกิดข้อผิดพลาด กรุณาลองใหม่');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _resendVerification() async {
    setState(() {
      _isBusy = true;
      _message = null;
    });
    try {
      await _auth.currentUser?.sendEmailVerification();
      if (mounted) setState(() => _message = 'ส่งอีเมลยืนยันอีกครั้งแล้ว');
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _message = _authError(error));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _message = 'กรอกอีเมลให้ถูกต้องก่อนขอรีเซ็ตรหัสผ่าน');
      return;
    }
    setState(() {
      _isBusy = true;
      _message = null;
    });
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (mounted) setState(() => _message = 'ส่งลิงก์ตั้งรหัสผ่านใหม่ไปที่ $email แล้ว');
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _message = _authError(error));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _backToSignIn() async {
    await _auth.signOut();
    if (mounted) {
      setState(() {
        _verificationPending = false;
        _isRegistering = false;
        _message = 'ยืนยันอีเมลแล้วจึงเข้าสู่ระบบได้';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_verificationPending ? 'ยืนยันอีเมล' : 'เข้าสู่ระบบ')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          children: [
            const Text(
              'AUVYQORA',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.gold,
                fontSize: 26,
                letterSpacing: 2,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _verificationPending
                  ? 'อีกขั้นตอนเดียวก่อนเริ่มรับชมเรื่องราว'
                  : _isRegistering
                      ? 'สร้างบัญชีเพื่อบันทึกรายการโปรดและประวัติการรับชม'
                      : 'เข้าสู่บัญชี AUVYQORA ของคุณ',
              style: TextStyle(color: Colors.white.withValues(alpha: .72)),
            ),
            const SizedBox(height: 24),
            if (_verificationPending) ...[
              const Icon(Icons.mark_email_unread_outlined, size: 58, color: AppTheme.gold),
              const SizedBox(height: 16),
              const Text(
                'กรุณายืนยันอีเมล',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'เปิดอีเมลจาก Firebase แล้วกดลิงก์ยืนยัน จากนั้นกลับมาเข้าสู่ระบบอีกครั้ง',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isBusy ? null : _resendVerification,
                child: Text(_isBusy ? 'กำลังส่ง...' : 'ส่งอีเมลยืนยันอีกครั้ง'),
              ),
              TextButton(onPressed: _backToSignIn, child: const Text('กลับไปหน้าเข้าสู่ระบบ')),
            ] else ...[
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'อีเมล',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty || !email.contains('@')) return 'กรอกอีเมลให้ถูกต้อง';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(
                        labelText: 'รหัสผ่าน',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        if ((value ?? '').length < 6) return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                        return null;
                      },
                      onFieldSubmitted: (_) => _isBusy ? null : _submit(),
                    ),
                    if (!_isRegistering)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isBusy ? null : _sendPasswordReset,
                          child: const Text('ลืมรหัสผ่าน?'),
                        ),
                      ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _isBusy ? null : _submit,
                      child: Text(
                        _isBusy
                            ? 'กำลังดำเนินการ...'
                            : _isRegistering
                                ? 'สร้างบัญชี'
                                : 'เข้าสู่ระบบบัญชี',
                      ),
                    ),
                    TextButton(
                      onPressed: _isBusy
                          ? null
                          : () => setState(() {
                                _isRegistering = !_isRegistering;
                                _message = null;
                              }),
                      child: Text(
                        _isRegistering
                            ? 'มีบัญชีอยู่แล้ว? เข้าสู่ระบบ'
                            : 'ยังไม่มีบัญชี? สมัครสมาชิก',
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(
                _message!,
                textAlign: TextAlign.center,
                style: TextStyle(color: _message!.contains('แล้ว') ? AppTheme.gold : Colors.orangeAccent),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
