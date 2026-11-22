# AUVYQORA video and trusted admin backend

## What this branch now contains

- Admin-only source video upload from the Android admin app.
- Upload progress and per-episode upload/transcoding status.
- A Cloud Storage finalize trigger that converts MP4/MOV/M4V/MKV/WEBM into HLS VOD (720p, six-second MPEG-TS segments) with FFmpeg.
- HLS playlist and segment download tokens, then an update of the episode's `hlsUrl` and `uploadStatus=ready`.
- A callable `setMemberStatus` function that disables/enables the Firebase Authentication account, updates the Firestore profile, and writes an audit record in one Firestore batch. It refuses self-disable and refuses to disable another admin.
- Storage rules that allow only admins to upload source video; HLS output is readable for playback and cannot be written by clients.

The transcode function does not publish an episode automatically. An administrator still reviews the episode and explicitly changes its content status to Published.

## Required Firebase setup before deployment

This backend is code-complete but is not live until the Firebase project has the required infrastructure. No billing setting or paid resource has been enabled by this change.

1. In Firebase Console, create/enable the project's default Cloud Storage bucket. Choose **us-central1** so it matches the default Cloud Functions/Eventarc region used here.
2. Cloud Functions second generation and newly provisioned Cloud Storage buckets require the Firebase **Blaze** billing plan. Storage, function execution, network egress, and build resources can incur charges. Set budget alerts and review the current Firebase/Google Cloud pricing before enabling billing.
3. Confirm the Android Admin Firebase app's `google-services.json` contains the project's `storage_bucket` value. The GitHub Actions secret `FIREBASE_ADMIN_GOOGLE_SERVICES_JSON` must correspond to package `com.auvyqora.admin` in project `auvyqora-c2d3a`.
4. Ensure the admin account has the trusted Firebase custom claim `admin: true` and has verified its email.

## Deployment commands

Run from the repository root after the project owner has approved billing and bucket creation:

```bash
firebase deploy --only functions,storage --project auvyqora-c2d3a
```

Deploy the Firestore rules separately after reviewing the rules change:

```bash
firebase deploy --only firestore:rules --project auvyqora-c2d3a
```

Do not run either command against another Firebase project.

## Admin upload flow

1. Open AUVYQORA ADMIN and choose a drama.
2. Create or edit an episode first, so the episode document exists.
3. Open the episode menu and choose **อัปโหลดวิดีโอ**.
4. Select an MP4/MOV/M4V/MKV/WEBM file no larger than 1 GB.
5. Wait for the upload to finish. The episode row reports Uploading, Transcoding, Ready, or Failed.
6. When it reports **วิดีโอพร้อมเล่น**, review the HLS playback in the viewer app, then publish the episode manually.

If the function has not been deployed or Storage is not enabled, the upload will fail and the UI will show the error. This is intentional; it must not pretend a video was processed.

## Cost and safety boundaries

- The maximum source upload is 1 GB. This is a technical cap, not a cost guarantee.
- The transcode trigger is capped at one concurrent instance, 2 GiB memory, two CPUs, and 540 seconds.
- Source uploads are retained after transcoding so an administrator can recover/reprocess them; configure a lifecycle policy only after deciding retention needs.
- HLS output is readable by anyone who has the generated playback URL. Only the trusted backend can write HLS objects.
- Never store service-account JSON or private keys in the repository or mobile app.
