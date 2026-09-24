const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { FieldValue, getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();
const db = getFirestore();
const region = 'asia-southeast1';

async function requireOwner(request) {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Vui lòng đăng nhập.');
  const profile = await db.collection('admins').doc(request.auth.uid).get();
  if (!profile.exists || profile.data().role !== 'owner' || profile.data().disabled === true) {
    throw new HttpsError('permission-denied', 'Chỉ chủ shop được quản lý nhân viên.');
  }
}

exports.onBookingCreated = onDocumentCreated(
  { document: 'bookings/{bookingId}', region },
  async (event) => {
    const booking = event.data?.data();
    if (!booking) return;
    const tokenDocs = await db.collection('admin_tokens').where('enabled', '==', true).get();
    const tokens = tokenDocs.docs.map((doc) => doc.data().token).filter(Boolean);
    for (let index = 0; index < tokens.length; index += 500) {
      const batchTokens = tokens.slice(index, index + 500);
      const response = await getMessaging().sendEachForMulticast({
        tokens: batchTokens,
        notification: {
          title: `Lịch hẹn mới — ${booking.name}`,
          body: `${booking.type === 'domay' ? 'Đo may' : 'Tư vấn'} · ${booking.date} lúc ${booking.time}`,
        },
        data: { bookingId: event.params.bookingId, screen: 'detail' },
        android: { priority: 'high', notification: { channelId: 'new_bookings' } },
      });
      const invalid = [];
      response.responses.forEach((result, offset) => {
        const code = result.error?.code;
        if (code === 'messaging/registration-token-not-registered' || code === 'messaging/invalid-registration-token') {
          invalid.push(batchTokens[offset]);
        }
      });
      if (invalid.length) {
        const cleanup = db.batch();
        invalid.forEach((token) => cleanup.delete(db.collection('admin_tokens').doc(token)));
        await cleanup.commit();
      }
    }
  },
);

exports.createAdminUser = onCall({ region }, async (request) => {
  await requireOwner(request);
  const { email, password, role = 'staff' } = request.data || {};
  if (typeof email !== 'string' || typeof password !== 'string' || password.length < 10 || !['admin', 'staff'].includes(role)) {
    throw new HttpsError('invalid-argument', 'Email, mật khẩu tối thiểu 10 ký tự hoặc vai trò chưa hợp lệ.');
  }
  const user = await getAuth().createUser({ email: email.trim().toLowerCase(), password, disabled: false });
  await db.collection('admins').doc(user.uid).set({
    email: user.email,
    role,
    disabled: false,
    createdAt: FieldValue.serverTimestamp(),
    createdBy: request.auth.uid,
  });
  return { uid: user.uid, email: user.email, role };
});

exports.disableAdminUser = onCall({ region }, async (request) => {
  await requireOwner(request);
  const { uid } = request.data || {};
  if (typeof uid !== 'string' || uid === request.auth.uid) {
    throw new HttpsError('invalid-argument', 'Không thể vô hiệu hóa tài khoản này.');
  }
  const profile = await db.collection('admins').doc(uid).get();
  if (!profile.exists || profile.data().role === 'owner') {
    throw new HttpsError('failed-precondition', 'Không thể vô hiệu hóa tài khoản owner.');
  }
  await getAuth().updateUser(uid, { disabled: true });
  await db.collection('admins').doc(uid).set({ disabled: true, disabledAt: FieldValue.serverTimestamp() }, { merge: true });
  const tokens = await db.collection('admin_tokens').where('uid', '==', uid).get();
  const batch = db.batch();
  tokens.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
  return { disabled: true };
});
