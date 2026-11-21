# Architecture plan

## Product rules
- Only platform administrators upload and publish drama content.
- Viewers watch content; no public user-generated uploads in the initial product.
- Android is the first client. Admin tools live in a separate web dashboard.
- Store video binaries in object storage/CDN as HLS, never in Firestore documents.

## Planned services
- Flutter Android client: browse, playback, profile, favorites, watch history.
- Firebase Authentication: verified email and sessions.
- Cloud Firestore: users, dramas, episodes, progress, favorites, publishing metadata.
- Trusted backend/Cloud Functions: role checks, publishing, signed playback access, analytics aggregation.
- Object storage + CDN: HLS renditions and posters.
- Web Admin Dashboard: upload, episode ordering, scheduling, member management, reports.
- AdMob: test units in development; rewarded ads require explicit opt-in; interstitials must be frequency-capped.

## Suggested collections
- users/{uid}: displayName, email, role, createdAt, status
- dramas/{dramaId}: title, synopsis, posterPath, status, publishedAt, createdBy
- dramas/{dramaId}/episodes/{episodeId}: title, episodeNumber, durationSeconds, hlsPath, status
- users/{uid}/favorites/{dramaId}: createdAt
- users/{uid}/watchProgress/{episodeId}: positionSeconds, updatedAt
- analyticsDaily/{date}: aggregated server-written metrics only

## Security
- Default deny until reviewed rules are implemented.
- Never trust a role supplied by the client; admin claims come from trusted server-side code.
- Viewers cannot write to content or storage publishing paths.
- Keep credentials and secrets out of source control.
- Label forecasts as estimates; actual ad revenue comes from ad-network reporting.
- Never click live ads or inflate impressions during testing.

## Phases
1. Foundation/UI; 2. Authentication; 3. Content API and streaming; 4. Admin dashboard; 5. Ads, analytics, policy review, release.
