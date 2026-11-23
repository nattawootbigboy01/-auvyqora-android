import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

const _gold = Color(0xFFD6B36A);
const _draft = 'draft';
const _published = 'published';

class ContentRepository {
  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get dramas => _db.collection('dramas');

  // Avoid orderBy on an optional timestamp: legacy documents without updatedAt
  // are excluded by Firestore when orderBy is used.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchDramas() => dramas.snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchEpisodes(String dramaId) =>
      dramas.doc(dramaId).collection('episodes').orderBy('number').snapshots();

  Future<bool> _audit(String action, String targetType, String targetId) async {
    try {
      await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('recordContentAudit')
          .call({
        'action': action,
        'targetType': targetType,
        'targetId': targetId,
      });
      return true;
    } catch (error) {
      // The content operation has already succeeded. Report the audit failure
      // separately instead of silently pretending the action was fully logged.
      debugPrint('Admin audit write failed: ${error.runtimeType}');
      return false;
    }
  }

  Future<bool> saveDrama(String? id, Map<String, dynamic> data) async {
    final ref = id == null ? dramas.doc() : dramas.doc(id);
    final values = <String, dynamic>{...data, 'updatedAt': FieldValue.serverTimestamp()};
    if (id == null) values['createdAt'] = FieldValue.serverTimestamp();
    await ref.set(values, SetOptions(merge: true));
    return _audit(id == null ? 'create' : 'update', 'drama', ref.id);
  }

  Future<bool> deleteDrama(String id) async {
    final ref = dramas.doc(id);
    final episodes = ref.collection('episodes');
    while (true) {
      final page = await episodes.orderBy(FieldPath.documentId).limit(400).get();
      if (page.docs.isEmpty) break;
      final batch = _db.batch();
      for (final doc in page.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    await ref.delete();
    return _audit('delete', 'drama', id);
  }

  Future<bool> saveEpisode(String dramaId, String? id, Map<String, dynamic> data) async {
    final collection = dramas.doc(dramaId).collection('episodes');
    final ref = id == null ? collection.doc() : collection.doc(id);
    final values = <String, dynamic>{...data, 'updatedAt': FieldValue.serverTimestamp()};
    if (id == null) values['createdAt'] = FieldValue.serverTimestamp();
    await ref.set(values, SetOptions(merge: true));
    return _audit(id == null ? 'create' : 'update', 'episode', ref.id);
  }

  Future<bool> deleteEpisode(String dramaId, String id) async {
    await dramas.doc(dramaId).collection('episodes').doc(id).delete();
    return _audit('delete', 'episode', id);
  }
}

class ManageDramasPage extends StatelessWidget {
  ManageDramasPage({super.key});
  final _repo = ContentRepository();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: StreamBuilder(
      stream: _repo.watchDramas(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _error('โหลดละครไม่สำเร็จ: ${snapshot.error}');
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final aTime = a.data()['updatedAt'];
            final bTime = b.data()['updatedAt'];
            if (aTime is Timestamp && bTime is Timestamp) return bTime.compareTo(aTime);
            if (aTime is Timestamp) return -1;
            if (bTime is Timestamp) return 1;
            return a.id.compareTo(b.id);
          });
        if (docs.isEmpty) return _empty(Icons.movie_outlined, 'ยังไม่มีละคร', 'กดเพิ่มละครเพื่อเริ่มต้น');
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            return Card(child: ListTile(
              leading: const Icon(Icons.movie, color: _gold),
              title: Text((data['title'] ?? 'ไม่มีชื่อ').toString()),
              subtitle: Text('${data['genre'] ?? 'ไม่ระบุแนว'} • ${data['status'] == _published ? 'เผยแพร่' : 'ฉบับร่าง'}'),
              trailing: PopupMenuButton<String>(
                onSelected: (action) async {
                  if (action == 'edit') {
                    await _dramaForm(context, doc.id, data);
                  } else if (action == 'delete') {
                    await _deleteDrama(context, doc.id);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('แก้ไข')),
                  PopupMenuItem(value: 'delete', child: Text('ลบ')),
                ],
              ),
              onTap: () => _dramaForm(context, doc.id, data),
            ));
          },
        );
      },
    ),
    floatingActionButton: FloatingActionButton.extended(
      backgroundColor: _gold, foregroundColor: Colors.black,
      onPressed: () => _dramaForm(context, null, null),
      icon: const Icon(Icons.add), label: const Text('เพิ่มละคร'),
    ),
  );

  Future<void> _dramaForm(BuildContext context, String? id, Map<String, dynamic>? data) async {
    final title = TextEditingController(text: data?['title']?.toString() ?? '');
    final genre = TextEditingController(text: data?['genre']?.toString() ?? '');
    final synopsis = TextEditingController(text: data?['synopsis']?.toString() ?? '');
    final posterUrl = TextEditingController(text: data?['posterUrl']?.toString() ?? '');
    var featured = data?['isFeatured'] == true;
    var status = data?['status'] == _published ? _published : _draft;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, setState) => AlertDialog(
        title: Text(id == null ? 'เพิ่มละคร' : 'แก้ไขละคร'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: 'ชื่อเรื่อง')),
          TextField(controller: genre, decoration: const InputDecoration(labelText: 'แนวละคร')),
          TextField(controller: synopsis, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'เรื่องย่อ')),
          TextField(controller: posterUrl, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'ลิงก์โปสเตอร์ (HTTPS)')),
          SwitchListTile(contentPadding: EdgeInsets.zero, value: featured, onChanged: (v) => setState(() => featured = v), title: const Text('แนะนำบนหน้าแรก')),
          DropdownButtonFormField<String>(
            initialValue: status, decoration: const InputDecoration(labelText: 'สถานะ'),
            items: const [DropdownMenuItem(value: _draft, child: Text('ฉบับร่าง')), DropdownMenuItem(value: _published, child: Text('เผยแพร่'))],
            onChanged: (v) => setState(() => status = v ?? _draft),
          ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('ยกเลิก')),
          FilledButton(onPressed: () {
            if (title.text.trim().isEmpty) return;
            final poster = posterUrl.text.trim();
            final posterUri = Uri.tryParse(poster);
            if (poster.isNotEmpty && (posterUri == null || posterUri.scheme != 'https' || !posterUri.hasAuthority)) return;
            Navigator.pop(dialogContext, {'title': title.text.trim(), 'genre': genre.text.trim(), 'synopsis': synopsis.text.trim(), 'posterUrl': poster, 'isFeatured': featured, 'status': status});
          }, child: const Text('บันทึก')),
        ],
      )),
    );
    title.dispose(); genre.dispose(); synopsis.dispose(); posterUrl.dispose();
    if (result == null) return;
    try {
      final audited = await _repo.saveDrama(id, result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(audited
              ? 'บันทึกละครและประวัติแอดมินแล้ว'
              : 'บันทึกละครแล้ว แต่บันทึกประวัติแอดมินไม่สำเร็จ'),
        ));
      }
    } catch (e) { if (context.mounted) _showError(context, e); }
  }

  Future<void> _deleteDrama(BuildContext context, String id) async {
    final yes = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('ลบละคร?'), content: const Text('ระบบจะลบรายการตอนของเรื่องนี้ด้วย'),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('ยกเลิก')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('ลบ'))],
    ));
    if (yes != true) return;
    try {
      final audited = await _repo.deleteDrama(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(audited
              ? 'ลบละครและบันทึกประวัติแล้ว'
              : 'ลบละครแล้ว แต่บันทึกประวัติแอดมินไม่สำเร็จ'),
        ));
      }
    } catch (e) { if (context.mounted) _showError(context, e); }
  }
}

class ManageEpisodesPage extends StatefulWidget {
  const ManageEpisodesPage({super.key});
  @override
  State<ManageEpisodesPage> createState() => _ManageEpisodesPageState();
}

class _ManageEpisodesPageState extends State<ManageEpisodesPage> {
  final _repo = ContentRepository();
  String? _selectedId;

  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: _repo.watchDramas(),
    builder: (context, dramasSnapshot) {
      if (dramasSnapshot.hasError) return _error('โหลดละครไม่สำเร็จ: ${dramasSnapshot.error}');
      if (!dramasSnapshot.hasData) return const Center(child: CircularProgressIndicator());
      final dramas = dramasSnapshot.data!.docs;
      if (dramas.isEmpty) return _empty(Icons.video_library, 'ยังไม่มีละคร', 'เพิ่มละครก่อนจัดการตอน');
      final selectedId = dramas.any((d) => d.id == _selectedId) ? _selectedId! : dramas.first.id;
      return Column(children: [
        Card(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline, color: _gold),
              SizedBox(width: 10),
              Expanded(child: Text('เลือกอัปโหลดไฟล์วิดีโอจากเครื่องได้ ระบบจะส่งไฟล์ไปจัดเก็บและให้ Cloud Functions แปลงเป็น HLS อัตโนมัติ หรือกรอกลิงก์ HLS ภายนอกแบบ HTTPS ได้')),
            ]),
          ),
        ),
        Padding(padding: const EdgeInsets.all(16), child: DropdownButtonFormField<String>(
          initialValue: selectedId, decoration: const InputDecoration(labelText: 'เลือกละคร'),
          items: [for (final d in dramas) DropdownMenuItem(value: d.id, child: Text((d.data()['title'] ?? '').toString()))],
          onChanged: (v) => setState(() => _selectedId = v),
        )),
        Expanded(child: StreamBuilder(
          stream: _repo.watchEpisodes(selectedId),
          builder: (context, episodesSnapshot) {
            if (episodesSnapshot.hasError) return _error('โหลดตอนไม่สำเร็จ: ${episodesSnapshot.error}');
            if (!episodesSnapshot.hasData) return const Center(child: CircularProgressIndicator());
            final episodes = episodesSnapshot.data!.docs;
            if (episodes.isEmpty) return _empty(Icons.video_library, 'ยังไม่มีตอน', 'กดเพิ่มตอนใหม่ด้านล่าง');
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: episodes.length,
              itemBuilder: (context, index) {
                final doc = episodes[index]; final data = doc.data();
                final uploadStatus = (data['uploadStatus'] ?? '').toString();
                final uploadLabel = switch (uploadStatus) {
                  'uploading' => 'กำลังอัปโหลด',
                  'processing' => 'กำลังแปลงเป็น HLS',
                  'ready' => 'วิดีโอพร้อมเล่น',
                  'failed' => 'แปลงวิดีโอไม่สำเร็จ',
                  _ => '',
                };
                final uploadError = (data['uploadError'] ?? '').toString();
                return Card(child: ListTile(
                  leading: CircleAvatar(child: Text('${data['number'] ?? index + 1}')),
                  title: Text((data['title'] ?? 'ไม่มีชื่อตอน').toString()),
                  subtitle: Text([
                    '${data['durationLabel'] ?? ''} • ${data['status'] == _published ? 'เผยแพร่' : 'ฉบับร่าง'}',
                    if (uploadLabel.isNotEmpty) uploadLabel,
                    if (uploadStatus == 'failed' && uploadError.isNotEmpty) uploadError,
                  ].join(' • '), maxLines: 3, overflow: TextOverflow.ellipsis),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') {
                        await _episodeForm(context, selectedId, doc.id, data);
                      } else if (v == 'upload') {
                        await _uploadEpisodeVideo(context, selectedId, doc.id);
                      } else if (v == 'delete') {
                        await _deleteEpisode(context, selectedId, doc.id);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('แก้ไขข้อมูลตอน')),
                      PopupMenuItem(value: 'upload', child: Text('อัปโหลดวิดีโอ')),
                      PopupMenuItem(value: 'delete', child: Text('ลบ')),
                    ],
                  ),
                ));
              },
            );
          },
        )),
        Padding(padding: const EdgeInsets.all(16), child: SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: () => _episodeForm(context, selectedId, null, null),
          icon: const Icon(Icons.add), label: const Text('เพิ่มตอนใหม่'),
        ))),
      ]);
    },
  );


  Future<File> _resolvePickedVideoFile(PlatformFile file) async {
    final existingPath = file.path;
    if (existingPath != null) {
      final candidate = File(existingPath);
      if (await candidate.exists()) return candidate;
    }

    // Some Android document providers return a stream instead of a filesystem path.
    // Copy in chunks to app-private temp storage, never loading a large video into RAM.
    final stream = file.readStream;
    if (stream == null) {
      throw StateError('ระบบเลือกไฟล์ไม่ส่งข้อมูลไฟล์กลับมา กรุณาลองเลือกไฟล์จากแอป Files อีกครั้ง');
    }

    final tempDir = await Directory.systemTemp.createTemp('auvyqora-video-');
    final safeName = file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final outputFile = File('${tempDir.path}/$safeName');
    final sink = outputFile.openWrite();
    var written = 0;
    var sinkClosed = false;
    const maxBytes = 1024 * 1024 * 1024;

    Future<void> closeSink() async {
      if (sinkClosed) return;
      sinkClosed = true;
      await sink.close();
    }

    try {
      await for (final chunk in stream) {
        written += chunk.length;
        if (written >= maxBytes) {
          throw StateError('ไฟล์วิดีโอต้องมีขนาดน้อยกว่า 1 GB');
        }
        sink.add(chunk);
      }
      await sink.flush();
      await closeSink();
      if (written == 0) {
        throw StateError('ไฟล์ที่เลือกไม่มีข้อมูล กรุณาเลือกไฟล์ใหม่');
      }
      return outputFile;
    } catch (_) {
      await closeSink();
      await tempDir.delete(recursive: true);
      rethrow;
    }
  }

  Future<void> _uploadEpisodeVideo(BuildContext context, String dramaId, String episodeId) async {
    FilePickerResult? picked;
    try {
      // Use the Android system picker without a restrictive MIME filter. Validate
      // extensions ourselves because some document providers misreport video MIME.
      picked = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: false,
        withReadStream: true,
      );
    } catch (error) {
      if (context.mounted) {
        _showError(context, 'เปิดตัวเลือกไฟล์ไม่สำเร็จ (${error.runtimeType}): $error');
      }
      return;
    }

    if (!context.mounted) return;
    if (picked == null || picked.files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยกเลิกการเลือกไฟล์')),
      );
      return;
    }

    final file = picked.files.single;
    final extension = (file.extension ??
            (file.name.contains('.') ? file.name.split('.').last : ''))
        .toLowerCase();
    const allowed = {'mp4', 'mov', 'm4v', 'mkv', 'webm'};
    if (!allowed.contains(extension)) {
      _showError(context, 'ไฟล์นี้ไม่รองรับ กรุณาเลือก MP4, MOV, M4V, MKV หรือ WEBM');
      return;
    }

    // Storage Rules require size < 1 GiB, not <= 1 GiB.
    const maxBytes = 1024 * 1024 * 1024;
    if (file.size >= maxBytes) {
      _showError(context, 'ไฟล์วิดีโอต้องมีขนาดน้อยกว่า 1 GB');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError(context, 'กรุณาเข้าสู่ระบบแอดมินใหม่');
      return;
    }

    late final File uploadFile;
    Directory? temporaryDirectory;
    var dialogOpen = false;
    var dialogFuture = Future<void>.value();

    try {
      uploadFile = await _resolvePickedVideoFile(file);
      final originalPath = file.path;
      if (originalPath == null || !await File(originalPath).exists()) {
        temporaryDirectory = uploadFile.parent;
      }
      final actualSize = await uploadFile.length();
      if (actualSize == 0 || actualSize >= maxBytes) {
        throw StateError('ไฟล์วิดีโอต้องมีข้อมูลและมีขนาดน้อยกว่า 1 GB');
      }

      final mime = switch (extension) {
        'mov' => 'video/quicktime',
        'mkv' => 'video/x-matroska',
        'webm' => 'video/webm',
        'm4v' => 'video/x-m4v',
        _ => 'video/mp4',
      };
      final safeName = file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final objectPath = 'uploads/${user.uid}/$dramaId/$episodeId/${DateTime.now().millisecondsSinceEpoch}_$safeName';

      await _repo.dramas.doc(dramaId).collection('episodes').doc(episodeId).update({
        'uploadStatus': 'uploading',
        'sourceObjectPath': objectPath,
        'uploadError': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final task = FirebaseStorage.instance.ref(objectPath).putFile(
        uploadFile,
        SettableMetadata(
          contentType: mime,
          customMetadata: {
            'uid': user.uid,
            'dramaId': dramaId,
            'episodeId': episodeId,
          },
        ),
      );
      if (context.mounted) {
        dialogFuture = showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => StreamBuilder<TaskSnapshot>(
            stream: task.snapshotEvents,
            builder: (context, snapshot) {
              final current = snapshot.data;
              final total = current?.totalBytes ?? 0;
              final sent = current?.bytesTransferred ?? 0;
              final progress = total > 0 ? sent / total : null;
              return AlertDialog(
                title: const Text('กำลังอัปโหลดวิดีโอ'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 12),
                    Text(total > 0
                        ? '${(sent / 1024 / 1024).toStringAsFixed(1)} / ${(total / 1024 / 1024).toStringAsFixed(1)} MB'
                        : 'กำลังเตรียมไฟล์'),
                  ],
                ),
              );
            },
          ),
        );
        dialogOpen = true;
      }
      await task;
      if (context.mounted && dialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogOpen = false;
      }
      await dialogFuture;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปโหลดสำเร็จ กำลังแปลงวิดีโอเป็น HLS')),
        );
      }
    } catch (error) {
      if (context.mounted && dialogOpen) {
        Navigator.of(context, rootNavigator: true).maybePop();
        dialogOpen = false;
      }
      await dialogFuture;
      try {
        await _repo.dramas.doc(dramaId).collection('episodes').doc(episodeId).update({
          'uploadStatus': 'failed',
          'uploadError': error.toString(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
      if (context.mounted) _showError(context, error);
    } finally {
      if (temporaryDirectory != null) {
        try {
          if (await temporaryDirectory.exists()) {
            await temporaryDirectory.delete(recursive: true);
          }
        } catch (_) {
          // Do not hide the original upload result if temp cleanup fails.
        }
      }
    }
  }

  Future<void> _episodeForm(BuildContext context, String dramaId, String? id, Map<String, dynamic>? data) async {
    final title = TextEditingController(text: data?['title']?.toString() ?? '');
    final number = TextEditingController(text: (data?['number'] ?? 1).toString());
    final duration = TextEditingController(text: data?['durationLabel']?.toString() ?? '2 นาที');
    final hlsUrl = TextEditingController(text: data?['hlsUrl']?.toString() ?? '');
    var status = data?['status'] == _published ? _published : _draft;
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (c) => StatefulBuilder(builder: (context, setState) => AlertDialog(
      title: Text(id == null ? 'เพิ่มตอนใหม่' : 'แก้ไขตอน'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, decoration: const InputDecoration(labelText: 'ชื่อตอน')),
        TextField(controller: number, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'หมายเลขตอน')),
        TextField(controller: duration, decoration: const InputDecoration(labelText: 'ความยาว เช่น 2 นาที')),
        TextField(controller: hlsUrl, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'ลิงก์วิดีโอ HLS (HTTPS)')),
        DropdownButtonFormField<String>(initialValue: status, decoration: const InputDecoration(labelText: 'สถานะ'),
          items: const [DropdownMenuItem(value: _draft, child: Text('ฉบับร่าง')), DropdownMenuItem(value: _published, child: Text('เผยแพร่'))],
          onChanged: (v) => setState(() => status = v ?? _draft)),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('ยกเลิก')),
        FilledButton(onPressed: () {
          final n = int.tryParse(number.text.trim());
          if (title.text.trim().isEmpty || n == null || n < 1) return;
          final streamUrl = hlsUrl.text.trim();
          final streamUri = Uri.tryParse(streamUrl);
          if (status == _published && (streamUri == null || streamUri.scheme != 'https' || !streamUri.hasAuthority)) return;
          if (streamUrl.isNotEmpty && (streamUri == null || streamUri.scheme != 'https' || !streamUri.hasAuthority)) return;
          Navigator.pop(c, {'title': title.text.trim(), 'number': n, 'durationLabel': duration.text.trim(), 'hlsUrl': streamUrl, 'status': status});
        }, child: const Text('บันทึก')),
      ],
    )));
    title.dispose(); number.dispose(); duration.dispose(); hlsUrl.dispose();
    if (result == null) return;
    try {
      final audited = await _repo.saveEpisode(dramaId, id, result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(audited
              ? 'บันทึกตอนและประวัติแอดมินแล้ว'
              : 'บันทึกตอนแล้ว แต่บันทึกประวัติแอดมินไม่สำเร็จ'),
        ));
      }
    } catch (e) { if (context.mounted) _showError(context, e); }
  }

  Future<void> _deleteEpisode(BuildContext context, String dramaId, String id) async {
    final yes = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('ลบตอน?'), content: const Text('ต้องการลบตอนนี้หรือไม่?'),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('ยกเลิก')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('ลบ'))],
    ));
    if (yes != true) return;
    try {
      final audited = await _repo.deleteEpisode(dramaId, id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(audited
              ? 'ลบตอนและบันทึกประวัติแล้ว'
              : 'ลบตอนแล้ว แต่บันทึกประวัติแอดมินไม่สำเร็จ'),
        ));
      }
    } catch (e) { if (context.mounted) _showError(context, e); }
  }
}

Widget _empty(IconData icon, String title, String message) => Center(child: Padding(
  padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 52, color: _gold), const SizedBox(height: 12),
    Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
    const SizedBox(height: 6), Text(message, textAlign: TextAlign.center),
  ]),
));

Widget _error(String message) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(message, textAlign: TextAlign.center)));

void _showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ดำเนินการไม่สำเร็จ: $error')));
}
