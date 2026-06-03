# Product Requirement Document (PRD)
# Project Name: Healink
### On-Demand Healthcare & Caregiving Logistics App

| Field | Detail |
|---|---|
| **Target Development Timeline** | 4 Weeks |
| **Technical Framework** | Flutter (Dart) |
| **Backend Infrastructure** | Firebase (Auth, Firestore, Cloud Messaging) |
| **UN SDG Alignment** | Goal 3: Good Health and Well-being — Target 3.8: Achieve universal health coverage, access to quality essential healthcare services, and access to safe, effective, quality, and affordable essential medicines and vaccines for all. |

---

## 1. Document Control & Course Requirements Mapping

This section maps the course syllabus requirements to the corresponding technical designs outlined within this PRD to guarantee absolute compliance during grading.

| Syllabus Requirement | Feature Location in App / Architecture | Assigned Owner | Status |
|---|---|---|---|
| Firebase Authentication | Auth Service, Global Role Router Interface | Team Shared | Mandatory |
| Cloud Firestore | Unified Database Architecture & Security Rules | Team Shared | Mandatory |
| Push Notifications | Firebase Cloud Messaging (FCM) Integration | Team Shared | Mandatory |
| Navigation Bar | Role-Based Dynamic BottomNavigationBar | Team Shared | Mandatory |
| Individual Module 1 (CRUD) | Caregiver Booking Module | Student A | Mandatory |
| Individual Module 2 (CRUD) | Hospital & Appointment Module | Student B | Mandatory |
| Individual Module 3 (CRUD) | Pharmacy & Medicine Delivery Module | Student C | Mandatory |
| External API Integration | Public openFDA Medicine/Drug Database API | Student C | Mandatory |
| Single GitHub Repository | Core Version Control Management | Team Shared | Mandatory |
| Weekly Commits | Monitored via Git Commit Schedule (Section 8) | All Members | Mandatory |
| AI Policy Debug Demo | Covered by Reversibility Engine & Mock Fallback | Team Shared | Defensive Strategy |

---

## 2. Executive Summary & Value Proposition

### 2.1 The Problem

Navigating outpatient healthcare systems, coordinating essential in-home caregiving support, and securing prescribed pharmaceuticals remains highly fragmented. Families are forced to manage these logistics through multiple unconnected platforms, resulting in administrative delays, medication errors, and overall distress for vulnerable patients.

### 2.2 The Solution (Healink)

Healink is a unified, on-demand home healthcare logistics ecosystem. It consolidates caregiver bookings, clinic appointments, and medication delivery into a single mobile interface. Utilizing a unified, role-based Flutter application architecture, Healink serves four main user groups:

- **Families** in need of domestic medical support.
- **Caregivers** looking for freelance in-home nursing opportunities.
- **Hospitals** coordinating outpatient consultations.
- **Pharmacies** managing and fulfilling medicine delivery logistics.

---

## 3. Dynamic System Architecture & Role Routing

To prevent scope creep and bloated repositories, the app is engineered as a **single Flutter application** that dynamically adjusts its dashboard interface based on the authenticated user's role.

```
+------------------------+
|   Firebase Auth Login  |
+----------+-------------+
           |
    Verify UID & Read User Role from Firestore
           |
           v
+-----------------------------------+
|       App Role-Based Router       |
+-----------------------------------+
           |
  +--------+--------+--------+--------+
  |        |        |        |        |
  v        v        v        v
+-------------+ +----------------+ +-----------------+ +----------------+
| Family Role | | Caregiver Role | |  Hospital Role  | | Pharmacy Role  |
+-------------+ +----------------+ +-----------------+ +----------------+
| - Caregiver | | - Active Queue | | - Clinic Booking| | - Order Intake |
|   UI        | | - Accept/Decl. | | - Slot Statuses | | - Pack/Dispatch|
| - Hospital  | | - Complete Logs| | - Patient Queue | | - Catalog Sync |
|   UI        | +----------------+ +-----------------+ +----------------+
| - Pharmacy  |
|   UI        |
+-------------+
           |          \          \         /          /
           +----------+-----------+--------+----------+
                      Unified Dynamic BottomNavigationBar
```

### 3.1 Dynamic Bottom Navigation Controller

When a user logs in, the security context is verified, and the `BottomNavigationBar` is customized via structural conditional parameters in Dart:

```dart
// role_router_scaffold.dart
import 'package:flutter/material.dart';

enum UserRole { family, caregiver, hospital, pharmacy }

class RoleRouterScaffold extends StatefulWidget {
  final UserRole userRole;
  const RoleRouterScaffold({Key? key, required this.userRole}) : super(key: key);

  @override
  State<RoleRouterScaffold> createState() => _RoleRouterScaffoldState();
}

class _RoleRouterScaffoldState extends State<RoleRouterScaffold> {
  int _currentIndex = 0;

  List<Widget> _getScreensForRole() {
    switch (widget.userRole) {
      case UserRole.family:
        return [
          const FamilyCaregiverListScreen(),
          const FamilyHospitalSchedulerScreen(),
          const FamilyPharmacyCatalogScreen(),
          const FamilyOrderHistoryScreen(),
        ];
      case UserRole.caregiver:
        return [
          const CaregiverDashboardScreen(),
          const CaregiverFulfillmentHistoryScreen(),
        ];
      case UserRole.hospital:
        return [
          const HospitalAdminSchedulerScreen(),
        ];
      case UserRole.pharmacy:
        return [
          const PharmacyOrderIntakeScreen(),
          const PharmacyInventoryCatalogScreen(),
        ];
    }
  }

  List<BottomNavigationBarItem> _getNavItemsForRole() {
    switch (widget.userRole) {
      case UserRole.family:
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Caregivers'),
          BottomNavigationBarItem(icon: Icon(Icons.local_hospital), label: 'Hospitals'),
          BottomNavigationBarItem(icon: Icon(Icons.medication), label: 'Pharmacy'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Orders'),
        ];
      case UserRole.caregiver:
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: 'Completed'),
        ];
      case UserRole.hospital:
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Clinic Schedule'),
        ];
      case UserRole.pharmacy:
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Incoming Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Inventory'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = _getScreensForRole();
    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal[700],
        unselectedItemColor: Colors.grey[600],
        items: _getNavItemsForRole(),
      ),
    );
  }
}
```

---

## 4. Module Specifications & CRUD Mapping

### 4.1 Module 1: Caregiver Booking (Owner: Student A)

- **Objective:** Manage on-demand sourcing, tracking, and scheduling for specialized healthcare providers.

- **Functional Workflows:**
  - **Family Flow:** Browse caregivers through a filtered list view with **sort chips** (by price ascending/descending, or rating). Cards display name, specialization, area/location, rating, and price. A **green/red availability dot** shows real-time status. Click a profile to view certifications, bio, and hourly rates. Tap "Kirim Booking" to initiate a request with date, time, and optional notes.
  - **Caregiver Flow:** View active incoming requests (pending + accepted only) in real time. Dashboard shows a **personalized greeting** with a **badge count** on the Requests tab when new bookings arrive. Confirm-before-decline dialog prevents accidental rejections. Once accepted, tap "Tandai Selesai" to open a clinical log notes dialog. Completed/cancelled bookings are accessible via **dedicated History Screen** (bottom nav tab 2).

- **UX Specification:** Scrollable lists featuring clean card widgets with colored status borders, animated sort chips, shimmer loading skeletons, distinct empty states (no-data vs no-search-results), and prominent status badges with Bahasa Indonesia labels and icons.

- **Module 1 CRUD Operations:**
  | Operation | Description |
  |---|---|
  | **Create** | Family submits a new document within the `/bookings` collection. |
  | **Read** | Family tracks status updates on ongoing bookings; Caregivers watch an active request stream (pending + accepted only) with a real-time badge count. |
  | **Update** | Caregiver updates the document status (`"pending"` → `"accepted"` → `"completed"` / `"cancelled"`) and writes clinical log notes via `completeBookingWithNote()`. Caregiver can also update their own profile (name, specialization, price, area, bio, availability toggle). |
  | **Delete** | Family cancels a pending booking from **My Bookings Screen**, transitioning status to `"cancelled"`. |

- **Extra Features Implemented (Beyond PRD):**
  - Sort chips on caregiver list (Price Low, Price High, Rating)
  - Availability ring + dot indicator on caregiver card avatar
  - `CaregiverHistoryScreen` — dedicated screen for completed/cancelled bookings with summary stats and clinical note display
  - `clinicalNote` field added to `BookingModel` for history display
  - Confirm-before-decline dialog on caregiver dashboard
  - Error state with retry button on caregiver list
  - Bottom nav bar for caregiver role (Requests + Riwayat), matching PRD nav spec

---

### 4.2 Module 2: Hospital & Consultation Scheduling (Owner: Student B)

- **Objective:** Direct appointment calendar management based on a synchronized, real-time cinema-seat booking model.

- **Functional Workflows:**
  - **Family Flow:** Browse list of participating hospitals, select a clinic, choose a calendar date, and view a visual grid of fixed 1-hour time slots.
  - **Cinema-Seat Layout Model:**
    - 🟢 **Green (Selectable):** Available slots.
    - ⚫ **Grey (Disabled):** Already reserved by other users.
    - 🔴 **Red (Indicator):** Selected slot.
  - **Hospital Admin Flow:** View daily chronological clinic rosters showing checked-in appointments, handle delays, and clear consultation blocks.

- **UX Specification:** Horizontal timeline date selector coupled with a responsive grid widget showing interactive time chips.

- **Module 2 CRUD Operations:**
  | Operation | Description |
  |---|---|
  | **Create** | Family claims an available time chip, instantly generating an appointment document. |
  | **Read** | Family views scheduled itineraries; Hospital admins read chronological daily agendas. |
  | **Update** | Hospital admin modifies appointment state (e.g., status changed to `"delayed"`, `"checked_in"`, or `"completed"`). |
  | **Delete** | Family cancels an appointment, which deletes the Firestore document and instantly opens up the time slot chip back to Green for other patients. |

---

### 4.3 Module 3: Pharmacy Catalog & Prescription Delivery (Owner: Student C)

- **Objective:** Searchable medicine catalog, shopping cart flow, and delivery status updates.

- **Functional Workflows:**
  - **Family Flow:** Query medications via a responsive search bar, view unit prices, and add items to a local shopping cart. Verify address parameters at checkout and submit an order.
  - **Pharmacy Flow:** Accept incoming order dispatches, view itemized lists with pricing, and progress orders through packaging, dispatch, and delivery.

- **UX Specification:** Clean e-commerce product grids, badges indicating total cart count, and progress timelines for tracking deliveries.

- **Module 3 CRUD Operations:**
  | Operation | Description |
  |---|---|
  | **Create** | Family submits checkout payload, writing a new transaction inside the `/orders` collection. |
  | **Read** | Family monitors shipment steps; Pharmacy reads incoming dispatch request structures. |
  | **Update** | Pharmacy updates shipping stages (`"ordered"` → `"preparing"` → `"out_for_delivery"` → `"delivered"`). |
  | **Delete** | Family cancels the transaction prior to packaging dispatch, wiping the cart instance or setting state to `"cancelled"`. |

---

## 5. Database Schema Architecture (Firestore)

A single-database design structure inside Cloud Firestore manages user roles, bookings, appointments, and shopping items securely.

```
/artifacts/{appId}/public/data/
  |
  +-- /users/ {uid} (Document)
  |       |-- name: String
  |       |-- email: String
  |       |-- role: String ("user" | "admin" | "caregiver" | "hospital" | "pharmacy")
  |       |-- metadata: Map
  |       └-- createdAt: Timestamp
  |
  +-- /bookings/ {bookingId} (Document)
  |       |-- bookingId: String
  |       |-- familyId: String
  |       |-- caregiverId: String
  |       |-- dateTime: Timestamp
  |       |-- specializationRequested: String
  |       |-- pricePerHour: Double
  |       |-- notes: String
  |       └-- status: String ("pending" | "accepted" | "completed" | "cancelled")
  |
  +-- /appointments/ {appointmentId} (Document)
  |       |-- appointmentId: String
  |       |-- familyId: String
  |       |-- hospitalId: String
  |       |-- dateString: String (Format: "YYYY-MM-DD")
  |       |-- timeSlot: String (Format: "HH:MM")
  |       └-- status: String ("booked" | "completed" | "delayed" | "cancelled")
  |
  +-- /medicines/ {medicineId} (Document - Static/API-Synced Catalog)
  |       |-- medicineId: String
  |       |-- name: String
  |       |-- genericName: String
  |       |-- price: Double
  |       └-- category: String
  |
  +-- /orders/ {orderId} (Document)
          |-- orderId: String
          |-- familyId: String
          |-- items: List<Map> [ { "medicineId": String, "name": String, "qty": Int, "price": Double } ]
          |-- totalPrice: Double
          |-- shippingAddress: String
          └-- status: String ("ordered" | "preparing" | "out_for_delivery" | "delivered" | "cancelled")
```

---

## 6. External API Integration & Reversibility Design (Student C)

To satisfy the mandatory external API requirement securely under a 4-week deadline, the app uses a clean **Repository Pattern** for Module 3. This pattern abstracts the data source and uses a global toggle configuration to instantly switch between the live, internet-reliant openFDA API and a local, zero-dependency mock dataset.

### 6.1 Architectural Layout

```
                    +-------------------------+
                    |  PharmacyRepository     | <--- Interface Class
                    +----------+--------------+
                               |
              +----------------+------------------+
              |                                   |
              v                                   v
+---------------------------+       +---------------------------+
|  MockPharmacyRepository   |       |  FdaPharmacyRepository    |
+---------------------------+       +---------------------------+
| - Pure offline Dart code  |       | - Live HTTP Web Requests  |
| - Fast, zero failures     |       | - Raw JSON Parser         |
| - Predefined demo data    |       | - openFDA API Endpoint    |
+---------------------------+       +---------------------------+
```

### 6.2 Data Sourcing Contract (Interface)

```dart
// pharmacy_repository.dart
import 'package:Healink/models/medicine_model.dart';

abstract class PharmacyRepository {
  Future<List<Medicine>> searchMedicines(String query);
}
```

### 6.3 Medicine Data Model

```dart
// medicine_model.dart
class Medicine {
  final String id;
  final String name;
  final String genericName;
  final double price;

  const Medicine({
    required this.id,
    required this.name,
    required this.genericName,
    required this.price,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['product_id'] ?? '',
      name: json['brand_name'] ?? 'Generic Medicine',
      genericName: json['generic_name'] ?? 'Unknown',
      price: 15.0, // Fixed baseline catalog price
    );
  }
}
```

### 6.4 Implementation A: Clean Offline Mock Repository

```dart
// mock_pharmacy_repository.dart
import 'package:Healink/models/medicine_model.dart';
import 'pharmacy_repository.dart';

class MockPharmacyRepository implements PharmacyRepository {
  @override
  Future<List<Medicine>> searchMedicines(String query) async {
    // Mimic API networking latency
    await Future.delayed(const Duration(milliseconds: 400));

    final offlineMeds = [
      const Medicine(id: 'mock-01', name: 'Aspirin', genericName: 'Acetylsalicylic Acid', price: 5.50),
      const Medicine(id: 'mock-02', name: 'Paracetamol', genericName: 'Acetaminophen', price: 4.00),
      const Medicine(id: 'mock-03', name: 'Amoxicillin', genericName: 'Amoxicillin Trihydrate', price: 12.75),
      const Medicine(id: 'mock-04', name: 'Ibuprofen', genericName: 'Ibuprofen', price: 6.20),
      const Medicine(id: 'mock-05', name: 'Lipitor', genericName: 'Atorvastatin Calcium', price: 45.00),
    ];

    if (query.isEmpty) return offlineMeds;

    return offlineMeds
        .where((med) =>
            med.name.toLowerCase().contains(query.toLowerCase()) ||
            med.genericName.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
```

### 6.5 Implementation B: Live HTTP openFDA API Repository

```dart
// fda_pharmacy_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:Healink/models/medicine_model.dart';
import 'pharmacy_repository.dart';

class FdaPharmacyRepository implements PharmacyRepository {
  @override
  Future<List<Medicine>> searchMedicines(String query) async {
    if (query.isEmpty) {
      // Avoid raw queries on openFDA to prevent unnecessary bandwidth consumption
      return const [];
    }

    // Direct openFDA endpoint matching search query to brand_name
    final url = Uri.parse(
      'https://api.fda.gov/drug/ndc.json?search=brand_name:"$query"&limit=8'
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List?;
        if (results == null) return const [];
        return results.map((item) => Medicine.fromJson(item)).toList();
      } else {
        // Fallback gracefully on response errors
        return const [];
      }
    } catch (e) {
      // Catch socket exceptions or no internet scenarios
      throw Exception("Connection failed. Check your network.");
    }
  }
}
```

### 6.6 The Master Configuration Switch (Toggle Config)

```dart
// app_config.dart
import 'package:Healink/repositories/pharmacy_repository.dart';
import 'package:Healink/repositories/mock_pharmacy_repository.dart';
import 'package:Healink/repositories/fda_pharmacy_repository.dart';

class AppConfig {
  /// Toggle this master variable to change data sourcing system-wide:
  /// [true]  -> Hits the real external openFDA API over HTTP.
  /// [false] -> Instantly routes data queries locally using safe offline Mock repositories.
  static const bool useRealApi = false;

  static PharmacyRepository get pharmacyRepository {
    return useRealApi ? FdaPharmacyRepository() : MockPharmacyRepository();
  }
}
```

---

## 7. 4-Week Project Timeline & Sprint Schedule

To meet the mandatory weekly commit requirements, the team will organize development cycles into strict weekly milestones.

```
+--------------------------------------------------------------+
|                           WEEK 1                             |
|  - Setup Repository & Flutter Base Application               |
|  - Set up Firebase Authentication & Core Firestore Schema    |
|  - Build Dynamic Login, Signup, & Role Router Switch         |
+--------------------------------------------------------------+
                              |
                              v
+--------------------------------------------------------------+
|                           WEEK 2                             |
|  - Build Individual Modules & Basic Views                    |
|  - Student A: Caregiver list UI & dynamic booking requests   |
|  - Student B: Calendar engine & cinema-seat slot grid        |
|  - Student C: Storefront catalog, local cart, checkout       |
+--------------------------------------------------------------+
                              |
                              v
+--------------------------------------------------------------+
|                           WEEK 3                             |
|  - Implement API Integration & Push Notifications            |
|  - Student C: Integrate openFDA API / Repository toggle      |
|  - Integrate Firebase Cloud Messaging (FCM) notifications    |
|  - Connect end-to-end CRUD flows to database listener feeds  |
+--------------------------------------------------------------+
                              |
                              v
+--------------------------------------------------------------+
|                           WEEK 4                             |
|  - Design Polish & Code-Modification Drill Practice          |
|  - Finalize dynamic bottom navigation presentation layers    |
|  - Execute mock grading sessions (Code-Tampering Drills)     |
|  - Package production app and write project documentation    |
+--------------------------------------------------------------+
```

### Week 1 Milestone: Environment Setup & Core Gate

- **Core Goal:** Initialize unified working spaces and global authentication routines.
- **Actions:**
  - Build unified GitHub codebase directory.
  - Connect shared Firebase Console instance supporting Auth + Firestore dependencies.
  - Set up landing screens, user registration parameters, database-written user roles, and the dynamic router scaffold.
- **Commit Requirement:** Each member must push baseline project configuration modifications.

### Week 2 Milestone: Individual Feature Execution (CRUD Foundation)

- **Core Goal:** Finish baseline presentation structures and run core transactional database operations for all three modules.
- **Actions:**
  - **Student A:** Complete UI structures rendering active caregiver lists and details, and caregiver-side incoming request interfaces.
  - **Student B:** Build the custom cinema-seat date grid, preventing users from selecting disabled slot chips.
  - **Student C:** Build medicine card lists, the dynamic search bar widget, and basic shopping cart layouts.
- **Commit Requirement:** Feature-branch merges documenting unique CRUD activity scripts for every student.

### Week 3 Milestone: API Sourcing & Systems Communication

- **Core Goal:** Implement dynamic cloud messaging and complete live data calls.
- **Actions:**
  - **Student C:** Complete raw JSON parsers mapping live openFDA responses into Dart object lists.
  - **Team Shared:** Initialize cloud messaging triggers. When a Family member places an appointment booking, send a payload notification directly displaying on the Hospital workspace dashboard.
- **Commit Requirement:** Merge records demonstrating robust HTTP routing logic and integrated push messaging workflows.

### Week 4 Milestone: Polish & Defensive Testing Drills

- **Core Goal:** Secure clean, unified styling and complete preparation drills for the live final presentation.
- **Actions:**
  - Apply standardized color palettes, clear layout spacing, and uniform loader overlays.
  - Run mock grading drills simulating live code-tampering by intentionally breaking database variables, allowing members to practice locating and fixing bugs within minutes under pressure.
- **Commit Requirement:** Final verification reviews, production assets cleanup, and repository delivery preparation.

---

## 8. Defensive Testing & Live Demo Strategy

> ⚠️ The course syllabus highlights a critical grading component: the evaluator will modify several lines of your code during the live Final Project demonstration, and you will be required to debug and fix it on the spot.

Here is your team's tactical playbook to guarantee success under pressure.

### 8.1 The "API Break" Defensive Blueprint

If the instructor selects Student C's medicine search, comments out an API parsing helper, or injects mock network failures to test handling:

1. **Remain Calm:** The dynamic layout structures are completely isolated from the database operations using our structured Repository Pattern.
2. **Toggle the Configuration Switch:** Open `lib/app_config.dart` and immediately locate:
   ```dart
   static const bool useRealApi = false; // Toggle from true to false
   ```
3. **Hot Reload:** Switch the boolean to `false` and hit hot reload.
4. **Demonstrate Stability:** Show the evaluator that the application gracefully falls back to the uncompromised Mock repository system, keeping the UI, shopping cart, and transaction systems fully functional. This displays excellent software engineering principles and keeps your demo running smoothly.

### 8.2 The "Database Naming Tampering" Recovery Steps

If the instructor modifies a Firestore field name to test dynamic updates (e.g., altering `status` to `bookingStatus` in a backend file):

1. **Locate Firestore Mappers:** Immediately navigate to the corresponding data model class (e.g., `lib/models/booking_model.dart`). Do not hunt for variables across UI files.
2. **Adjust Parsers Locally:** Modify the JSON key parser helper directly within the factory parser:
   ```dart
   // Locate this line inside your model file
   factory Booking.fromFirestore(Map<String, dynamic> data) {
     return Booking(
       // Update 'status' key read string to what the instructor named it
       status: data['bookingStatus'] ?? data['status'] ?? 'pending',
     );
   }
   ```
3. **Hot Reload:** Keep your layouts clean and compile immediately to demonstrate instant recovery, showing the instructor that your code is modular, well-architected, and fully understood by your team.

---

## Healink: Architectural Design & Folder Structure

## 1. Architectural Pattern: Feature-Driven Design

For a 3-person team under a tight 4-week deadline, Healink will use a **Feature-Driven Architecture**.

Instead of organizing by technical layers (e.g., putting all UI in one folder and all databases in another), we organize the app by **Modules**. This provides isolated workspaces so each student can build their CRUD features without causing Git merge conflicts with their teammates.

---

## 2. The Global Folder Structure (`lib/`)

```
lib/
│
├── main.dart                    # The entry point of the app (Firebase Init)
├── app_config.dart              # Master switch for Student C's openFDA API/Mock toggle
│
├── core/                        # Global assets & rules shared by everyone
│   ├── constants/               # Colors, TextStyles, API Keys, App Theme
│   └── utils/                   # Shared helper functions (e.g., date formatters)
│
├── services/                    # Global backend connections
│   ├── firebase_auth_service.dart    # Handles Login, Registration, & User Roles
│   └── notification_service.dart     # Handles Firebase Cloud Messaging (Push Notifications)
│
└── features/                    # 📍 THE ISOLATED WORKSPACES
    │
    ├── auth/                    # Shared Auth UI
    │   ├── models/              # UserModel (contains the user 'role')
    │   └── screens/             # LoginScreen, RegisterScreen
    │
    ├── dashboard/               # Shared Navigation
    │   └── screens/
    │       └── role_router_scaffold.dart  # The dynamic BottomNavigationBar
    │
    ├── caregiver_booking/       # 🟦 STUDENT A WORKSPACE
    │   ├── models/              # BookingModel, CaregiverProfileModel
    │   ├── screens/             # FamilyCaregiverList, CaregiverDashboard
    │   ├── widgets/             # CaregiverCard, StatusBadge
    │   └── services/            # CaregiverFirestoreService (CRUD ops)
    │
    ├── hospital_appointment/    # 🟩 STUDENT B WORKSPACE
    │   ├── models/              # AppointmentModel, HospitalModel
    │   ├── screens/             # FamilyHospitalScheduler, AdminDashboard
    │   ├── widgets/             # CinemaSeatTimeSlotGrid, CalendarPicker
    │   └── services/            # HospitalFirestoreService (CRUD ops)
    │
    └── pharmacy_delivery/       # 🟥 STUDENT C WORKSPACE
        ├── models/              # MedicineModel, OrderModel
        ├── repositories/        # 🛡 THE REPOSITORY PATTERN (API vs Mock)
        │   ├── pharmacy_repository.dart       # Abstract Interface
        │   ├── fda_pharmacy_repository.dart   # Live HTTP openFDA parser
        │   └── mock_pharmacy_repository.dart  # Offline Mock fallback
        ├── screens/             # PharmacyCatalog, CartCheckout, PharmacyDashboard
        ├── widgets/             # MedicineGridItem, CartFloatingButton
        └── services/            # PharmacyFirestoreService (CRUD ops for Orders)
```

---

## 3. How This Structure Protects Your Team

### ✅ Zero Merge Conflicts

Notice how the `features/` directory is split up:

- **Student A** will only ever create and edit files inside `lib/features/caregiver_booking/`.
- **Student B** will only ever touch files inside `lib/features/hospital_appointment/`.
- Because you are working in completely different folders, when you push your weekly commits to GitHub, you **won't accidentally overwrite each other's code!**

### ✅ Easy API Switching (Student C)

Student C's workspace contains the `repositories/` folder. Because `app_config.dart` sits at the very root of the app, Student C can easily point their UI screens to use the `app_config.dart` toggle switch without tangling their code with the rest of the application.

### ✅ The "Brain" is Isolated

The `features/dashboard/role_router_scaffold.dart` file is the brain of your UI. It acts as the traffic cop. Once a user logs in via the `auth` feature, this scaffold checks their role and imports the correct screens from Student A, B, or C's folders to display on the Bottom Navigation Bar.

---

## 4. Initialization Checklist for Week 1

To set this up flawlessly in your first meeting, have one person (usually the team lead) do the following:

1. Run `flutter create healink`.
2. Delete everything inside the `lib` folder except `main.dart`.
3. Manually create the exact folder tree shown above (Right-click → New Folder).
4. Create empty placeholder `.dart` files for the workspaces (e.g., just make a blank file called `family_caregiver_list.dart` with a basic `StatelessWidget` returning a `Text("Caregiver Screen")`).
5. Push this empty skeleton to the GitHub repository.
6. Have Student A, B, and C clone the repo. Now everyone has their designated folders ready to go!