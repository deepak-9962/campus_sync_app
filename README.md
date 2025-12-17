# 🎓 Campus Sync - Comprehensive Student Management Application

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

> A modern, cross-platform mobile application that revolutionizes student management and campus digitization through a unified digital platform.

## 📱 Overview

Campus Sync is a comprehensive Flutter-based application designed to address critical challenges in educational institutions. It provides a role-based access system with distinct interfaces for students, faculty, and administrators, integrating multiple functionalities into a single unified platform.

## ✨ Key Features

### 🎯 Core Academic Management

#### 📊 Smart Attendance System
- **Period-Based Attendance**: Track attendance for specific subjects and periods
- **Auto-Resolution**: Automatically detects subject and staff for selected periods
- **Interactive Analytics**: Click on present/absent counts to view filtered student lists
- **Multi-View Support**: 
  - Today's attendance (Period & Daily views)
  - Overall attendance analytics with visual progress indicators
- **Student Linking**: One-time account linking for automatic attendance viewing
- **Staff Interface**: Easy attendance marking with subject and period selection

#### 📅 Digital Timetable Management
- **Role-Based Access**: Admin and Staff can create/edit timetables
- **Conflict Detection**: Automatic prevention of scheduling conflicts
- **Advanced Operations**:
  - Copy timetable between sections
  - Load standard templates
  - Day-wise editing interface (Monday-Saturday)
- **Faculty & Room Management**: Prevents double-booking
- **Batch Support**: Lab session scheduling (B1, B2, Full Class)

#### 📚 Resource Hub
- **Document Sharing**: Upload and access PDF documents and study materials
- **Category Organization**: Organized by subject, department, and semester
- **Cloud Storage**: Secure file storage and sharing via Supabase
- **PDF Viewer**: Built-in viewer for seamless document access
- **Search & Filter**: Easy resource discovery

#### 🧮 GPA/CGPA Calculator
- **Multi-Department Support**: 
  - Computer Science and Engineering
  - Information Technology
  - Artificial Intelligence and Data Science
  - Biomedical Engineering
  - Mechanical Engineering
- **Comprehensive Curriculum**: All 8 semesters with accurate credit calculations
- **Grade System**: 10-point grading scale with automatic calculations
- **Progressive Tracking**: Semester-wise and cumulative GPA tracking

### 👥 User Management & Authentication

#### 🔐 Secure Authentication
- Email/password authentication via Supabase Auth
- Role-based access control (Student/Faculty/Admin)
- Password reset functionality
- Row-level security (RLS) for data protection

#### 👤 Profile Management
- User profile creation and management
- Department and semester selection
- Personal information management
- Account linking for students

### 🏫 Administrative Tools

#### 📋 Faculty Dashboard
- Centralized access to all faculty tools
- Attendance management interface
- Timetable editing capabilities
- Student analytics and reporting

#### 🔧 Database Management
- Database setup and configuration interface
- User role management
- Data migration tools
- System maintenance utilities

### 🎨 User Experience Features

#### 📱 Cross-Platform Compatibility
- **Mobile**: Android & iOS
- **Desktop**: Windows, macOS, Linux
- **Web**: Progressive Web App support

#### 🎨 Modern UI/UX
- Material Design 3 implementation
- Responsive design for all screen sizes
- Intuitive navigation with role-based interfaces
- Dark/Light theme support
- Interactive components and animations

#### 📲 Notifications & Updates
- Real-time data synchronization
- Push notifications (planned)
- Announcement system
- Lost & Found digital board

## 🛠️ Technical Architecture

### Frontend
- **Framework**: Flutter 3.x
- **Language**: Dart
- **UI**: Material Design 3
- **State Management**: StatefulWidget with Provider pattern
- **Navigation**: Go Router for advanced routing

### Backend
- **BaaS**: Supabase (Backend-as-a-Service)
- **Database**: PostgreSQL with real-time capabilities
- **Authentication**: Supabase Auth with RLS
- **Storage**: Supabase Storage for file management
- **API**: REST API with real-time subscriptions

### Database Schema

#### Core Tables
- `users` - User authentication and roles
- `students` - Student information and registration data
- `attendance` - Period-based attendance records
- `daily_attendance` - Daily attendance summaries
- `overall_attendance_summary` - Computed attendance analytics
- `class_schedule` - Timetable and scheduling data
- `subjects` - Subject information and codes
- `resources` - Educational resources and documents
- `profiles` - User profile information

#### Features
- **Row Level Security (RLS)**: Ensures data isolation and proper access control
- **Triggers & Functions**: Automatic calculations and data consistency
- **Views**: Optimized queries for reporting and analytics
- **Indexes**: Performance optimization for frequently accessed data

## 🚀 Getting Started

### Prerequisites
   ```bash
   git clone https://github.com/deepak-9962/campus_sync_app.git
   ```bash
   flutter pub get
   - Create a `.env` file in the root directory:
   SUPABASE_URL=your_supabase_url_here
   SUPABASE_ANON_KEY=your_supabase_anon_key_here
   ```
   - **Important**: Never commit the `.env` file to version control
   - The `.env` file is already included in `.gitignore` for security


### Web Deployment (Vercel / Netlify)

Prerequisites: `flutter config --enable-web`

Build (with dart-define for Supabase):

```
flutter build web --release --web-renderer canvaskit \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
```

Vercel quick deploy:
1. Commit `vercel.json`.
2. Run build locally, then `vercel deploy build/web` (or set a project build command to run the flutter build in CI).

Netlify quick deploy:
1. Commit `netlify.toml`.
2. Connect repo in Netlify, it will run the build command and publish `build/web`.

SPA routing handled by the included config files.

If you update the app frequently, bump `kBuildVersion` in `lib/main.dart` so clients can detect a new cache version (optional banner logic can be added to `web/index.html`).
4. **Setup Database**
   - Navigate to your Supabase SQL Editor
   - Run the setup scripts in order:
     ```sql
     -- Run these files in your Supabase SQL Editor
     supabase_setup.sql
     optimized_attendance_schema.sql
     setup_timetable_permissions.sql
     add_student_user_link.sql
     ```

5. **Run the application**
   ```bash
   flutter run
   ```

### Building for Production

#### Android
```bash
flutter build apk --release
```

#### iOS
```bash
flutter build ios --release
```

#### Web
```bash
flutter build web --release
```

#### Desktop
```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

## 📖 Usage Guide

### For Students
1. **Registration & Login**: Create account with institutional email
2. **Account Linking**: Link your user account with registration number (one-time)
3. **View Attendance**: Automatic attendance viewing without manual input
4. **Access Resources**: Browse and download study materials
5. **Calculate GPA**: Track academic performance across semesters
6. **Check Timetable**: View class schedules and timings

### For Faculty/Staff
1. **Dashboard Access**: Access faculty dashboard after role assignment
2. **Mark Attendance**: Select subject, period, and mark student attendance
3. **Manage Timetable**: Create and edit class schedules
4. **Upload Resources**: Share study materials with students
5. **View Analytics**: Access attendance reports and student performance

### For Administrators
1. **User Management**: Assign roles and manage user accounts
2. **System Configuration**: Setup database and system preferences
3. **Data Management**: Import/export data and manage academic records
4. **Advanced Features**: Access all system functionalities

## 🔧 Configuration

### Environment Variables
Create a `.env` file in the root directory:
```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

### App Configuration
Key configuration files:
- `lib/config/app_config.dart` - App-wide configuration
- `lib/services/supabase_service.dart` - Database connection
- `pubspec.yaml` - Dependencies and app metadata

## 📞 Support & Contact

- **Issues**: [GitHub Issues](https://github.com/deepak-9962/campus_sync_app/issues)
- **Discussions**: [GitHub Discussions](https://github.com/deepak-9962/campus_sync_app/discussions)
- **Email**: [Contact Developer](mailto:deepak.9962@example.com)

## 🗂️ Project Structure

```
campus_sync_app/
├── android/                     # Android platform files
├── ios/                        # iOS platform files
├── web/                        # Web platform files
├── windows/                    # Windows platform files
├── linux/                      # Linux platform files
├── macos/                      # macOS platform files
├── assets/                     # App assets
│   ├── fonts/                  # Custom fonts
│   ├── icon/                   # App icons
│   └── videos/                 # Video assets
├── lib/                        # Main application code
│   ├── main.dart               # App entry point
│   ├── config/                 # App configuration
│   ├── models/                 # Data models
│   ├── screens/                # UI screens
│   │   ├── about_us_screen.dart
│   │   ├── announcements_screen.dart
│   │   ├── attendance_lookup_screen.dart
│   │   ├── attendance_screen.dart
│   │   ├── attendance_view_screen.dart
│   │   ├── auth_screen.dart
│   │   ├── daily_attendance_screen.dart
│   │   ├── database_setup_screen.dart
│   │   ├── faculty_dashboard_screen.dart
│   │   ├── gpa_cgpa_calculator_screen.dart
│   │   ├── home_screen.dart
│   │   ├── library_screen.dart
│   │   ├── link_student_account_screen.dart
│   │   ├── lost_found_screen.dart
│   │   ├── marks_entry_screen.dart
│   │   ├── profile_settings_screen.dart
│   │   ├── regulation_selection_screen.dart
│   │   ├── resource_hub_screen.dart
│   │   ├── role_test_screen.dart
│   │   ├── sem_screen.dart
│   │   ├── splash_screen.dart
│   │   ├── staff_attendance_screen.dart
│   │   ├── student_attendance_screen.dart
│   │   ├── timetable_editor_screen.dart
│   │   ├── timetable_screen.dart
│   │   └── view_marks_screen.dart
│   ├── services/               # Backend services
│   │   ├── attendance_service.dart
│   │   ├── auth_service.dart
│   │   ├── resource_service.dart
│   │   └── timetable_management_service.dart
│   ├── widgets/                # Reusable widgets
│   └── utils/                  # Utility functions
├── sql files/                  # Database scripts
├── supabase/                   # Supabase configuration
├── test/                       # Test files
├── docs/                       # Documentation files
│   ├── COUNCIL_DEMO_GUIDE.md
│   ├── DBMS_MARKS_GUIDE.md
│   ├── DEPARTMENT_SEMESTER_SWITCHER_FEATURE.md
│   ├── DEPLOYMENT_GUIDE.md
│   ├── MARKS_SYSTEM_GUIDE.md
│   ├── PERIOD_ATTENDANCE_IMPLEMENTATION_GUIDE.md
│   ├── PROPER_DATABASE_SCHEMA_FIX.md
│   ├── Project_Abstract.md
│   ├── STAFF_ADMIN_TIMETABLE_EDITING_STATUS.md
│   ├── STUDENT_ATTENDANCE_GUIDE.md
│   ├── TIMETABLE_CONFLICT_FINAL_FIX.md
│   ├── TIMETABLE_DATABASE_ERROR_FIXED.md
│   ├── TIMETABLE_EDITING_CONFLICT_FIX.md
│   ├── TIMETABLE_FINAL_SCHEMA_FIX.md
│   ├── TIMETABLE_MANAGEMENT_GUIDE.md
│   └── TIMETABLE_ROOT_CAUSE_FIXED.md
├── build/                      # Build output directory
├── pubspec.yaml               # Flutter dependencies
├── pubspec.lock               # Dependency lock file
├── analysis_options.yaml     # Code analysis configuration
├── devtools_options.yaml     # DevTools configuration
└── README.md                  # Project documentation
```

### Key Directories

#### `/lib/screens/`
Contains all UI screens organized by functionality:
- **Authentication**: `auth_screen.dart`
- **Home & Navigation**: `home_screen.dart`, `splash_screen.dart`
- **Attendance Management**: 
  - `attendance_screen.dart` - Main attendance interface
  - `attendance_view_screen.dart` - Attendance viewing with analytics
  - `staff_attendance_screen.dart` - Staff attendance marking
  - `student_attendance_screen.dart` - Student attendance viewing
  - `daily_attendance_screen.dart` - Daily attendance reports
  - `attendance_lookup_screen.dart` - Attendance search
  - `link_student_account_screen.dart` - Student account linking
- **Timetable**: 
  - `timetable_screen.dart` - Timetable viewing
  - `timetable_editor_screen.dart` - Timetable management
- **Academic Tools**:
  - `gpa_cgpa_calculator_screen.dart` - GPA calculation
  - `marks_entry_screen.dart` - Marks management
  - `view_marks_screen.dart` - Marks viewing
- **Resources**: `resource_hub_screen.dart` - Document management
- **Administration**:
  - `faculty_dashboard_screen.dart` - Faculty tools
  - `database_setup_screen.dart` - System setup
  - `role_test_screen.dart` - Role testing
- **Additional Features**:
  - `library_screen.dart` - Library integration
  - `announcements_screen.dart` - Campus announcements
  - `lost_found_screen.dart` - Lost & Found
  - `profile_settings_screen.dart` - User profile
  - `about_us_screen.dart` - App information

#### `/lib/services/`
Backend service classes for data management:
- `attendance_service.dart` - Attendance operations and analytics
- `auth_service.dart` - User authentication and authorization
- `resource_service.dart` - File and resource management
- `timetable_management_service.dart` - Timetable CRUD operations

#### `/docs/`
Comprehensive documentation for different features and implementations

## 🚦 Current Status

### ✅ Completed Features
- ✅ User Authentication & Role Management
- ✅ Period-Based Attendance System
- ✅ Comprehensive Timetable Management
- ✅ Resource Hub with File Management
- ✅ GPA/CGPA Calculator (5 Departments)
- ✅ Student Account Linking
- ✅ Cross-Platform Support
- ✅ Real-time Data Synchronization

### 🔄 In Progress
- 🔄 Push Notifications
- 🔄 Advanced Analytics Dashboard
- 🔄 Bulk Import/Export Features
- 🔄 Mobile App Optimization

### 📋 Planned Features
- 📋 Library Integration
- 📋 Examination Management
- 📋 Fee Management System
- 📋 Parent Portal
- 📋 Alumni Network

---

**Made with ❤️ by [Deepak](https://github.com/deepak-9962)**

*Transforming education through technology*
