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

The app, Firestore Rules, Storage Rules, and callable backend all require the exact Firebase custom claim `admin: true` and a verified email.

A `role: "admin"` field or claim is **not** accepted by the current implementation. A normal user cannot grant themselves admin access. Set `admin: true` only from a trusted, access-controlled server environment using the Firebase Admin SDK. Never use a client-writable Firestore field as authorization. After changing claims, sign out and sign in again (or force-refresh the ID token) before testing the Admin app.

## Current implementation and deployment boundary

The Admin app currently includes:
- Email/password sign-in, verified-email check, and the server-assigned `admin: true` claim gate.
- Drama and episode management, including draft/published status.
- Source-video upload to the restricted Storage path and HLS processing through Cloud Functions.
- Member activation/suspension through the authenticated `setMemberStatus` callable.
- Read-only viewing reports and append-only admin audit history.

The repository contains Firestore Rules, Storage Rules, and backend functions, plus emulator tests. Passing emulator tests does **not** prove that the matching rules/functions are deployed in Firebase project `auvyqora-c2d3a`. Verify the deployed versions and the Admin user's custom claim before diagnosing production permission errors.

AdMob currently uses Google's test ad unit only. A paid ad-free membership, payment processing, subscription renewal, and revenue reporting are **not implemented**. Do not collect real payments or publish live ad IDs until those flows have server-side entitlement validation, billing verification, privacy/consent handling, and end-to-end tests.
