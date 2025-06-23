/* Delete all anonymous Firebase Auth users.
 * Usage:
 *  1. Install dependencies: npm install firebase-admin
 *  2. Export your service-account json path:  export GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json
 *  3. Run: node scripts/delete_anon_users.js
 */

const admin = require('firebase-admin');

// Initialize using GOOGLE_APPLICATION_CREDENTIALS env var
admin.initializeApp();

async function deleteAnonymous(nextPageToken) {
  const list = await admin.auth().listUsers(1000, nextPageToken);
  const anon = list.users.filter((u) => u.providerData.length === 0).map((u) => u.uid);
  if (anon.length) {
    const res = await admin.auth().deleteUsers(anon);
    console.log(`Deleted ${res.successCount} anon users, failures: ${res.failureCount}`);
  }
  if (list.pageToken) {
    await deleteAnonymous(list.pageToken);
  }
}

deleteAnonymous().then(() => {
  console.log('Done.');
  process.exit(0);
}).catch((e) => {
  console.error(e);
  process.exit(1);
}); 