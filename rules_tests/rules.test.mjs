import { readFile } from 'node:fs/promises';
import { after, before, beforeEach, describe, it } from 'node:test';
import { strict as assert } from 'node:assert';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { collection, doc, getDoc, setDoc } from 'firebase/firestore';
import { ref, uploadBytes, getBytes } from 'firebase/storage';

const projectId = 'demo-auvyqora';
let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: { rules: await readFile(new URL('../firestore.rules', import.meta.url), 'utf8') },
    storage: { rules: await readFile(new URL('../storage.rules', import.meta.url), 'utf8') },
  });
});
after(async () => env.cleanup());
beforeEach(async () => {
  await env.clearFirestore();
  await env.clearStorage();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'dramas/published'), { title: 'Published', status: 'published' });
    await setDoc(doc(db, 'dramas/draft'), { title: 'Draft', status: 'draft' });
    await setDoc(doc(db, 'dramas/published/episodes/ep1'), { title: 'Episode', status: 'published' });
    await setDoc(doc(db, 'view_events/view1'), { uid: 'member-uid-123', dramaId: 'published', episodeId: 'ep1' });
    await setDoc(doc(db, 'users/member-uid-123'), { email: 'member@example.com', status: 'active' });
  });
});

const verifiedMember = () => env.authenticatedContext('member-uid-123', {
  email: 'member@example.com', email_verified: true,
});
const verifiedAdmin = () => env.authenticatedContext('admin-uid-123', {
  email: 'admin@example.com', email_verified: true, admin: true,
});

describe('Firestore Rules', () => {
  it('allows public reads only for published dramas and episodes', async () => {
    const db = env.unauthenticatedContext().firestore();
    await assertSucceeds(getDoc(doc(db, 'dramas/published')));
    await assertFails(getDoc(doc(db, 'dramas/draft')));
    await assertSucceeds(getDoc(doc(db, 'dramas/published/episodes/ep1')));
  });

  it('restricts member profile and favorites to the owner', async () => {
    const db = verifiedMember().firestore();
    await assertSucceeds(getDoc(doc(db, 'users/member-uid-123')));
    await assertFails(getDoc(doc(db, 'users/other-user')));
    await assertSucceeds(setDoc(doc(db, 'users/member-uid-123/favorites/published'), {
      dramaId: 'published', createdAt: new Date(),
    }));
    await assertFails(setDoc(doc(db, 'users/other-user/favorites/published'), {
      dramaId: 'published', createdAt: new Date(),
    }));
  });

  it('allows verified admins to read analytics but blocks client event and audit writes', async () => {
    const adminDb = verifiedAdmin().firestore();
    await assertSucceeds(getDoc(doc(adminDb, 'view_events/view1')));
    await assertFails(setDoc(doc(adminDb, 'audit_logs/forged'), {
      actorUid: 'admin-uid-123', action: 'delete', targetType: 'drama',
      targetId: 'published', createdAt: new Date(),
    }));
    await assertFails(setDoc(doc(adminDb, 'view_events/forged'), {
      uid: 'admin-uid-123', dramaId: 'published', episodeId: 'ep1',
      createdAt: new Date(),
    }));
    await assertFails(getDoc(doc(verifiedMember().firestore(), 'view_events/view1')));
  });

  it('requires verified admin claim for admin access', async () => {
    const unverifiedAdmin = env.authenticatedContext('admin-unverified', {
      admin: true, email_verified: false,
    }).firestore();
    await assertFails(getDoc(doc(unverifiedAdmin, 'view_events/view1')));
  });
});

describe('Storage Rules', () => {
  it('allows only verified admins to upload source videos', async () => {
    const adminStorage = verifiedAdmin().storage();
    await assertSucceeds(uploadBytes(ref(adminStorage, 'uploads/admin-uid-123/published/ep1/source.mp4'),
      new Uint8Array([1, 2, 3]), { contentType: 'video/mp4' }));
    const memberStorage = verifiedMember().storage();
    await assertFails(uploadBytes(ref(memberStorage, 'uploads/member-uid-123/published/ep1/source.mp4'),
      new Uint8Array([1, 2, 3]), { contentType: 'video/mp4' }));
  });

  it('denies direct SDK reads of HLS objects', async () => {
    const adminStorage = verifiedAdmin().storage();
    await env.withSecurityRulesDisabled(async (context) => {
      await uploadBytes(ref(context.storage(), 'hls/published/ep1/index.m3u8'),
        new Uint8Array([35, 69, 88, 84, 77, 51, 85]), { contentType: 'application/vnd.apple.mpegurl' });
    });
    await assertFails(getBytes(ref(adminStorage, 'hls/published/ep1/index.m3u8')));
    await assertFails(getBytes(ref(verifiedMember().storage(), 'hls/published/ep1/index.m3u8')));
  });
});
