# Kontribusi Individu — Baihaqi

> **Modul:** Caregiver Booking System
> **Folder:** `lib/features/caregiver_booking/`
> **SDG:** Goal 3 — Good Health and Well-Being

---

## Deskripsi Fitur

Modul **Caregiver Booking** adalah sistem pemesanan tenaga perawat (*caregiver*) on-demand untuk keperluan rumahan — merawat lansia, pasien pasca operasi, atau orang dengan kebutuhan khusus.

Fitur ini menghubungkan tiga sisi pengguna:
- **Family/User** — browse caregiver, lihat profil lengkap, buat booking, pantau status, beri ulasan
- **Caregiver (Mitra)** — terima/tolak/selesaikan pesanan real-time, edit profil + foto, lihat riwayat
- **Super Admin** — pantau semua booking & mitra, block/unblock caregiver, hapus mitra, tangani laporan

Seluruh alur berjalan end-to-end: Flutter → Firebase Firestore + FCM, dengan bonus integrasi **Groq Cloud AI** sebagai Health Assistant Chatbot dan **Supabase Storage** untuk upload foto profil.

---

## Pemenuhan Kriteria Penilaian

### 2.1 Core Requirements

| Kriteria | Status | Bukti |
|----------|--------|-------|
| Individual feature (end-to-end cloud ↔ mobile) | Terpenuhi | Booking flow: Flutter → Firestore → FCM push notification real-time |
| SDG alignment | Terpenuhi | SDG 3: Good Health and Well-Being (lihat bagian SDG di bawah) |
| Full CRUD | Terpenuhi | Lihat tabel CRUD lengkap di bawah |
| Version control (GitHub) | Terpenuhi | Semua commit di repo grup |
| User Authentication | Terpenuhi | Firebase Auth — login/register user & caregiver (tidak dihitung sebagai fitur individual) |
| Cloud Infrastructure | Terpenuhi | Firebase Firestore + Supabase Storage + FCM |
| External API | Terpenuhi | Groq Cloud AI (LLM) — `groq_service.dart` |

### 2.2 AI Policy

Penggunaan AI tools untuk code generation diizinkan. Fitur ini dipahami secara menyeluruh dan dapat di-debug secara langsung.

Selama demo dosen akan memodifikasi beberapa baris kode — evaluator siap mendiagnosis dan memperbaiki secara on-the-spot karena logika bisnis tiap method dikuasai penuh:
- `updateBookingStatus()` → state machine pending → accepted/cancelled → completed
- `sendNotificationToUser()` → FCM HTTP V1 dengan JWT dari service account
- `StreamBuilder` pattern → real-time Firestore listener tanpa polling

### 2.3 Technical Requirements

| Requirement | Status | Implementasi |
|-------------|--------|--------------|
| Firebase Authentication | Terpenuhi | Login, register user & caregiver via `AuthProvider` |
| Cloud Firestore | Terpenuhi | CRUD booking, profil caregiver, review, laporan — semua real-time stream |
| Push Notifications (FCM) | Terpenuhi | Notifikasi dua arah: booking baru → caregiver, diterima/ditolak → family |
| Navigation Bar | Terpenuhi | Bottom nav 4 tab (Beranda, Caregiver, Pesanan, AI Chat) di `home_screen.dart` |
| **BONUS:** Cloud Storage | Terpenuhi | Upload foto profil caregiver ke **Supabase Storage** → `uploadProfilePhoto()` |

---

## Full CRUD — Lengkap Semua Role

### Dari Sisi User/Family

| Operasi | Fitur | File & Method |
|---------|-------|---------------|
| **C — Create** | Buat booking ke caregiver (pilih tanggal, jam, catatan) | `caregiver_detail_screen.dart` → `_submitBooking()` → `createBooking()` |
| **C — Create** | Buat laporan terhadap caregiver | `my_bookings_screen.dart` → `_showReportDialog()` → `submitReport()` |
| **C — Create** | Beri ulasan + rating setelah booking selesai | `my_bookings_screen.dart` → `_showReviewDialog()` → `submitReview()` |
| **R — Read** | Browse daftar caregiver (filter spesialisasi, area, harga, rating) | `caregiver_list_screen.dart` → `getCaregivers()` |
| **R — Read** | Lihat detail profil caregiver (foto, bio, rating, harga) | `caregiver_detail_screen.dart` |
| **R — Read** | Pantau semua booking sendiri secara real-time | `my_bookings_screen.dart` → `getBookingsByFamily()` |
| **U — Update** | Submit ulasan mengupdate `rating` & `totalReviews` caregiver | `admin_service.dart` → `submitReview()` |
| **D — Delete** | Batalkan booking yang masih pending (soft delete → status cancelled) | `my_bookings_screen.dart` → `_confirmCancel()` → `cancelBooking()` |
| **D — Delete** | Hapus riwayat booking dari daftar (hard delete Firestore) | `my_bookings_screen.dart` → `_confirmDelete()` → `deleteBookingHistory()` |

### Dari Sisi Caregiver (Mitra)

| Operasi | Fitur | File & Method |
|---------|-------|---------------|
| **C — Create** | Buat laporan terhadap user/family | `caregiver_dashboard_screen.dart` → `_showReportUserDialog()` → `submitReport()` |
| **R — Read** | Lihat semua booking aktif (pending + accepted) secara real-time | `caregiver_dashboard_screen.dart` Tab Requests → `getActiveBookingsByCaregiver()` |
| **R — Read** | Lihat riwayat booking selesai & dibatalkan | `caregiver_dashboard_screen.dart` Tab Riwayat → `getCompletedBookingsByCaregiver()` |
| **R — Read** | Lihat & edit profil sendiri secara real-time | `caregiver_dashboard_screen.dart` Tab Profil → `getCaregiverProfileStream()` |
| **U — Update** | Terima booking (pending → accepted) + kirim notifikasi ke family | `caregiver_dashboard_screen.dart` → `_acceptBooking()` → `updateBookingStatus()` |
| **U — Update** | Tolak booking (pending → cancelled) + kirim notifikasi ke family | `caregiver_dashboard_screen.dart` → `_confirmDecline()` → `updateBookingStatus()` |
| **U — Update** | Tandai booking selesai + isi catatan klinis (accepted → completed) | `caregiver_dashboard_screen.dart` → `_showCompleteDialog()` → `completeBookingWithNote()` |
| **U — Update** | Edit profil lengkap (nama, spesialisasi, harga, area, bio, availability) | `caregiver_dashboard_screen.dart` → `_saveProfile()` → `updateCaregiverProfile()` |
| **U — Update** | Upload/ganti foto profil dari galeri (simpan ke Supabase Storage) | `caregiver_dashboard_screen.dart` → `_pickAndUploadPhoto()` → `uploadProfilePhoto()` |
| **D — Delete** | Hapus riwayat booking selesai/batal dari daftar (hard delete) | `caregiver_dashboard_screen.dart` Tab Riwayat → `_confirmDeleteHistory()` → `deleteBookingHistory()` |

### Dari Sisi Super Admin

| Operasi | Fitur | File & Method |
|---------|-------|---------------|
| **R — Read** | Overview statistik: total booking, pending, jumlah caregiver, jumlah user | `admin_dashboard_screen.dart` → `_OverviewTab` |
| **R — Read** | Lihat 10 booking terbaru secara real-time | `admin_dashboard_screen.dart` → Firestore stream |
| **R — Read** | Lihat semua mitra caregiver + status (aktif/blocked) | `admin_dashboard_screen.dart` → `getCaregiversStream()` |
| **R — Read** | Lihat & proses laporan pengguna | `admin_reports_screen.dart` → `getPendingReportsStream()` |
| **U — Update** | Block/unblock mitra caregiver | `admin_dashboard_screen.dart` → `blockCaregiver()` |
| **U — Update** | Force cancel booking manapun + alasan admin | `admin_dashboard_screen.dart` → `forceCancelBooking()` |
| **D — Delete** | Hapus akun mitra caregiver secara permanen | `admin_dashboard_screen.dart` → `deleteCaregiver()` |

---

## End-to-End Cloud Connection

```
Flutter App
  └─► Firebase Auth       → login, register caregiver/user/admin
  └─► Cloud Firestore     → CRUD booking & profil caregiver (real-time stream)
  └─► Supabase Storage    → upload & serve foto profil caregiver
  └─► FCM HTTP V1 API     → push notification dua arah (caregiver ↔ family)
  └─► Groq Cloud API      → AI health chatbot (external LLM API)
```

**Seluruh flow tidak ada dummy data** — caregiver muncul di listing hanya setelah register nyata, booking hanya muncul setelah user benar-benar melakukan pemesanan.

---

## Bonus: Cloud Storage (Supabase)

Caregiver dapat mengupload foto profil dari galeri HP:
- Gambar diambil via `image_picker`, dikompres (quality 40%, max 400px)
- Upload ke Supabase Storage path: `caregivers/profile_{uid}.jpg`
- Public URL disimpan ke Firestore field `photoUrl`
- Ditampilkan di listing caregiver (`caregiver_card.dart`) dan halaman detail (`caregiver_detail_screen.dart`)

**Implementasi:** `caregiver_firestore_service.dart` → `uploadProfilePhoto()`

---

## External API — Groq Cloud AI

Integrasi **Groq Cloud (LLM API)** sebagai Health Assistant Chatbot:
- Endpoint: `https://api.groq.com/openai/v1/chat/completions`
- Model: `llama-3.1-8b-instant` (gratis, tercepat di Groq)
- Fungsi: Pengguna bertanya jenis caregiver yang cocok untuk kondisi pasien
- Relevansi SDG 3: Memperluas akses informasi kesehatan

**Implementasi:** `groq_service.dart`, `health_chatbot_screen.dart`
**Entry point:** Banner "Health Assistant AI" di `home_screen.dart`
**Konfigurasi:** `app_config.dart` → `AppConfig.groqApiKey`

---

## Push Notification (Dua Arah)

| Event | Arah | Isi Notifikasi |
|-------|------|----------------|
| Family buat booking | App → Caregiver | "Booking Baru! [familyName] memesan layanan [spesialisasi] kamu." |
| Caregiver **terima** booking | App → Family | "Booking Diterima! Caregiver [nama] telah menerima booking kamu." |
| Caregiver **tolak** booking | App → Family | "Booking Ditolak. Silakan pilih caregiver lain." |

**Implementasi:** `notification_service.dart` → `sendNotificationToUser(targetUid:, title:, body:, data:)`
Menggunakan FCM HTTP V1 API dengan JWT dari Firebase Service Account.

**Demo notifikasi:**
- Caregiver dashboard → Tab Profil → copy FCM Token → paste ke Firebase Console → Cloud Messaging → Send test message
- Atau gunakan 2 emulator / 1 emulator + 1 HP asli untuk demo end-to-end

---

## Struktur File Modul

```
lib/features/caregiver_booking/
├── models/
│   ├── booking_model.dart                # BookingModel + BookingStatus enum
│   └── caregiver_profile_model.dart      # CaregiverProfileModel (nama, harga, photoUrl, dll)
├── services/
│   ├── caregiver_firestore_service.dart  # Semua CRUD Firestore + Supabase photo upload
│   └── groq_service.dart                 # Groq Cloud AI HTTP client (external API)
├── screens/
│   ├── caregiver_list_screen.dart        # Daftar caregiver + search + sort (family view)
│   ├── caregiver_detail_screen.dart      # Detail profil + form booking + riwayat per caregiver
│   ├── caregiver_dashboard_screen.dart   # Dashboard mitra (3 tab: Requests | Profil | Riwayat)
│   ├── my_bookings_screen.dart           # Semua booking family + cancel + review + hapus
│   └── health_chatbot_screen.dart        # AI Health Assistant chatbot UI
└── widgets/
    ├── caregiver_card.dart               # Card listing (foto, rating, harga, area)
    └── status_badge.dart                 # Badge status booking (pending/accepted/completed/dll)
```

**Catatan file:**
- `caregiver_dashboard_screen.dart` mengandung 3 tab sekaligus: Requests (active queue), Profil (edit), dan Riwayat (history + delete)
- Tidak ada seed/dummy data — semua muncul dari register & transaksi nyata

---

## SDG Alignment

**SDG 3: Good Health and Well-Being**

| Sub-target SDG 3 | Implementasi di Fitur |
|---|---|
| 3.8 — Akses layanan kesehatan universal | Platform menghubungkan keluarga langsung dengan tenaga perawat profesional |
| 3.c — Tenaga kesehatan terlatih | Caregiver mendaftar dengan spesialisasi (Elderly Care, Post-Surgery, Pediatric, dll) |
| 3.d — Informasi kesehatan | AI Health Chatbot membantu pengguna memilih jenis caregiver sesuai kondisi pasien |
| Keterjangkauan | Harga per jam transparan, bisa di-sort dan dibandingkan antar caregiver |

---

## Cara Menjalankan Fitur

### Sebagai Family (User):
1. Buka app → tap **Caregiver** di navbar atau quick action
2. Browse daftar, filter/sort berdasarkan harga atau rating
3. Tap caregiver → lihat profil lengkap + foto → isi tanggal, jam, catatan → **Kirim Booking**
4. Pantau status di tab **Pesanan** (bottom nav)
5. Booking pending → bisa **Batalkan**; booking selesai → **Beri Ulasan** atau **Hapus Riwayat**

### Sebagai Caregiver (Mitra):
1. Sign In → **Daftar sebagai Mitra** → pilih Caregiver → isi semua field
2. Tab **Profil Saya** → upload foto, atur availability toggle → **Simpan Profil**
3. Tab **Requests** → terima (Terima) atau tolak (Tolak) booking yang masuk
4. Booking accepted → tap **Tandai Selesai** → isi catatan klinis
5. Tab **Riwayat** → lihat semua booking completed/cancelled → tap **Hapus Riwayat** untuk menghapus

### Sebagai Super Admin:
1. Login dengan `admin@mail.com` / `123456`
2. Tab **Overview** → pantau statistik + booking terbaru + daftar mitra
3. Mitra → ikon titik tiga → **Block/Unblock** atau **Hapus Mitra**
4. Tab **Laporan** → proses laporan dari user/caregiver

---

## Catatan Teknis

- **Double-booking guard:** Sistem menolak booking baru jika sudah ada booking aktif (pending/accepted) dengan caregiver yang sama
- **Clinical note:** Caregiver wajib mengisi catatan klinis saat tandai selesai — disimpan ke field `clinicalNote` di Firestore
- **Real-time UI:** Semua data booking & profil menggunakan `StreamBuilder` — update otomatis tanpa pull-to-refresh
- **Photo fallback:** Foto caregiver ditampilkan di listing dan halaman detail; fallback ke initial huruf nama jika foto gagal load
- **FCM token debug card:** Muncul di bawah form profil caregiver — bisa di-copy langsung untuk test notifikasi via Firebase Console
- **Groq API key:** Konfigurasi di `lib/app_config.dart` → `AppConfig.groqApiKey`
- **Back navigation:** `CaregiverListScreen` menyembunyikan tombol back ketika diakses via bottom nav (mencegah black screen)
