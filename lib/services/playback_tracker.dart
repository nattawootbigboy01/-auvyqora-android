import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlaybackTracker {
  PlaybackTracker({required this.dramaId, required this.episodeId, required this.dramaTitle, required this.episodeTitle});
  final String dramaId, episodeId, dramaTitle, episodeTitle;
  int _lastSavedBucket = -1;
  bool _viewRecorded = false;
  User? get _verifiedUser {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.emailVerified ? user : null;
  }
  Future<void> recordView() async {
    final user = _verifiedUser;
    if (user == null || _viewRecorded || dramaId.isEmpty || episodeId.isEmpty) return;
    _viewRecorded = true;
    try {
      await FirebaseFunctions.instance.httpsCallable('recordViewEvent').call({
        'dramaId': dramaId,
        'episodeId': episodeId,
      });
    } catch (_) {
      _viewRecorded = false;
    }
  }
  Future<void> savePosition(int seconds) async {
    final user = _verifiedUser;
    if (user == null || dramaId.isEmpty || episodeId.isEmpty || seconds < 0) return;
    final bucket = seconds ~/ 15;
    if (bucket == _lastSavedBucket) return;
    _lastSavedBucket = bucket;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid)
          .collection('watch_history').doc(episodeId).set({
        'dramaId': dramaId, 'episodeId': episodeId,
        'dramaTitle': dramaTitle, 'episodeTitle': episodeTitle,
        'lastPositionSeconds': seconds, 'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) { _lastSavedBucket = -1; }
  }
}
