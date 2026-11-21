# Android runner and Firebase configuration

The Android Gradle project is generated on the GitHub Actions build machine with:
`flutter create . --platforms=android --org com.auvyqora`

The expected Android application ID is `com.auvyqora.auvyqora`. The CI workflow verifies this value against the package name inside the Firebase configuration before building.

Never commit `google-services.json` to this public repository. Store its complete JSON content as the GitHub Actions repository secret named `FIREBASE_ANDROID_GOOGLE_SERVICES_JSON`. The workflow writes it only into the temporary build workspace.

Firebase Android builds require Google Services Gradle plugin and minSdk 24. Do not commit signing keys or local.properties.
