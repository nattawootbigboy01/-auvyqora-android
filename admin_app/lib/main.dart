import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'content_management.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const AuvyqoraAdminApp());
}

class AdminTheme {
  static const gold = Color(0xFFD6B36A);
  static const burgundy = Color(0xFF5B1728);
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF101014),
        colorScheme: ColorScheme.fromSeed(
          seedColor: burgundy,
          brightness: Brightness.dark,
          primary: gold,
          secondary: burgundy,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF17171D),
          foregroundColor: gold,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1B1B22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Color(0xFF1B1B22),
        ),
      );
}

class AuvyqoraAdminApp extends StatelessWidget {
  const AuvyqoraAdminApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'AUVYQORA ADMIN',
        debugShowCheckedModeBanner: false,
        theme: AdminTheme.dark,
        home: const AdminAuthGate(),
      );
}

class AdminAuthGate extends StatelessWidget {
  const AdminAuthGate({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingPage();
          }
          final user = snapshot.data;
          if (user == null) return const AdminLoginPage();
          return AdminRoleGate(user: user);
        },
      );
}

class AdminRoleGate extends StatefulWidget {
  const AdminRoleGate({required this.user, super.key});
  final User user;

  @override
  State<AdminRoleGate> createState() => _AdminRoleGateState();
}

class _AdminRoleGateState extends State<AdminRoleGate> {
  late Future<bool> _authorization;

  @override
  void initState() {
    super.initState();
    _authorization = _checkAdmin();
  }

  @override
  void didUpdateWidget(covariant AdminRoleGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid) {
      _authorization = _checkAdmin();
    }
  }

  Future<bool> _checkAdmin() async {
    await widget.user.reload();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !user.emailVerified) return false;
    final token = await user.getIdTokenResult(true);
    final claims = token.claims ?? <String, dynamic>{};
    return claims['admin'] == true;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
        future: _authorization,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _LoadingPage();
          }
          if (snapshot.data == true) return const AdminDashboard();
          return const AdminAccessDeniedPage();
        },
      );
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      await result.user?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || !user.emailVerified) {
        await FirebaseAuth.instance.signOut();
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'กรุณายืนยันอีเมลก่อนเข้าสู่ระบบผู้ดูแล',
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _error = e.code == 'email-not-verified'
            ? 'กรุณายืนยันอีเมลก่อนเข้าสู่ระบบ'
            : 'เข้าสู่ระบบไม่สำเร็จ (Firebase: ${e.code})');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'เกิดข้อผิดพลาดในการเชื่อมต่อ: ${e.runtimeType}');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ListView(
                padding: const EdgeInsets.all(24),
                shrinkWrap: true,
                children: [
                  const Icon(Icons.admin_panel_settings_outlined,
                      size: 58, color: AdminTheme.gold),
                  const SizedBox(height: 18),
                  const Text('AUVYQORA ADMIN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AdminTheme.gold,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  const Text('ระบบจัดการแพลตฟอร์มสำหรับผู้ดูแลเท่านั้น',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(
                    'Firebase Project: ${Firebase.apps.isEmpty ? 'ยังไม่เริ่มต้น' : Firebase.app().options.projectId}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .55),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                              labelText: 'อีเมลผู้ดูแล',
                              prefixIcon: Icon(Icons.email_outlined)),
                          validator: (v) =>
                              (v == null || !v.contains('@')) ? 'กรอกอีเมลให้ถูกต้อง' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          obscureText: true,
                          decoration: const InputDecoration(
                              labelText: 'รหัสผ่าน',
                              prefixIcon: Icon(Icons.lock_outline)),
                          validator: (v) =>
                              (v == null || v.length < 6) ? 'กรอกรหัสผ่านอย่างน้อย 6 ตัวอักษร' : null,
                          onFieldSubmitted: (_) => _busy ? null : _signIn(),
                        ),
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: _busy ? null : _signIn,
                          child: Text(_busy ? 'กำลังตรวจสอบ...' : 'เข้าสู่ระบบผู้ดูแล'),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(_error!, textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.orangeAccent)),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}

class AdminAccessDeniedPage extends StatelessWidget {
  const AdminAccessDeniedPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('จำกัดสิทธิ์การใช้งาน')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.gpp_bad_outlined, size: 64, color: Colors.orangeAccent),
              const SizedBox(height: 16),
              const Text('บัญชีนี้ไม่มีสิทธิ์ผู้ดูแล',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'ระบบตรวจไม่พบสิทธิ์ผู้ดูแลที่กำหนดจากฝั่งเซิร์ฟเวอร์ กรุณาใช้บัญชีแอดมินที่ได้รับอนุญาต',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.tonal(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text('ออกจากระบบ'),
              ),
            ]),
          ),
        ),
      );
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selected = 0;
  static const _sections = [
    ('ภาพรวม', Icons.dashboard_outlined),
    ('จัดการละคร', Icons.movie_creation_outlined),
    ('จัดการตอน', Icons.video_library_outlined),
    ('สมาชิก', Icons.people_outline),
    ('รายงาน', Icons.analytics_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final title = _sections[_selected].$1;
    return Scaffold(
      appBar: AppBar(
        title: Text('AUVYQORA ADMIN • $title',
            maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'ออกจากระบบ',
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: _selected == 0
            ? _overview()
            : _selected == 1
                ? ManageDramasPage()
                : _selected == 2
                    ? const ManageEpisodesPage()
                    : _selected == 3
                        ? const ManageMembersPage()
                        : _sectionPlaceholder(title),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selected,
        onDestinationSelected: (index) => setState(() => _selected = index),
        destinations: [
          for (final section in _sections)
            NavigationDestination(
              icon: Icon(section.$2),
              label: section.$1,
            ),
        ],
      ),
    );
  }

  Widget _overview() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('dramas').snapshots(),
        builder: (context, dramaSnapshot) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, userSnapshot) {
              final dramaCount = dramaSnapshot.data?.docs.length;
              final userCount = userSnapshot.data?.docs.length;
              final publishedCount = dramaSnapshot.data?.docs
                      .where((doc) => doc.data()['status'] == 'published')
                      .length;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('ศูนย์ควบคุมแพลตฟอร์ม',
                      style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('ข้อมูลจาก Cloud Firestore แบบเรียลไทม์',
                      style: TextStyle(color: Colors.white.withValues(alpha: .7))),
                  const SizedBox(height: 18),
                  _MetricCard(
                    icon: Icons.movie_outlined,
                    title: 'ละครทั้งหมด',
                    value: dramaSnapshot.hasError ? 'โหลดไม่สำเร็จ' : dramaCount?.toString() ?? 'กำลังโหลด',
                    note: dramaSnapshot.hasError ? 'ตรวจสอบ Firestore Rules' : 'เผยแพร่แล้ว ${publishedCount ?? 0} เรื่อง',
                  ),
                  _MetricCard(
                    icon: Icons.people_outline,
                    title: 'สมาชิก',
                    value: userSnapshot.hasError ? 'โหลดไม่สำเร็จ' : userCount?.toString() ?? 'กำลังโหลด',
                    note: userSnapshot.hasError ? 'ตรวจสอบ Firestore Rules' : 'บัญชีที่มีโปรไฟล์ในระบบ',
                  ),
                  const _MetricCard(
                    icon: Icons.play_circle_outline,
                    title: 'ยอดรับชม',
                    value: 'ยังไม่มีข้อมูล',
                    note: 'ต้องเชื่อมระบบบันทึกการรับชมก่อน',
                  ),
                  const _MetricCard(
                    icon: Icons.payments_outlined,
                    title: 'รายได้จริง',
                    value: 'ยังไม่มีข้อมูล',
                    note: 'ยังไม่ได้เชื่อมระบบโฆษณาและรายได้',
                  ),
                  if (dramaSnapshot.hasError || userSnapshot.hasError)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'เกิดข้อผิดพลาดในการอ่านข้อมูล: ${dramaSnapshot.error ?? userSnapshot.error}',
                          style: const TextStyle(color: Colors.orangeAccent),
                        ),
                      ),
                    ),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('ข้อมูลจำนวนละครและสมาชิกอัปเดตจาก Firestore โดยตรง ส่วนยอดรับชมและรายได้จะไม่แสดงตัวเลขสมมติจนกว่าจะมีระบบบันทึกและแหล่งข้อมูลจริง'),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );

  Widget _sectionPlaceholder(String title) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.construction_outlined,
                size: 52, color: AdminTheme.gold),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'เตรียมหน้าจอไว้แล้ว รอเชื่อมต่อ Backend และระบบสิทธิ์ก่อนเปิดใช้ข้อมูลจริง',
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      );
}


class ManageMembersPage extends StatefulWidget {
  const ManageMembersPage({super.key});

  @override
  State<ManageMembersPage> createState() => _ManageMembersPageState();
}

class _ManageMembersPageState extends State<ManageMembersPage> {
  final _search = TextEditingController();
  final _users = FirebaseFirestore.instance.collection('users');

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'ค้นหาด้วยอีเมลหรือชื่อสมาชิก',
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _users.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('โหลดสมาชิกไม่สำเร็จ: ${snapshot.error}', textAlign: TextAlign.center),
                    ),
                  );
                }
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final query = _search.text.trim().toLowerCase();
                // Sort locally so legacy profiles without createdAt are not omitted.
                final allDocs = snapshot.data!.docs.toList()
                  ..sort((a, b) {
                    final aCreated = a.data()['createdAt'];
                    final bCreated = b.data()['createdAt'];
                    if (aCreated is Timestamp && bCreated is Timestamp) {
                      return bCreated.compareTo(aCreated);
                    }
                    if (aCreated is Timestamp) return -1;
                    if (bCreated is Timestamp) return 1;
                    return a.id.compareTo(b.id);
                  });
                final docs = allDocs.where((doc) {
                  final data = doc.data();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  final name = (data['displayName'] ?? '').toString().toLowerCase();
                  return query.isEmpty || email.contains(query) || name.contains(query);
                }).toList();
                if (docs.isEmpty) {
                  return const Center(child: Text('ไม่พบสมาชิก หรือยังไม่มีโปรไฟล์สมาชิก'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final suspended = data['status'] == 'suspended';
                    final email = (data['email'] ?? 'ไม่พบอีเมล').toString();
                    final name = (data['displayName'] ?? 'สมาชิก AUVYQORA').toString();
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: suspended ? Colors.red.shade900 : AdminTheme.burgundy,
                          child: Icon(suspended ? Icons.block : Icons.person_outline, color: AdminTheme.gold),
                        ),
                        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('$email\n${suspended ? 'ระงับการใช้งาน' : 'ใช้งานปกติ'}',
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) => _setStatus(doc.reference, action),
                          itemBuilder: (_) => [
                            if (!suspended)
                              const PopupMenuItem(value: 'suspended', child: Text('ระงับการใช้งาน')),
                            if (suspended)
                              const PopupMenuItem(value: 'active', child: Text('เปิดใช้งานอีกครั้ง')),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );

  Future<void> _setStatus(DocumentReference<Map<String, dynamic>> ref, String status) async {
    final label = status == 'suspended' ? 'ระงับ' : 'เปิดใช้งาน';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$labelบัญชีสมาชิก?'),
        content: Text(status == 'suspended'
            ? 'สมาชิกจะไม่สามารถอ่านเนื้อหาที่ต้องเข้าสู่ระบบได้'
            : 'สมาชิกจะกลับมาใช้งานเนื้อหาที่ต้องเข้าสู่ระบบได้'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(label)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(status == 'suspended' ? 'ระงับบัญชีแล้ว' : 'เปิดใช้งานบัญชีแล้ว')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เปลี่ยนสถานะไม่สำเร็จ: $error')),
        );
      }
    }
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.note,
  });

  final IconData icon;
  final String title;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Icon(icon, size: 30, color: AdminTheme.gold),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 18, color: AdminTheme.gold)),
                  Text(note,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: .62))),
                ],
              ),
            ),
          ]),
        ),
      );
}
