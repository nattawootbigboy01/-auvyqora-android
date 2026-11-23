# AUVYQORA

**A UNIVERSE OF STORIES**  
*SHORT DRAMA. BIG EMOTIONS.*

Android-first short-drama streaming platform. Platform administrators manage and publish dramas; viewers browse and watch published episodes. The current build uses Firebase Authentication, Firestore, Cloud Storage, Cloud Functions, HLS processing, and Google's AdMob test unit.

## Current scope
- Viewer app: email/password registration and sign-in, email verification, published drama catalog, playback, favorites, and watch history.
- Admin app: separate Android package, verified-email plus server-assigned admin claim, drama/episode management, source-video upload and HLS processing, member suspension, reports, and audit history.
- Security: Firestore and Storage Rules restrict privileged reads/writes; backend callables perform trusted member and view operations. Emulator tests are in `rules_tests/`.

## Not yet implemented
Live AdMob monetization, paid ad-free membership, payment processing, subscription renewal/cancellation, and real revenue reporting are not implemented. The ad-free membership must be enforced by server-verified entitlement before live ads or payment collection are enabled.

## Run
Install Flutter stable, then run `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter run`.

The Android runner is generated on the build machine with `flutter create . --platforms=android --org com.auvyqora`. No Firebase credentials, live ad IDs, signing keys, or production secrets belong in this repository. Use Google's test ad units only during development.
