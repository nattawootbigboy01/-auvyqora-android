const { spawn } = require("node:child_process");
const { mkdtemp, mkdir, readFile, readdir, rm } = require("node:fs/promises");
const { tmpdir } = require("node:os");
const path = require("node:path");
const { randomUUID } = require("node:crypto");

const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { FieldValue, getFirestore } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onObjectFinalized } = require("firebase-functions/v2/storage");
const { onDocumentDeleted } = require("firebase-functions/v2/firestore");
const ffmpegPath = require("ffmpeg-static");

initializeApp();

exports.setMemberStatus = onCall(async (request) => {
  if (!request.auth || request.auth.token.admin !== true || request.auth.token.email_verified !== true) {
    throw new HttpsError("permission-denied", "เฉพาะผู้ดูแลระบบที่ยืนยันอีเมลแล้วเท่านั้น");
  }

  const uid = request.data && request.data.uid;
  const status = request.data && request.data.status;
  if (typeof uid !== "string" || uid.length < 10 || uid.length > 128) {
    throw new HttpsError("invalid-argument", "รหัสสมาชิกไม่ถูกต้อง");
  }
  if (status !== "active" && status !== "suspended") {
    throw new HttpsError("invalid-argument", "สถานะบัญชีไม่ถูกต้อง");
  }
  if (uid === request.auth.uid) {
    throw new HttpsError("failed-precondition", "ไม่สามารถเปลี่ยนสถานะบัญชีผู้ดูแลที่กำลังใช้งานอยู่");
  }

  const auth = getAuth();
  const db = getFirestore();
  let target;
  try {
    target = await auth.getUser(uid);
  } catch (error) {
    if (error.code === "auth/user-not-found") {
      throw new HttpsError("not-found", "ไม่พบบัญชีสมาชิกใน Firebase Authentication");
    }
    throw new HttpsError("internal", "ตรวจสอบบัญชีสมาชิกไม่สำเร็จ");
  }
  if (target.customClaims && target.customClaims.admin === true) {
    throw new HttpsError("failed-precondition", "ไม่สามารถระงับบัญชีผู้ดูแลระบบผ่านเมนูสมาชิก");
  }

  const disabled = status === "suspended";
  const previousDisabled = target.disabled;
  await auth.updateUser(uid, { disabled });
  try {
    const memberRef = db.collection("users").doc(uid);
    const auditRef = db.collection("audit_logs").doc();
    const batch = db.batch();
    batch.set(memberRef, {
      email: target.email || null,
      displayName: target.displayName || null,
      status,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    batch.set(auditRef, {
      actorUid: request.auth.uid,
      action: disabled ? "suspend" : "activate",
      targetType: "member",
      targetId: uid,
      createdAt: FieldValue.serverTimestamp(),
    });
    await batch.commit();
  } catch (error) {
    await auth.updateUser(uid, { disabled: previousDisabled });
    throw new HttpsError("internal", "บันทึกสถานะและประวัติไม่สำเร็จ ระบบยกเลิกการเปลี่ยนสถานะแล้ว");
  }
  return { success: true, uid, status, disabled };
});

function runFfmpeg(args) {
  return new Promise((resolve, reject) => {
    if (!ffmpegPath) return reject(new Error("ไม่พบ FFmpeg binary"));
    const child = spawn(ffmpegPath, args, { stdio: ["ignore", "ignore", "pipe"] });
    let stderr = "";
    child.stderr.on("data", (chunk) => {
      stderr = (stderr + chunk.toString()).slice(-12000);
    });
    child.on("error", reject);
    child.on("close", (code) => {
      if (code === 0) return resolve();
      reject(new Error("FFmpeg แปลงไฟล์ไม่สำเร็จ: " + stderr.slice(-1500)));
    });
  });
}

function storageDownloadUrl(bucketName, objectPath, token) {
  return "https://firebasestorage.googleapis.com/v0/b/" + bucketName +
    "/o/" + encodeURIComponent(objectPath) + "?alt=media&token=" + token;
}

exports.transcodeUploadedEpisode = onObjectFinalized({
  memory: "2GiB",
  cpu: 2,
  timeoutSeconds: 540,
  maxInstances: 1,
  concurrency: 1,
}, async (event) => {
  const object = event.data;
  const objectPath = object.name || "";
  const match = objectPath.match(/^uploads\/([^/]+)\/([^/]+)\/([^/]+)\/[^/]+$/);
  if (!match) return;

  const [, uid, dramaId, episodeId] = match;
  const custom = object.metadata || {};
  if (custom.uid !== uid || custom.dramaId !== dramaId || custom.episodeId !== episodeId) {
    console.warn("Ignoring upload with mismatched metadata", objectPath);
    return;
  }
  if (!String(object.contentType || "").startsWith("video/")) return;

  const db = getFirestore();
  const bucket = getStorage().bucket(object.bucket);
  const episodeRef = db.collection("dramas").doc(dramaId).collection("episodes").doc(episodeId);
  const workDir = await mkdtemp(path.join(tmpdir(), "auvyqora-hls-"));
  const inputPath = path.join(workDir, "source-video");
  const outputDir = path.join(workDir, "hls");
  const maxBytes = 1024 * 1024 * 1024;

  try {
    if (Number(object.size || 0) > maxBytes) {
      throw new Error("ไฟล์วิดีโอมีขนาดเกิน 1 GB");
    }
    await episodeRef.set({
      uploadStatus: "processing",
      uploadError: FieldValue.delete(),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });

    await mkdir(outputDir, { recursive: true });
    await bucket.file(objectPath).download({ destination: inputPath });
    const playlistPath = path.join(outputDir, "index.m3u8");
    const segmentPattern = path.join(outputDir, "segment_%03d.ts");
    await runFfmpeg([
      "-y", "-i", inputPath,
      "-vf", "scale=-2:720",
      "-c:v", "libx264", "-preset", "veryfast", "-crf", "23",
      "-c:a", "aac", "-b:a", "128k",
      "-f", "hls", "-hls_time", "6", "-hls_playlist_type", "vod",
      "-hls_flags", "independent_segments",
      "-hls_segment_filename", segmentPattern,
      playlistPath,
    ]);

    const bucketName = bucket.name;
    const names = await readdir(outputDir);
    const segmentNames = names.filter((name) => name.endsWith(".ts")).sort();
    if (segmentNames.length === 0) throw new Error("ไม่พบไฟล์ HLS segment หลังแปลงวิดีโอ");

    for (const segmentName of segmentNames) {
      const outputPath = "hls/" + dramaId + "/" + episodeId + "/" + segmentName;
      await bucket.file(outputPath).save(await readFile(path.join(outputDir, segmentName)), {
        resumable: false,
        metadata: {
          contentType: "video/mp2t",
          cacheControl: "public,max-age=31536000,immutable",
        },
      });
    }

    const playlistToken = randomUUID();
    const localPlaylist = await readFile(playlistPath, "utf8");

    const segmentTokens = new Map();
    for (const segmentName of segmentNames) segmentTokens.set(segmentName, randomUUID());
    const finalPlaylist = localPlaylist.split(/\r?\n/).map((line) => {
      const segmentName = line.trim();
      if (!segmentName.endsWith(".ts")) return line;
      const token = segmentTokens.get(segmentName);
      return storageDownloadUrl(bucketName, "hls/" + dramaId + "/" + episodeId + "/" + segmentName, token);
    }).join("\n");

    for (const segmentName of segmentNames) {
      const token = segmentTokens.get(segmentName);
      await bucket.file("hls/" + dramaId + "/" + episodeId + "/" + segmentName).setMetadata({
        metadata: { firebaseStorageDownloadTokens: token },
      });
    }

    const hlsObjectPath = "hls/" + dramaId + "/" + episodeId + "/index.m3u8";
    await bucket.file(hlsObjectPath).save(finalPlaylist, {
      resumable: false,
      metadata: {
        contentType: "application/vnd.apple.mpegurl",
        cacheControl: "public,max-age=300",
        metadata: { firebaseStorageDownloadTokens: playlistToken },
      },
    });

    await episodeRef.set({
      hlsUrl: storageDownloadUrl(bucketName, hlsObjectPath, playlistToken),
      uploadStatus: "ready",
      uploadError: FieldValue.delete(),
      transcodedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    console.log("HLS transcode complete", { dramaId, episodeId, segmentCount: segmentNames.length });
  } catch (error) {
    console.error("HLS transcode failed", objectPath, error);
    await episodeRef.set({
      uploadStatus: "failed",
      uploadError: String(error && error.message ? error.message : error).slice(0, 500),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  } finally {
    await rm(workDir, { recursive: true, force: true });
  }
});


// Remove generated media when an episode is deleted. Source uploads are removed when
// their object path was recorded by the Admin upload flow.
exports.cleanupDeletedEpisodeMedia = onDocumentDeleted(
  "dramas/{dramaId}/episodes/{episodeId}",
  async (event) => {
    const before = event.data && event.data.data();
    if (!before) return;
    const { dramaId, episodeId } = event.params;
    const bucket = getStorage().bucket();
    const hlsPrefix = "hls/" + dramaId + "/" + episodeId + "/";
    const [hlsFiles] = await bucket.getFiles({ prefix: hlsPrefix });
    if (hlsFiles.length) {
      await Promise.all(hlsFiles.map((file) => file.delete().catch((error) => {
        if (error.code !== 404) throw error;
      })));
    }
    const sourcePath = before.sourceObjectPath;
    if (typeof sourcePath === "string" && sourcePath.startsWith("uploads/")) {
      await bucket.file(sourcePath).delete().catch((error) => {
        if (error.code !== 404) throw error;
      });
    }
    console.log("Deleted episode media cleanup complete", { dramaId, episodeId, hlsFiles: hlsFiles.length });
  }
);
