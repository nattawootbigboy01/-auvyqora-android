import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    ('จัดการละคร/หมวดหมู่', Icons.movie_creation_outlined),
    ('จัดการตอน/วิดีโอ', Icons.video_library_outlined),
    ('สมาชิก', Icons.people_outline),
    ('รายงาน/ส่งออก', Icons.analytics_outlined),
    ('แพ็กเกจ/การชำระเงิน', Icons.workspace_premium_outlined),
    ('แจ้งเตือน/ปัญหา', Icons.notifications_active_outlined),
    ('ทีมงาน/สิทธิ์', Icons.admin_panel_settings_outlined),
    ('ประวัติแอดมิน', Icons.history_edu_outlined),
    ('ตั้งค่าระบบ/ความปลอดภัย', Icons.security_outlined),
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
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 18),
                child: Text('ศูนย์จัดการ AUVYQORA',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminTheme.gold)),
              ),
              for (var i = 0; i < _sections.length; i++)
                ListTile(
                  leading: Icon(_sections[i].$2, color: _selected == i ? AdminTheme.gold : null),
                  title: Text(_sections[i].$1),
                  selected: _selected == i,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _selected = i);
                  },
                ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: switch (_selected) {
          0 => _overview(),
          1 => ManageDramasPage(),
          2 => const ManageEpisodesPage(),
          3 => const ManageMembersPage(),
          4 => _reports(),
          5 => const AdminModulePage(
            title: 'แพ็กเกจและการชำระเงิน',
            intro: 'พื้นที่จัดการสมาชิกแบบไม่มีโฆษณา แพ็กเกจ และรายการชำระเงิน',
            items: [
              ('แพ็กเกจสมาชิก', 'ยังไม่เชื่อมระบบจัดเก็บแพ็กเกจและสิทธิ์สมาชิก'),
              ('คำสั่งซื้อและสถานะชำระเงิน', 'ยังไม่มี Payment Provider หรือ Webhook ที่ตรวจสอบยอดเงินจริง'),
              ('ต่ออายุ ยกเลิก และคืนเงิน', 'ยังไม่เปิดใช้งาน เพื่อป้องกันการแสดงสถานะชำระเงินที่ไม่ถูกต้อง'),
              ('สิทธิ์ดูแบบไม่มีโฆษณา', 'ต้องให้ Backend ยืนยันสิทธิ์และวันหมดอายุก่อนเปิดใช้งาน'),
            ],
          ),
          6 => const AdminModulePage(
            title: 'แจ้งเตือนและปัญหาระบบ',
            intro: 'ศูนย์ติดตามเหตุการณ์และปัญหาที่ต้องให้ทีมงานตรวจสอบ',
            items: [
              ('กล่องแจ้งเตือนแอดมิน', 'ยังไม่มี collection และระบบส่งแจ้งเตือนกลาง'),
              ('รายงานปัญหาจากสมาชิก', 'ยังไม่มีแบบฟอร์มรับเรื่องและสถานะ ticket'),
              ('เหตุการณ์ผิดปกติ', 'ยังไม่มีระบบตรวจจับและแจ้งเตือนอัตโนมัติ'),
              ('ประวัติการแก้ไขปัญหา', 'จะเชื่อมกับ ticket และ audit log เมื่อกำหนด schema แล้ว'),
            ],
          ),
          7 => const AdminModulePage(
            title: 'ทีมงานและสิทธิ์ผู้ดูแล',
            intro: 'สิทธิ์ปัจจุบันตรวจจาก Custom Claims ฝั่ง Firebase ไม่ใช่ค่าที่แก้จากหน้าจอได้',
            items: [
              ('Super Admin', 'สงวนสิทธิ์ให้ผู้ดูแลระบบระดับสูงที่กำหนดจาก Backend'),
              ('Content Admin', 'สิทธิ์จัดการละคร ตอน และสื่อ ต้องเพิ่ม role claims และ Rules แยก'),
              ('User Admin', 'สิทธิ์ดูแลสมาชิก ต้องเพิ่ม role claims และ callable ที่จำกัดขอบเขต'),
              ('Finance Admin / Analyst', 'ยังไม่เปิดใช้จนกว่าจะมี schema การเงินและสิทธิ์อ่านรายงานแยก'),
              ('การเพิ่ม/ถอดผู้ดูแล', 'ปิดการแก้สิทธิ์จากแอปเพื่อป้องกันการยกระดับสิทธิ์โดยผู้ใช้ทั่วไป'),
            ],
          ),
          8 => _auditLogs(),
          _ => const AdminModulePage(
            title: 'ตั้งค่าระบบและความปลอดภัย',
            intro: 'หน้าตรวจสอบขอบเขตการดูแลระบบ โดยไม่เปลี่ยนค่าของ Firebase Production',
            items: [
              ('Firebase Authentication', 'ใช้บัญชีที่ยืนยันอีเมลและ Custom Claim admin=true'),
              ('Firestore / Storage Rules', 'ตรวจสอบด้วย Emulator และ CI ก่อนพิจารณา Deploy'),
              ('สำรองข้อมูล', 'ยังไม่สั่ง Backup อัตโนมัติหรือสร้างค่าใช้จ่ายบน Cloud'),
              ('การตั้งค่าระบบ', 'ยังไม่มีหน้าปรับค่าระบบ Production'),
              ('Audit Log', 'อ่านจาก audit_logs และการเขียนต้องผ่าน Backend ที่เชื่อถือได้'),
            ],
          ),
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selected < 5 ? _selected : 0,
        onDestinationSelected: (index) => setState(() => _selected = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'ภาพรวม'),
          NavigationDestination(icon: Icon(Icons.movie_outlined), label: 'ละคร'),
          NavigationDestination(icon: Icon(Icons.video_library_outlined), label: 'ตอน'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'สมาชิก'),
          NavigationDestination(icon: Icon(Icons.analytics_outlined), label: 'รายงาน'),
        ],
      ),
    );
  }

  Widget _auditLogs() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('audit_logs')
            .orderBy('createdAt', descending: true).limit(200).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('โหลดประวัติแอดมินไม่สำเร็จ: ${snapshot.error}', textAlign: TextAlign.center),
            ));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('ยังไม่มีประวัติการดำเนินการ'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final stamp = data['createdAt'];
              final time = stamp is Timestamp ? stamp.toDate().toLocal().toString() : 'ไม่ทราบเวลา';
              return Card(child: ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined, color: AdminTheme.gold),
                title: Text('${data['action'] ?? 'action'} • ${data['targetType'] ?? 'item'}'),
                subtitle: Text('เป้าหมาย: ${data['targetId'] ?? '-'}\nผู้ดำเนินการ: ${data['actorUid'] ?? '-'}\n$time'),
                isThreeLine: true,
              ));
            },
          );
        },
      );

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
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance.collection('view_events').limit(500).snapshots(),
                    builder: (context, viewSnapshot) => _MetricCard(
                      icon: Icons.play_circle_outline,
                      title: 'ยอดเปิดรับชม',
                      value: viewSnapshot.hasError ? 'อ่านข้อมูลไม่ได้' : viewSnapshot.hasData ? viewSnapshot.data!.docs.length.toString() : 'กำลังโหลด',
                      note: 'เหตุการณ์รับชมสูงสุด 500 รายการล่าสุด',
                    ),
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

  Widget _reports() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('view_events').orderBy('createdAt', descending: true).limit(500).snapshots(),
        builder: (context, viewSnapshot) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('dramas').snapshots(),
            builder: (context, dramaSnapshot) {
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, userSnapshot) {
                  final hasError = viewSnapshot.hasError || dramaSnapshot.hasError || userSnapshot.hasError;
                  final views = viewSnapshot.data?.docs ?? [];
                  final dramaDocs = dramaSnapshot.data?.docs ?? [];
                  final memberCount = userSnapshot.data?.docs.length;
                  final byDrama = <String, int>{};
                  for (final event in views) {
                    final id = (event.data()['dramaId'] ?? '').toString();
                    if (id.isNotEmpty) byDrama[id] = (byDrama[id] ?? 0) + 1;
                  }
                  final sorted = byDrama.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
                  final uniqueViewers = views.map((event) => (event.data()['uid'] ?? '').toString())
                      .where((uid) => uid.isNotEmpty).toSet().length;
                  final dailyViews = <String, int>{};
                  final today = DateTime.now();
                  for (final event in views) {
                    final stamp = event.data()['createdAt'];
                    if (stamp is Timestamp) {
                      final date = stamp.toDate();
                      final age = today.difference(DateTime(date.year, date.month, date.day)).inDays;
                      if (age >= 0 && age < 7) {
                        final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                        dailyViews[key] = (dailyViews[key] ?? 0) + 1;
                      }
                    }
                  }
                  final dailySorted = dailyViews.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
                  final titles = {for (final doc in dramaDocs) doc.id: (doc.data()['title'] ?? doc.id).toString()};
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text('รายงานและสถิติการรับชม',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: viewSnapshot.hasError || !viewSnapshot.hasData ? null : () async {
                          String cell(Object? value) => '"${(value ?? '').toString().replaceAll('"', '""')}"';
                          final csv = StringBuffer('event_id,uid,drama_id,created_at\\n');
                          for (final doc in views) {
                            final data = doc.data();
                            final stamp = data['createdAt'];
                            csv.writeln([
                              cell(doc.id),
                              cell(data['uid']),
                              cell(data['dramaId']),
                              cell(stamp is Timestamp ? stamp.toDate().toIso8601String() : ''),
                            ].join(','));
                          }
                          await Clipboard.setData(ClipboardData(text: csv.toString()));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('คัดลอก CSV ของเหตุการณ์รับชม 500 รายการล่าสุดหรือน้อยกว่าแล้ว')),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('คัดลอก CSV เหตุการณ์รับชม'),
                      ),
                      const SizedBox(height: 14),
                      Card(
                        child: ListTile(
                          leading: Icon(hasError ? Icons.cloud_off : Icons.analytics_outlined,
                              color: hasError ? Colors.orangeAccent : AdminTheme.gold),
                          title: Text(hasError ? 'โหลดรายงานไม่สำเร็จ' : 'ข้อมูลจากเหตุการณ์รับชมจริง'),
                          subtitle: Text(hasError
                              ? [
                                  if (viewSnapshot.hasError)
                                    'view_events: ${viewSnapshot.error}',
                                  if (dramaSnapshot.hasError)
                                    'dramas: ${dramaSnapshot.error}',
                                  if (userSnapshot.hasError)
                                    'users: ${userSnapshot.error}',
                                ].join(' | ')
                              : 'แสดงข้อมูลสูงสุด 500 เหตุการณ์ล่าสุด'),
                        ),
                      ),
                      _MetricCard(
                        icon: Icons.play_circle_outline,
                        title: 'ยอดเปิดรับชมที่บันทึกได้',
                        value: viewSnapshot.hasError ? 'อ่านข้อมูลไม่ได้' : viewSnapshot.hasData ? views.length.toString() : 'กำลังโหลด',
                        note: 'นับจาก view_events ที่อ่านได้ใน 500 รายการล่าสุด',
                      ),
                      _MetricCard(
                        icon: Icons.people_outline,
                        title: 'โปรไฟล์สมาชิก',
                        value: userSnapshot.hasError ? 'อ่านข้อมูลไม่ได้' : memberCount?.toString() ?? 'กำลังโหลด',
                        note: 'จำนวนเอกสารใน users',
                      ),
                      _MetricCard(
                        icon: Icons.people_alt_outlined,
                        title: 'ผู้ชมไม่ซ้ำในข้อมูลที่โหลด',
                        value: viewSnapshot.hasError ? 'อ่านข้อมูลไม่ได้' : viewSnapshot.hasData ? uniqueViewers.toString() : 'กำลังโหลด',
                        note: 'นับ UID ไม่ซ้ำจาก 500 เหตุการณ์ล่าสุด ไม่ใช่ยอดสะสมทั้งหมด',
                      ),
                      const _MetricCard(
                        icon: Icons.payments_outlined,
                        title: 'รายได้จริง',
                        value: 'ยังไม่มีข้อมูล',
                        note: 'ยังไม่มีระบบธุรกรรมหรือการชำระเงิน',
                      ),
                      const SizedBox(height: 8),
                      const Text('ยอดรับชมรายวันใน 7 วันที่มีข้อมูล',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      if (dailySorted.isEmpty)
                        const Card(child: Padding(
                          padding: EdgeInsets.all(14),
                          child: Text('ยังไม่มีข้อมูลวันที่บันทึกได้ในช่วง 7 วันที่ผ่านมา'),
                        ))
                      else
                        ...dailySorted.map((entry) => Card(
                          child: ListTile(
                            title: Text(entry.key),
                            trailing: Text('${entry.value} ครั้ง',
                                style: const TextStyle(color: AdminTheme.gold, fontWeight: FontWeight.bold)),
                          ),
                        )),
                      const SizedBox(height: 8),
                      const Text('ละครที่มีการรับชมมากที่สุดในข้อมูลที่โหลด',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      const SizedBox(height: 8),
                      if (!viewSnapshot.hasData && !viewSnapshot.hasError)
                        const Center(child: CircularProgressIndicator())
                      else if (sorted.isEmpty)
                        const Card(child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('ยังไม่มีเหตุการณ์รับชมที่บันทึกได้'),
                        ))
                      else
                        ...sorted.take(10).map((entry) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.movie_outlined, color: AdminTheme.gold),
                            title: Text(titles[entry.key] ?? entry.key),
                            trailing: Text('${entry.value} ครั้ง',
                                style: const TextStyle(color: AdminTheme.gold, fontWeight: FontWeight.bold)),
                          ),
                        )),
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('สถิตินี้นับการเปิดเล่นที่บันทึกสำเร็จ ไม่ใช่จำนวนผู้ชมไม่ซ้ำ และจำกัดการอ่านไว้ 500 เหตุการณ์ล่าสุด รายได้จะไม่แสดงจนกว่าจะมีระบบธุรกรรมจริง'),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
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
              // Sort locally so legacy profiles without createdAt remain visible.
              stream: _users.snapshots(),
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
                // Keep legacy profiles visible; orderBy(createdAt) omits documents missing that field.
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
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('setMemberStatus');
      await callable.call(<String, dynamic>{
        'uid': ref.id,
        'status': status,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(status == 'suspended' ? 'ระงับบัญชีและปิดการเข้าสู่ระบบแล้ว' : 'เปิดใช้งานบัญชีแล้ว')),
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


class AdminModulePage extends StatelessWidget {
  const AdminModulePage({
    required this.title,
    required this.intro,
    required this.items,
    super.key,
  });

  final String title;
  final String intro;
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(intro, style: TextStyle(color: Colors.white.withValues(alpha: .72))),
          const SizedBox(height: 16),
          for (final item in items)
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline, color: AdminTheme.gold),
                title: Text(item.$1),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(item.$2),
                ),
              ),
            ),
          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'สถานะ: ยังไม่เปิดใช้งานจริงใน Production หน้านี้ไม่สร้างข้อมูลตัวอย่าง ไม่เปลี่ยนสิทธิ์ และไม่เรียกเก็บเงิน',
              ),
            ),
          ),
        ],
      );
}
