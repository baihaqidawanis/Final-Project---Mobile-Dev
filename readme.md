# Product Requirement Document (PRD)

[cite_start]**Project Name:** Healink (On-Demand Healthcare & Caregiving Logistics App) [cite: 2]
[cite_start]**Target Development Timeline:** 4 Weeks [cite: 3]
[cite_start]**Technical Framework:** Flutter (Dart) [cite: 3]
[cite_start]**Backend Infrastructure:** Firebase (Auth, Firestore, Cloud Messaging) [cite: 4]
[cite_start]**UN SDG Alignment:** Goal 3: Good Health and Well-being (Target 3.8: Achieve universal health coverage, access to quality essential healthcare services, and access to safe, effective, quality, and affordable essential medicines and vaccines for all)[cite: 5].

---

## 1. Document Control & Course Requirements Mapping
[cite_start]This section maps the course syllabus requirements to the corresponding technical designs outlined within this PRD to guarantee absolute compliance during grading[cite: 6].

| Syllabus Requirement | Feature Location in App Architecture | Assigned Owner | Status |
| :--- | :--- | :--- | :--- |
| Firebase Authentication | Auth Service, Global Role Router Interface | Team Shared | [cite_start]Mandatory | [cite: 7]
| Cloud Firestore | Unified Database Architecture & Security Rules | Team Shared | [cite_start]Mandatory | [cite: 7]
| Push Notifications | Firebase Cloud Messaging (FCM) Integration | Team Shared | [cite_start]Mandatory | [cite: 7]
| Navigation Bar | Role-Based Dynamic BottomNavigationBar | Team Shared | [cite_start]Mandatory | [cite: 7]
| Individual Module 1 (CRUD) | Caregiver Booking | Student A | [cite_start]Mandatory | [cite: 7, 8]
| Individual Module 2 (CRUD) | Hospital & Appointment Module | Student B | [cite_start]Mandatory | [cite: 8]
| Individual Module 3 (CRUD) | Pharmacy & Medicine Delivery Module | Student C | [cite_start]Mandatory | [cite: 8]
| External API Integration | Public openFDA Medicine/Drug Database API | Student C | [cite_start]Mandatory | [cite: 8]
| Single GitHub Repository | Version Control Core Management | Team Shared | [cite_start]Mandatory | [cite: 8]
| Weekly Commits | Monitored via Git Commit Schedule (Section 8) | All Members | [cite_start]Mandatory | [cite: 8]
| AI Policy Debug Demo | Covered by Reversibility Engine & Mock Fallback | Team Shared | [cite_start]Defensive Strategy | [cite: 8]

---

## 2. Executive Summary & Value Proposition

### 2.1 The Problem
* [cite_start]Navigating outpatient healthcare systems, coordinating essential in-home caregiving support, and securing prescribed pharmaceuticals remains highly fragmented[cite: 11].
* [cite_start]Families are forced to manage these logistics through multiple unconnected platforms, resulting in administrative delays, medication errors, and overall distress for vulnerable patients[cite: 12].

### 2.2 The Solution (Healink)
* [cite_start]Healink is a unified, on-demand home healthcare logistics ecosystem[cite: 14].
* [cite_start]It consolidates caregiver bookings, clinic appointments, and medication delivery into a single mobile interface[cite: 14].
* [cite_start]Utilizing a unified, role-based Flutter application architecture, Healink serves four main user groups[cite: 15]:
    * [cite_start]Families in need of domestic medical support[cite: 16].
    * [cite_start]Caregivers looking for freelance in-home nursing opportunities[cite: 17].
    * [cite_start]Hospitals coordinating outpatient consultations[cite: 17].
    * [cite_start]Pharmacies managing and fulfilling medicine delivery logistics[cite: 18].

---

## 3. Dynamic System Architecture & Role Routing
[cite_start]To prevent scope creep and bloated repositories, the app is engineered as a single Flutter application that dynamically adjusts its dashboard interface based on the authenticated user's role[cite: 20].

**Architecture Flow:**
* [cite_start]Firebase Auth Login -> Verify UID & Read User Role from Firestore -> App Role-Based Router[cite: 21, 22, 24].
* [cite_start]**Family Role:** Caregiver UI, Hospital UI, Pharmacy UI[cite: 25, 28].
* [cite_start]**Caregiver Role:** Active Queue, Accept/Decline, Complete Logs[cite: 26, 29].
* [cite_start]**Hospital Role:** Clinic Booking, Slot Statuses, Patient Queue[cite: 27, 30].
* [cite_start]**Pharmacy Role:** Order Intake, Pack/Dispatch, Catalog Sync[cite: 27, 31].
* [cite_start]Seluruh peran tersebut dihubungkan melalui Unified Dynamic BottomNavigationBar[cite: 32].

[cite_start]*(Catatan Teknis: Implementasi kode Dart untuk `RoleRouterScaffold` dan pengkondisian `_getScreensForRole` serta `_getNavItemsForRole` dapat dilihat pada source code aplikasi [cite: 33, 34, 38, 45, 70])*

---

## 4. Module Specifications & CRUD Mapping

### 4.1 Module 1: Caregiver Booking (Owner: Student A)
* [cite_start]**Objective:** Manage on-demand sourcing, tracking, and scheduling for specialized healthcare providers[cite: 123].
* **Functional Workflows:**
    * [cite_start]**Family Flow:** Browse caregivers through a filtered list view (by price, rating, specialization)[cite: 127]. [cite_start]Click a profile to view certifications, credentials, and hourly rates[cite: 128]. [cite_start]Tap "Instant Book" to initiate a request[cite: 128].
    * [cite_start]**Caregiver Flow:** View incoming service requests in real time[cite: 130]. [cite_start]Features single-tap accept and decline buttons[cite: 130]. [cite_start]Once accepted, provide a "Mark as Complete" interface containing clinical log notes[cite: 131].
* [cite_start]**UX Specification:** Scrollable lists featuring clean card widgets, standard layout structures to minimize native asset load, and prominent status tags[cite: 132].
* **Module 1 CRUD Operations:**
    * [cite_start]**Create:** Family submits a new document within the `/bookings` collection[cite: 135].
    * **Read:** Family tracks status updates on ongoing bookings; [cite_start]Caregivers watch a pending request stream[cite: 135, 136].
    * [cite_start]**Update:** Caregiver updates the document status ("pending" -> "accepted" / "completed" / "cancelled") and writes log comments[cite: 137, 138].
    * [cite_start]**Delete:** Family cancels a pending booking before acceptance, removing the document or transitioning status to "cancelled"[cite: 139].

### 4.2 Module 2: Hospital & Consultation Scheduling (Owner: Student B)
* [cite_start]**Objective:** Direct appointment calendar management based on a synchronized, real-time cinema-seat booking model[cite: 141].
* **Functional Workflows:**
    * [cite_start]**Family Flow:** Browse list of participating hospitals, select a clinic, choose a calendar date, and view a visual grid of fixed 1-hour time slots[cite: 144, 145].
    * [cite_start]**Cinema-Seat Layout Model:** Green (Selectable/Available), Grey (Disabled/Reserved), Red (Indicator/Selected)[cite: 146, 147, 148, 149].
    * [cite_start]**Hospital Admin Flow:** View daily chronological clinic rosters showing checked-in appointments, handle delays, and clear consultation blocks[cite: 150].
* [cite_start]**UX Specification:** Horizontal timeline date selector coupled with a responsive grid widget showing interactive time chips[cite: 151].
* **Module 2 CRUD Operations:**
    * [cite_start]**Create:** Family claims an available time chip, instantly generating an appointment document[cite: 153].
    * **Read:** Family views scheduled itineraries; [cite_start]Hospital admins read chronological daily agendas[cite: 154].
    * [cite_start]**Update:** Hospital admin modifies appointment state (e.g., status changed to "delayed", "checked_in", or "completed")[cite: 156].
    * [cite_start]**Delete:** Family cancels an appointment, which deletes the Firestore document and instantly opens up the time slot chip back to Green for other patients[cite: 157].

### 4.3 Module 3: Pharmacy Catalog & Prescription Delivery (Owner: Student C)
* [cite_start]**Objective:** Searchable medicine catalog, shopping cart flow, and delivery status updates[cite: 161].
* **Functional Workflows:**
    * [cite_start]**Family Flow:** Query medications via a responsive search bar, view unit prices, and add items to a local shopping cart[cite: 162]. [cite_start]Verify address parameters at checkout and submit an order[cite: 163].
    * [cite_start]**Pharmacy Flow:** Accept incoming order dispatches, view itemized lists with pricing, and progress orders through packaging, dispatch, and delivery[cite: 165].
* [cite_start]**UX Specification:** Clean e-commerce product grids, badges indicating total cart count, and progress timelines for tracking deliveries[cite: 166].
* **Module 3 CRUD Operations:**
    * [cite_start]**Create:** Family submits checkout payload, writing a new transaction inside the `/orders` collection[cite: 169].
    * **Read:** Family monitors shipment steps; [cite_start]Pharmacy reads incoming dispatch request structures[cite: 170].
    * [cite_start]**Update:** Pharmacy updates shipping stages ("ordered" -> "preparing" -> "out_for_delivery" -> "delivered")[cite: 171, 172, 173].
    * [cite_start]**Delete:** Family cancels the transaction prior to packaging dispatch, wiping the cart instance or setting state to "cancelled"[cite: 175].

---

## 5. Database Schema Architecture (Firestore)
[cite_start]A single-database design structure inside Cloud Firestore manages user roles, bookings, appointments, and shopping items securely[cite: 177].

* [cite_start]`/users/(uid)`: name, email, role, metadata, createdAt[cite: 180, 181, 182, 183, 184, 185].
* [cite_start]`/bookings/(bookingId)`: bookingId, familyId, caregiverId, dateTime, specializationRequested, pricePerHour, notes, status[cite: 186, 187, 188, 189, 190, 191, 192, 193, 194].
* [cite_start]`/appointments/(appointmentId)`: appointmentId, familyId, hospitalId, dateString, timeSlot, status[cite: 195, 196, 197, 198, 199, 200, 201].
* [cite_start]`/medicines/(medicineId)`: medicineId, name, genericName, price, category[cite: 202, 203, 204, 205, 206, 207].
* [cite_start]`/orders/(orderId)`: orderId, familyId, items, totalPrice, shippingAddress, status[cite: 208, 209, 210, 212, 213, 214].

---

## 6. External API Integration & Reversibility Design (Student C)
[cite_start]To satisfy the mandatory external API requirement securely under a 4-week deadline, the app uses a clean Repository Pattern for Module 3[cite: 216]. [cite_start]This pattern abstracts the data source and uses a global toggle configuration to instantly switch between the live, internet-reliant openFDA API and a local, zero-dependency mock dataset[cite: 216].

* [cite_start]**MockPharmacyRepository**: Pure offline Dart code, fast, zero failures, predefined demo data[cite: 218, 219, 220, 221].
* [cite_start]**FdaPharmacyRepository**: Live HTTP Web Requests, raw JSON parser, openFDA API Endpoint[cite: 223, 224, 225, 226].

[cite_start]*(Catatan Teknis: Model data obat dan implementasi kelas Repository beserta Toggle Config terdapat di source code yang disertakan [cite: 228, 254, 281, 312])*

---

## 7. 4-Week Project Timeline & Sprint Schedule
[cite_start]To meet the mandatory weekly commit requirements, the team will organize development cycles into strict weekly milestones[cite: 323].

* [cite_start]**WEEK 1 (Environment Setup & Core Gate):** Setup Repository & Flutter Base Application, Set up Firebase Authentication & Core Firestore Schema, Build Dynamic Login, Signup, & Role Router Switch[cite: 325, 326].
    * [cite_start]*Commit Requirement*: Each member must push baseline project configuration modifications[cite: 343].
* [cite_start]**WEEK 2 (Build Individual Modules & Basic Views):** Student A (Caregiver list UI & dynamic booking requests), Student B (Calendar engine & cinema-seat slot grid), Student C (Storefront catalog, local cart, checkout)[cite: 328, 329].
    * [cite_start]*Commit Requirement*: Feature-branch merges documenting unique CRUD activity scripts for every student[cite: 350].
* [cite_start]**WEEK 3 (Implement API Integration & Push Notifications):** Student C (Integrate openFDA API / Repository toggle), Integrate Firebase Cloud Messaging (FCM) notifications, Connect end-to-end CRUD flows to database listener feeds[cite: 332, 333, 334].
    * [cite_start]*Commit Requirement*: Merge records demonstrating robust HTTP routing logic and integrated push messaging workflows[cite: 356].
* [cite_start]**WEEK 4 (Design Polish & Code-Modification Drill Practice):** Finalize dynamic bottom navigation presentation layers, Execute mock grading sessions (Code-Tampering Drills), Package production app and write project documentation[cite: 337].
    * [cite_start]*Commit Requirement*: Final verification reviews, production assets cleanup, and repository delivery preparation[cite: 362].

---

## 8. Defensive Testing & Live Demo Strategy
[cite_start]The course syllabus highlights a critical grading component: the evaluator will modify several lines of your code during the live Final Project demonstration, and you will be required to debug and fix it on the spot[cite: 364].

### 8.1 The "API Break" Defensive Blueprint
[cite_start]If the instructor selects Student C's medicine search, comments out an API parsing helper, or injects mock network failures to test handling[cite: 367]:
1.  [cite_start]**Remain Calm:** The dynamic layout structures are completely isolated from the database operations using our structured Repository Pattern[cite: 368].
2.  [cite_start]**Toggle the Configuration Switch:** Open `lib/app_config.dart` and immediately locate: `static const bool useRealApi = false;` (Toggle from true to false)[cite: 369, 370].
3.  [cite_start]**Hot Reload:** Switch the boolean to false and hit hot reload[cite: 371].
4.  [cite_start]**Demonstrate Stability:** Show the evaluator that the application gracefully falls back to the uncompromised Mock repository system, keeping the UI, shopping cart, and transaction systems fully functional[cite: 372].

### 8.2 The "Database Naming Tampering" Recovery Steps
[cite_start]If the instructor modifies a Firestore field name to test dynamic updates (e.g., altering `status` to `bookingStatus` in a backend file)[cite: 375]:
1.  **Locate Firestore Mappers:** Immediately navigate to the corresponding data model class (e.g., `lib/models/booking_model.dart`). [cite_start]Do not hunt for variables across UI files[cite: 376, 377].
2.  [cite_start]**Adjust Parsers Locally:** Modify the JSON key parser helper directly within the factory parser (e.g., `status: data['bookingStatus'] ?? data['status'] ?? 'pending'`)[cite: 378, 380, 383].
3.  [cite_start]**Hot Reload:** Keep your layouts clean and compile immediately to demonstrate instant recovery, showing the instructor that your code is modular, well-architected, and fully understood by your team[cite: 386].