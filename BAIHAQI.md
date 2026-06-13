# 🟦 Kontribusi Individu — Baihaqi (Student A)

> **Modul:** Caregiver Booking System  
> **Folder:** `lib/features/caregiver_booking/`  
> **SDG:** Goal 3 — Good Health and Well-Being

---

## 📌 Deskripsi Fitur

Modul **Caregiver Booking** adalah sistem pemesanan tenaga perawat (*caregiver*) on-demand untuk keperluan rumahan — seperti merawat lansia, pasien pasca operasi, atau orang dengan kebutuhan khusus.

Fitur ini menghubungkan dua sisi pengguna:
- **Family/User** → mencari caregiver berdasarkan spesialisasi dan area, melihat profil lengkap, lalu melakukan pemesanan
- **Caregiver (Mitra)** → mendaftar sebagai mitra, mengisi profil dan foto, menerima/menolak pesanan secara real-time

Seluruh alur berjalan end-to-end dari aplikasi Flutter ke Firebase (Firestore + Storage + FCM), disertai integrasi AI chatbot via Groq Cloud untuk membantu pengguna menentukan jenis caregiver yang dibutuhkan.

---

## ✅ Metrik Penilaian — Individual

### 1. Full CRUD (Create, Read, Update, Delete)

| Operasi | Implementasi | File |
|---|---|---|
| **Create** | Family submit booking baru ke caregiver | `caregiver_detail_screen.dart` → `createBooking()` |
| **Read** | Lihat daftar caregiver + detail profil, real-time stream | `caregiver_list_screen.dart`, `getCaregivers()` |
| **Update** | Caregiver terima/tolak/selesaikan booking; edit profil + upload foto | `caregiver_dashboard_screen.dart` → `updateBookingStatus()`, `updateCaregiverProfile()`, `uploadProfilePhoto()` |
| **Delete** | Family batalkan booking dengan status *pending* | `my_bookings_screen.dart` → `cancelBooking()` |

### 2. End-to-End Cloud ↔ Mobile Connection

```
Flutter App
  └─► Firebase Auth       (login, register caregiver/user)
  └─► Cloud Firestore     (CRUD booking & profil caregiver, real-time stream)
  └─► Firebase Storage    (upload foto profil caregiver → public URL)
  └─► FCM HTTP V1 API     (push notification ke caregiver & ke family)
  └─► Groq Cloud API      (AI chatbot kesehatan — external API)
```

### 3. Object Storage — Firebase Storage ✅

Caregiver dapat mengupload foto profil dari galeri HP:
- Upload ke Firebase Storage path: `caregiver_photos/{uid}/profile.jpg`
- Public download URL disimpan ke Firestore field `photoUrl`
- Ditampilkan di listing caregiver dan dashboard via `Image.network(url)`

**Implementasi:** `caregiver_firestore_service.dart` → `uploadProfilePhoto()`

### 4. External API — Groq Cloud AI ✅

Integrasi **Groq Cloud (LLM API)** sebagai Health Assistant Chatbot:
- Endpoint: `https://api.groq.com/openai/v1/chat/completions`
- Model: `llama-3.1-8b-instant` (gratis, tercepat)
- Fungsi: Pengguna dapat bertanya jenis caregiver yang cocok untuk kondisi pasien
- Relevansi SDG: Memperluas akses informasi kesehatan untuk masyarakat → SDG 3

**Implementasi:** `groq_service.dart`, `health_chatbot_screen.dart`  
**Entry point:** Banner "Health Assistant AI" di `home_screen.dart`  
**Konfigurasi:** `app_config.dart` → `AppConfig.groqApiKey`

### 5. Push Notification (Dua Arah) ✅

| Event | Arah | Isi Notifikasi |
|---|---|---|
| Family buat booking | App → Caregiver | "Ada permintaan booking baru!" |
| Caregiver **terima** booking | App → Family | "✅ Booking Diterima! Caregiver [nama] telah menerima booking kamu" |
| Caregiver **tolak** booking | App → Family | "❌ Booking Ditolak. Silakan pilih caregiver lain" |

**Implementasi:** `notification_service.dart` → `sendNotificationToUser(targetUid:, title:, body:, data:)`  
Menggunakan FCM HTTP V1 API dengan JWT dari Firebase Service Account.

### 6. User Authentication ✅

Caregiver wajib register via `MitraRegisterScreen` dengan role `caregiver`.  
**Tidak ada seed data / dummy** — semua data caregiver di Firestore berasal dari registrasi nyata.

---

## 📁 Struktur File Modul Caregiver

```
lib/features/caregiver_booking/
├── models/
│   ├── booking_model.dart           # Model booking (status, familyId, caregiverId, dll)
│   └── caregiver_profile_model.dart # Model profil caregiver (spesialisasi, harga, photoUrl)
├── services/
│   ├── caregiver_firestore_service.dart  # CRUD Firestore + Firebase Storage upload
│   └── groq_service.dart                # Groq Cloud AI HTTP service (external API)
├── screens/
│   ├── caregiver_list_screen.dart        # Daftar caregiver (family view)
│   ├── caregiver_detail_screen.dart      # Detail profil + form booking
│   ├── caregiver_dashboard_screen.dart   # Dashboard mitra (terima/tolak + edit profil + foto)
│   ├── caregiver_history_screen.dart     # Riwayat booking selesai/dibatalkan
│   ├── my_bookings_screen.dart           # Booking aktif family + cancel
│   └── health_chatbot_screen.dart        # AI Health Assistant chatbot UI
└── widgets/
    ├── caregiver_card.dart               # Card listing caregiver (foto, rating, harga)
    └── status_badge.dart                 # Badge status booking (pending/accepted/dll)
```

---

## 🔗 Integrasi dengan Modul Lain

- **Auth Module** (`features/auth/`) — `AuthProvider` menyimpan role dan session
- **Home Screen** (`features/home/`) — tombol Caregiver + banner Health AI Chatbot
- **Notification Service** (`core/services/`) — dipakai bersama semua modul
- **App Config** (`app_config.dart`) — Groq API key terpusat di sini

---

## 🌐 SDG Alignment

**SDG 3: Good Health and Well-Being**

| Sub-target | Implementasi di Fitur |
|---|---|
| Akses layanan kesehatan | Platform menghubungkan keluarga dengan tenaga perawat profesional |
| Tenaga kesehatan terlatih | Caregiver mendaftar dengan spesialisasi (Elderly Care, Post-Surgery, dll) |
| Informasi kesehatan | AI Health Chatbot memberikan panduan pemilihan caregiver berdasarkan kondisi pasien |
| Keterjangkauan | Harga per jam transparan dan dapat dibandingkan antar caregiver |

---

## 🗓️ Cara Menjalankan Fitur Caregiver

### Sebagai Family (User):
1. Buka app → tap "Caregiver" atau banner "Health AI 🤖"
2. Browse daftar caregiver, filter berdasarkan spesialisasi
3. Tap caregiver → lihat profil lengkap → isi form booking
4. Pantau status booking di "Pesananku"
5. Batalkan booking jika masih pending

### Sebagai Caregiver (Mitra):
1. Sign In → Daftar sebagai Mitra → pilih Caregiver
2. Isi profil: nama, spesialisasi, harga/jam, area, bio
3. Upload foto profil (tap avatar di tab Profil)
4. Tab "Requests" → terima atau tolak booking masuk
5. Tab "Riwayat" → lihat semua history booking

---

## 📌 Catatan Teknis

- **Double-booking guard:** Sistem menolak booking baru jika caregiver sudah punya booking aktif
- **Clinical note:** Caregiver wajib mengisi catatan klinis saat menandai booking selesai
- **Real-time UI:** Semua data booking menggunakan `StreamBuilder` dari Firestore — update otomatis tanpa refresh
- **Photo fallback:** Jika foto gagal load, tampil initial huruf pertama nama caregiver
- **Groq API key:** Konfigurasi di `lib/app_config.dart` → `AppConfig.groqApiKey`
