# AUVYQORA ADMIN

The administrator client is a separate Flutter Android application under `admin_app/`.
It shares the AUVYQORA Firebase project but uses a distinct Android application ID:

- Viewer app: `com.auvyqora.auvyqora`
- Admin app: `com.auvyqora.admin`

## Firebase setup required

1. In Firebase Console, register another Android app in project `auvyqora-c2d3a`.
2. Use package name `com.auvyqora.admin` and app nickname `AUVYQORA ADMIN`.
3. Download its `google-services.json`.
4. Add it to GitHub Actions repository secrets as `FIREBASE_ADMIN_GOOGLE_SERVICES_JSON`.
5. Never commit either Firebase configuration file to this public repository.

## Authorization

The app requires a verified email and a trusted Firebase custom claim:
- `admin: true`, or
- `role: "admin"`

A normal user cannot grant themselves this claim. Set claims only from a trusted, access-controlled server environment using the Firebase Admin SDK. Do not use a client-writable Firestore role field as authorization.

## Current implementation boundary

This is the separate admin app foundation: sign-in, verified-email check, custom-claim gate, responsive dashboard shell, and navigation placeholders. Content CRUD, video upload, publishing, member operations, and revenue reporting remain disabled until secure backend endpoints, Storage rules, and server authorization are implemented and tested.
