// Chạy một lần sau khi thiết lập GOOGLE_APPLICATION_CREDENTIALS:
// node migrate_sqlite.js C:\duong-dan\data\phuong-dong.sqlite
const path = require('node:path');
const { DatabaseSync } = require('node:sqlite');
const { Timestamp } = require('firebase-admin/firestore');
const { getFirestore } = require('firebase-admin/firestore');
require('./index');

const source = process.argv[2];
if (!source) throw new Error('Thiếu đường dẫn file SQLite.');
const sqlite = new DatabaseSync(path.resolve(source), { readOnly: true });
const rows = sqlite.prepare('SELECT * FROM orders ORDER BY id').all();
const firestore = getFirestore();

function status(value) {
  if (value === 0) return 'pending';
  if (value === 6) return 'completed';
  return 'confirmed';
}

async function migrate() {
  for (let offset = 0; offset < rows.length; offset += 400) {
    const batch = firestore.batch();
    for (const row of rows.slice(offset, offset + 400)) {
      const config = JSON.parse(row.config_json || '{}');
      const total = Number(row.quote || 0);
      const booking = {
        id: row.code,
        type: 'domay',
        name: row.full_name,
        phone: row.phone_number,
        email: row.email || '',
        product: `Vest ${config.fabric || ''}`.trim(),
        budget: total ? String(total) : '',
        note: row.notes || '',
        date: row.preferred_date,
        time: row.preferred_time,
        status: status(Number(row.status)),
        payMethod: row.paid_total > 0 ? 'Đã ghi nhận trên hệ thống cũ' : '',
        quote: total ? { type: 'Vest may đo', fabric: config.fabric || '', qty: 1, unitPrice: total, total, deposit: Number(row.deposit_required || 0) } : null,
        adminNote: row.internal_note || '',
        createdAt: Timestamp.fromDate(new Date(row.created_at)),
        updatedAt: Timestamp.now(),
        statusHistory: [{ status: status(Number(row.status)), at: Timestamp.now(), by: 'sqlite-migration' }],
      };
      batch.set(firestore.collection('bookings').doc(row.code), booking, { merge: false });
    }
    await batch.commit();
  }
  sqlite.close();
  console.log(`Đã chuyển ${rows.length} lịch hẹn sang Firestore.`);
}

migrate().catch((error) => { console.error(error); process.exitCode = 1; });
