# Department and Semester Switcher Feature

## Overview
Added a convenient department and semester switcher to both the student home screen and faculty dashboard hamburger menus. This allows users to switch between different departments and semesters without needing to log out and log back in.

## Features Added

### 1. Student Home Screen (`lib/screens/home_screen.dart`)
- Added "Switch Department/Semester" option to the drawer menu
- Beautiful dialog with dropdown selections for department and semester
- Real-time preview of current selection
- Updates the entire app view to show content for selected department/semester
- Shows confirmation message when changes are applied

### 2. Faculty Dashboard Screen (`lib/screens/faculty_dashboard_screen.dart`) 
- Added "Switch Department/Semester" option to the faculty drawer menu
- Same intuitive dialog interface as student screen
- Updates faculty view to show content for selected department/semester
- Header displays current selected department and semester

## How It Works

### For Students:
1. Open the hamburger menu (☰) in the home screen
2. Tap on "Switch Department/Semester"
3. Select desired department from dropdown
4. Select desired semester (1-8)
5. Tap "Apply Changes"
6. The entire app view updates to show content for the selected department/semester

### For Faculty:
1. Open the hamburger menu (☰) in the faculty dashboard
2. Tap on "Switch Department/Semester"  
3. Select desired department from dropdown
4. Select desired semester (1-8)
5. Tap "Apply Changes"
6. Faculty view updates to show content for the selected department/semester

## Available Departments
- Computer Science and Engineering
- Electronics and Communication Engineering
- Mechanical Engineering
- Civil Engineering
- Electrical and Electronics Engineering
- Information Technology
- Chemical Engineering
- Biotechnology

## Available Semesters
- Semester 1 through Semester 8

## Benefits
- **No Re-login Required**: Switch departments/semesters instantly without signing out
- **Universal Access**: Works for all user roles (students, faculty, admin)
- **Real-time Updates**: All screens immediately reflect the new department/semester selection
- **Intuitive Interface**: Clean, user-friendly dialog with dropdowns
- **Visual Feedback**: Headers and navigation show currently selected department/semester
- **Persistent Selection**: Selected department/semester remains active until changed again

## Technical Implementation
- Uses `StatefulBuilder` for reactive dialog updates
- Maintains selected values in widget state variables
- Updates all navigation parameters to use selected values instead of original profile values
- Provides visual confirmation through SnackBar messages
- Clean, Material Design-compliant interface

## Usage Examples

### Staff Attendance System
Now staff can easily switch to mark attendance for different departments and semesters:
1. Switch to "Computer Science and Engineering - Semester 3"
2. Mark period-wise attendance for CSE students
3. Switch to "Mechanical Engineering - Semester 5" 
4. Mark attendance for Mechanical Engineering students
5. All without logging out and back in!

### Student View
Students can explore content from different departments:
1. View timetables for different semesters
2. Check attendance records across departments
3. Access resources from various engineering branches
4. Compare curriculum across different programs

This feature significantly improves the user experience by providing flexibility and convenience for all users of the Campus Sync app!
