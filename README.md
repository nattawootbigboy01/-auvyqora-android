# AUVYQORA

**A UNIVERSE OF STORIES**  
*SHORT DRAMA. BIG EMOTIONS.*

Android-first short-drama streaming platform. Only platform administrators publish dramas; viewers browse and watch for free, with advertising planned as a revenue source.

## Foundation branch
This branch establishes the Flutter application shell, cinematic dark theme, initial screens, typed content models, and architecture/security plan.

## Run
Install Flutter stable, then run `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter run`.

The Android runner is generated on the build machine with `flutter create . --platforms=android --org com.auvyqora`. No Firebase credentials, ad IDs, signing keys, or production secrets belong in this repository.

Authentication, real video streaming, admin publishing, and ads are planned integrations and are not represented as working services yet. Use test ad units only during development.
