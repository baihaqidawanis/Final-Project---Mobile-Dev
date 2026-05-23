# Product Requirement Document (PRD)

**Project Name:** Healink (On-Demand Healthcare & Caregiving Logistics App)  
**Target Development Timeline:** 4 Weeks  
**Technical Framework:** Flutter (Dart)  
**Backend Infrastructure:** Firebase (Auth, Firestore, Cloud Messaging)  
**UN SDG Alignment:** Goal 3: Good Health and Well-being  
*Target 3.8: Achieve universal health coverage, access to quality essential healthcare services, and access to safe, effective, quality, and affordable essential medicines and vaccines for all.*

---

## 1. Document Control & Course Requirements Mapping

This section maps the course syllabus requirements to the corresponding technical designs outlined within this PRD to guarantee absolute compliance during grading.

| Syllabus Requirement | Feature Location in App Architecture | Assigned Owner | Status |
| :--- | :--- | :--- | :--- |
| Firebase Authentication | Auth Service, Global Role Router Interface | Team Shared | Mandatory |
| Cloud Firestore | Unified Database Architecture & Security Rules | Team Shared | Mandatory |
| Push Notifications | Firebase Cloud Messaging (FCM) Integration | Team Shared | Mandatory |
| Navigation Bar | Role-Based Dynamic BottomNavigationBar | Team Shared | Mandatory |
| Individual Module 1 (CRUD) | Caregiver Booking | Student A | Mandatory |
| Individual Module 2 (CRUD) | Hospital & Appointment Module | Student B | Mandatory |
| Individual Module 3 (CRUD) | Pharmacy & Medicine Delivery Module | Student C | Mandatory |
| External API Integration | Public openFDA Medicine/Drug Database API | Student C | Mandatory |
| Single GitHub Repository | Version Control Core Management | Team Shared | Mandatory |
| Weekly Commits | Monitored via Git Commit Schedule (Section 8) | All Members | Mandatory |
| AI Policy Debug Demo | Covered by Reversibility Engine & Mock Fallback | Team Shared | Defensive Strategy |

---

## 2. Executive Summary & Value Proposition

### 2.1 The Problem
* Navigating outpatient healthcare systems, coordinating essential in-home caregiving support, and securing prescribed pharmaceuticals remains highly fragmented.
* Families are forced to manage these logistics through multiple unconnected platforms, resulting in administrative delays, medication errors, and overall distress for vulnerable patients.

### 2.2 The Solution (Healink)
Healink is a unified, on-demand home healthcare logistics ecosystem. It consolidates caregiver bookings, clinic appointments, and medication delivery into a single mobile interface. Utilizing a unified, role-based Flutter application architecture, Healink serves four main user groups:
* Families in need of domestic medical support.
* Caregivers looking for freelance in-home nursing opportunities.
* Hospitals coordinating outpatient consultations.
* Pharmacies managing and fulfilling medicine delivery logistics.

---

## 3. Dynamic System Architecture & Role Routing

To prevent scope creep and bloated repositories, the app is engineered as a single Flutter application that dynamically adjusts its dashboard interface based on the authenticated user's role.

```text
       +------------------------------------+
       |        Firebase Auth Login         |
       +-----------------+------------------+
                         |
    Verify UID & Read User Role from Firestore
                         |
                         V
       +-----------------+------------------+
       |       App Role-Based Router        |
       +-----------------+------------------+
                         |
    +-------------+------+------+-------------+
    V             V             V             V
+-----------+ +------------+ +------------+ +------------+
|Family Role| |Caregiver   | |Hospital    | |Pharmacy    |
|           | |Role        | |Role        | |Role        |
+-----------+ +------------+ +------------+ +------------+
|- Caregiver|- Active Queue|- Clinic    |- Order Intake|
|  UI       |- Accept/     |  Booking   |- Pack/       |
|- Hospital |  Decline     |- Slot      |  Dispatch    |
|  UI       |- Complete    |  Statuses  |- Catalog     |
|- Pharmacy |  Logs        |- Patient   |  Sync        |
|  UI       |              |  Queue     |              |
+-----------+ +------------+ +------------+ +------------+
    \             /             \             /
     \           /               \           /
+--------------------------------------------------------+
|          Unified Dynamic BottomNavigationBar           |
+--------------------------------------------------------+