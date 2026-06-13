# 🏥 Healink — On-Demand Healthcare & Caregiving App

> **Flutter · Firebase · Dart** | Final Project Mobile App Development
> UN SDG Goal 3: Good Health and Well-being

---

## 📋 Overview

Healink adalah aplikasi mobile on-demand untuk layanan kesehatan rumahan, mirip model Gojek/Traveloka. Pengguna bisa browse dan memesan **caregiver**, menjadwalkan konsultasi **rumah sakit**, dan memesan **obat** — semuanya dalam satu aplikasi.

---

## 👥 Tim & Modul

| Student | Modul | Folder | Docs |
|---|---|---|---|
| **Baihaqi** (Student A) | Caregiver Booking | `lib/features/caregiver_booking/` | [📄 BAIHAQI.md](./BAIHAQI.md) |
| Student B | Hospital & Appointment | `lib/features/hospital_appointment/` | — |
| Student C | Pharmacy & Delivery | `lib/features/pharmacy_delivery/` | — |

---

## 🔐 Role & Cara Masuk

### 👑 Super Admin
Dashboard: statistik, semua booking, semua mitra, full CRUD.

```
Email    : admin@mail.com
Password : 123456
```
> Buat akun di **Firebase Console → Authentication → Add user** (tidak ada tombol Register di app).

---

### 👤 User (Pengguna)
Browse & pesan caregiver. Tidak perlu login untuk browse — login hanya saat mau memesan.

**Cara daftar:**
1. Buka app → tap **Sign In** (pojok kanan atas)
2. Tap **Daftar sebagai Pengguna**
3. Isi nama, email, password

---

### 🏷️ Mitra Caregiver
Daftar, isi profil, terima & manage pesanan dari pengguna.

**Cara daftar:**
1. Tap **Sign In** → **Daftar sebagai Mitra**
2. Pilih **Caregiver**
3. Isi: nama, email, password, spesialisasi, harga/jam, daerah, bio
4. Setelah login → profil muncul di list caregiver untuk dipesan user

---

## 🚀 Setup Tim (Clone & Run)

### Prasyarat
- Flutter SDK ≥ 3.24 · Android Studio / VS Code · Emulator / Device

### Langkah

```bash
# 1. Clone
git clone <link-repo-github>
cd FP-MobileDev

# 2. Install dependencies
flutter pub get

# 3. Taruh file Firebase (minta Student A via WA)
#    - lib/firebase_options.dart
#    - android/app/google-services.json

# 4. Jalankan
flutter run
```

---

## 📱 Alur Aplikasi

```
App buka → HomeScreen (tanpa login)
  ├── [Health AI Chat] → Health Assistant Chatbot (Groq AI)
  ├── [Caregiver] → CaregiverListScreen → Profil → Pesan
  │         └── Belum login? → Bottom sheet "Sign In dulu"
  ├── [Rumah Sakit] → FamilyHospitalSchedulerScreen (Student B)
  └── [Farmasi] → PharmacyListScreen (Student C)

Sign In
  ├── Pengguna → HomeScreen (bisa langsung pesan)
  ├── Caregiver → Dashboard (Tab: Pesanan | Riwayat | Edit Profil + Upload Foto)
  ├── Hospital  → HospitalAdminDashboardScreen (Student B)
  ├── Pharmacy  → PharmacyOrderIntakeScreen (Student C)
  └── Admin → Admin Panel
```

---

## 🗂️ Folder Structure

```
lib/
├── main.dart                     # Entry + AppGate (routing by role)
├── core/constants/               # AppColors, AppTheme
├── features/
│   ├── auth/                     # Login, UserRegister, MitraRegister
│   ├── home/                     # HomeScreen (Gojek-style)
│   ├── admin/                    # AdminDashboardScreen
│   ├── dashboard/                # RoleRouterScaffold
│   ├── caregiver_booking/        # 🟦 Student A
│   ├── hospital_appointment/     # 🟩 Student B
│   └── pharmacy_delivery/        # 🟥 Student C
```

---

## 🔥 Firestore Collections

| Collection | Dibuat Oleh | Isi |
|---|---|---|
| `/users/{uid}` | Auth (semua) | role, name, email |
| `/caregivers/{uid}` | Caregiver saat register | profil, harga, daerah |
| `/bookings/{id}` | User saat booking | status: pending→accepted→completed |
| `/appointments/{id}` | Student B | jadwal RS |
| `/medicines/{id}` | Student C | katalog obat |
| `/orders/{id}` | Student C | order farmasi |

---

## 📄 PRD Lengkap

Lihat [prd.md](./prd.md) untuk CRUD mapping, database schema, sprint schedule, dan defensive testing strategy.

---

## ⚠️ Keamanan

`firebase_options.dart` dan `google-services.json` **tidak ada di repo ini** (di `.gitignore`).
Minta file ke Baihaqi via DM/WA untuk setup lokal.

---

## 📄 Kontribusi Individu

- [🟦 Baihaqi — Caregiver Booking](./BAIHAQI.md) — CRUD, Firebase Storage, Groq AI, Push Notification
