# Timetable Management System - Admin & Staff Access Guide

## Overview
The Campus Sync app now provides comprehensive timetable management capabilities for both **Admin** and **Staff** users. This system allows authorized users to create, edit, and manage class schedules with advanced features like conflict detection, template loading, and section copying.

## Access Control

### Who Can Edit Timetables?
- ✅ **Admin users** - Full access to all timetable management features
- ✅ **Staff users** - Full access to all timetable management features  
- ✅ **Faculty users** - Full access to all timetable management features
- ✅ **Teacher users** - Full access to all timetable management features
- ❌ **Student users** - Read-only access (can view timetables only)

### How to Access Timetable Management

#### Method 1: Via Faculty Dashboard
1. Login with your Admin/Staff account
2. From the Home Screen, tap **"Faculty Dashboard"**
3. In the Faculty Dashboard, tap **"Edit Timetable"**

#### Method 2: Direct Quick Action
1. Login with your Admin/Staff account
2. From the Home Screen, scroll to **"Quick Actions"** section
3. Tap **"Edit Timetable"**

## Features Available

### 1. Create/Edit Class Periods
- Add new class periods with subject, faculty, room, and batch information
- Edit existing periods with full form validation
- Autocomplete suggestions for faculty names and room numbers
- Batch selection for lab sessions (B1, B2, or Full Class)

### 2. Time Conflict Detection
- Automatic detection of scheduling conflicts
- Prevents double-booking of faculty or rooms
- Real-time validation when adding/editing periods

### 3. Department & Section Management
- Support for all engineering departments
- Semester-wise timetable management (1-8)
- Section-wise scheduling (A, B, C, etc.)

### 4. Advanced Operations
- **Copy Timetable**: Copy entire timetable from one section to another
- **Load Template**: Apply standard timetable templates
- **Clear All**: Remove all classes for selected department/semester/section
- **Export**: Export timetable data (planned feature)

### 5. Day-wise Editing
- Tabbed interface for each day of the week (Monday-Saturday)
- Visual period cards showing time slots and class details
- Drag-and-drop style editing interface

## Database Structure

### Tables Used
- `class_schedule` - Main timetable data storage
- `subjects` - Subject information and codes
- `users` - User roles and permissions

### Required Permissions
Run the `setup_timetable_permissions.sql` file in your Supabase SQL Editor to ensure proper Row Level Security (RLS) policies are in place.

## Technical Implementation

### Frontend Components
- **TimetableEditorScreen**: Main editing interface
- **PeriodDialog**: Modal for adding/editing individual periods
- **TimetableManagementService**: Backend service handling CRUD operations
- **Faculty Dashboard**: Centralized access point for all faculty tools

### Backend Services
- Full CRUD operations with conflict detection
- Supabase integration with RLS policies
- Real-time validation and error handling

## Usage Examples

### Adding a New Class Period
1. Select Department, Semester, and Section
2. Choose the day tab (e.g., Monday)
3. Click "+" on an empty time slot
4. Fill in: Subject, Faculty, Room, Batch (if applicable)
5. Save - automatic conflict detection runs

### Copying Timetable Between Sections
1. Use the menu (⋮) in the top-right
2. Select "Copy from Section"
3. Choose source section (e.g., Section A)
4. Confirm copy to current section (e.g., Section B)

### Loading a Standard Template
1. Use the menu (⋮) in the top-right
2. Select "Load Template"
3. Confirm to apply standard template structure

## Security Notes
- All timetable modifications are logged with timestamps
- Only authenticated users with appropriate roles can make changes
- Row Level Security ensures data isolation and access control
- Real-time conflict detection prevents scheduling errors

## Troubleshooting

### Common Issues
1. **"Permission Denied" errors**: Ensure user role is set correctly in database
2. **Conflict detection false positives**: Check for duplicate entries in database
3. **Data not saving**: Verify network connection and Supabase configuration

### Database Verification
```sql
-- Check user role
SELECT role FROM users WHERE id = auth.uid();

-- Verify RLS policies
SELECT * FROM pg_policies WHERE tablename = 'class_schedule';
```

## Future Enhancements
- Bulk import/export functionality
- Advanced recurring schedule templates
- Integration with attendance tracking
- Mobile app push notifications for schedule changes
- Advanced reporting and analytics
