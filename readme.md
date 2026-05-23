# 🏥 Healink — On-Demand Healthcare & Caregiving App

> **Flutter · Firebase · Dart**  
> Final Project — Mobile App Development  
> UN SDG Goal 3: Good Health and Well-being

---

## 📋 Overview

Healink adalah aplikasi mobile on-demand untuk layanan kesehatan rumahan, mirip model Gojek/Traveloka. Pengguna bisa browse dan memesan caregiver, menjadwalkan konsultasi rumah sakit, dan memesan obat — semuanya dalam satu aplikasi.

**Tech Stack:**
- Framework: Flutter (Dart)
- Backend: Firebase (Auth, Firestore, Cloud Messaging)
- Architecture: Feature-Driven

---

## 👥 Tim & Pembagian Modul

| Nama | Modul | Fitur |
|---|---|---|
| Student A | Caregiver Booking | Browse, booking, accept/decline, profil caregiver |
| Student B | Hospital & Appointment | Penjadwalan klinik, sistem seat |
| Student C | Pharmacy & Delivery | Katalog obat, keranjang, openFDA API |

---

## 🔐 Role & Akun Test

Healink menggunakan **3 jenis role**:

### 1. 👑 Super Admin
Akses: Dashboard statistik, semua booking, semua mitra terdaftar.

```
Email    : admin@mail.com
Password : 123456
```
> ⚠️ Akun admin dibuat manual di Firebase Console → Authentication → Add user.  
> Tidak ada tombol Register untuk admin.

---

### 2. 👤 User (Pengguna / Keluarga)
Akses: Browse caregiver tanpa login, pesan caregiver setelah login.

**Cara daftar:**
1. Buka app → tap **Sign In** (pojok kanan atas)
2. Tap **Daftar sebagai Pengguna**
3. Isi nama, email, password → selesai

---

### 3. 🏷️ Mitra (Caregiver / RS / Farmasi)
Akses: Kelola profil sendiri, lihat & manage request masuk.

**Cara daftar sebagai Caregiver:**
1. Tap **Sign In** → **Daftar sebagai Mitra**
2. Pilih **Caregiver**
3. Isi informasi akun + profil (spesialisasi, harga/jam, daerah, bio)
4. Tap **Daftar sebagai Mitra**

---

## 🚀 Setup untuk Tim (Clone & Run)

### Prasyarat
- Flutter SDK ≥ 3.24
- Android Studio / VS Code
- Android Emulator atau device fisik

### Langkah Setup

**1. Clone repo**
```bash
git clone <link-repo-github>
cd FP-MobileDev
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Taruh file Firebase (minta ke Student A)**

| File | Lokasi |
|---|---|
| `firebase_options.dart` | `lib/` |
| `google-services.json` | `android/app/` |

**4. Jalankan app**
```bash
flutter run
```

---

## 🗂️ Struktur Folder

```
lib/
├── main.dart                        # Entry point + AppGate (role router)
├── firebase_options.dart            # ⚠️ TIDAK di-commit (ada di .gitignore)
├── core/
│   ├── constants/
│   │   ├── app_colors.dart          # Color palette
│   │   └── app_theme.dart           # Material 3 theme
│   └── utils/
│       └── date_utils.dart          # Date formatter helpers
├── features/
│   ├── auth/                        # Login, Register (User & Mitra)
│   ├── home/                        # HomeScreen (browse tanpa login)
│   ├── admin/                       # Admin Dashboard
│   ├── dashboard/                   # RoleRouterScaffold
│   ├── caregiver_booking/           # 🟦 Student A
│   ├── hospital_appointment/        # 🟩 Student B
│   └── pharmacy_delivery/           # 🟥 Student C
```

---

## 📱 Alur Aplikasi

```
App Launch
    │
    ▼
HomeScreen (tanpa login)
    ├── Browse & search caregiver
    ├── Lihat profil caregiver
    └── Tap "Instant Book"
            ├── Belum login → Bottom sheet "Masuk dulu"
            └── Sudah login → Form booking (tanggal, jam, notes)

Sign In / Daftar
    ├── Pengguna biasa → HomeScreen (bisa booking)
    ├── Caregiver → Dashboard (Requests + Edit Profil)
    └── Admin → Admin Panel (statistik + semua data)
```

---

## 🔥 Firebase Collections

| Collection | Isi |
|---|---|
| `/users/{uid}` | Semua user (role, name, email) |
| `/caregivers/{uid}` | Profil caregiver (spesialisasi, harga, area) |
| `/bookings/{id}` | Booking caregiver (status: pending→accepted→completed) |
| `/appointments/{id}` | 🟩 Student B — jadwal RS |
| `/medicines/{id}` | 🟥 Student C — katalog obat |
| `/orders/{id}` | 🟥 Student C — order farmasi |

---

## 📄 Dokumentasi Lengkap

Lihat **[prd.md](./prd.md)** untuk:
- Product Requirement Document (PRD) lengkap
- CRUD mapping per modul
- Database schema Firestore
- Arsitektur & folder structure detail
- Sprint schedule 4 minggu
- Defensive testing strategy

---

## 🛡️ Catatan Keamanan

- `firebase_options.dart` dan `google-services.json` **tidak di-commit** ke repo publik ini
- File tersebut berisi API key Firebase — minta langsung ke Student A via DM
- Firestore Security Rules: **test mode** (30 hari) — ganti sebelum presentasi
