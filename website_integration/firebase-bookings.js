import { initializeApp } from 'firebase/app';
import { doc, getFirestore, serverTimestamp, setDoc } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

function createCode() {
  const bytes = crypto.getRandomValues(new Uint8Array(6));
  return `PD-${[...bytes].map((value) => alphabet[value % alphabet.length]).join('')}`;
}

/**
 * Tạo lịch hẹn từ website khách. Firestore Rules chỉ cho phép CREATE với
 * status pending; website không có quyền đọc, sửa hoặc xóa collection này.
 */
export async function createFirebaseBooking(input) {
  const id = createCode();
  const booking = {
    id,
    type: input.type === 'domay' ? 'domay' : 'tuvan',
    name: String(input.name || input.fullName || '').trim(),
    phone: String(input.phone || input.phoneNumber || '').trim(),
    email: String(input.email || '').trim().toLowerCase(),
    product: String(input.product || input.config?.fabric || '').trim(),
    budget: String(input.budget || '').trim(),
    note: String(input.note || input.notes || '').trim(),
    date: String(input.date || input.preferredDate || ''),
    time: String(input.time || input.preferredTime || ''),
    status: 'pending',
    payMethod: String(input.payMethod || '').trim(),
    quote: null,
    adminNote: '',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    statusHistory: [],
  };
  await setDoc(doc(db, 'bookings', id), booking);
  return { ...booking, createdAt: new Date().toISOString(), updatedAt: new Date().toISOString() };
}
