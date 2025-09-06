# HOD (Head of Department) Role Implementation Guide

## Overview
This implementation adds HOD role functionality to Campus Sync, allowing department heads to view comprehensive attendance statistics for their entire department.

## Features for HOD Users

### 1. Department-wide Attendance Dashboard
- **Total students** in the department across all semesters
- **Average attendance percentage** for the department
- **Today's attendance summary** (present/absent counts)
- **Low attendance alerts** (students below 75%)

### 2. Semester-wise View
- Breakdown by semester (1st to 8th year)
- Individual student attendance percentages
- Section-wise statistics

### 3. Low Attendance Monitoring
- List of students with attendance below 75%
- Detailed view with registration numbers and percentages
- Early intervention alerts

## Implementation Steps

### Step 1: Database Setup
Run the SQL script to set up HOD permissions:

```bash
# Execute this in your Supabase SQL Editor
# File: sql files/create_hod_role_and_permissions.sql
```

Key changes:
- Adds `role` and `assigned_department` columns to users table
- Creates department-wide attendance view
- Sets up Row Level Security for HOD access
- Creates summary statistics function

### Step 2: Create HOD User Account

Option A: Via Supabase Dashboard
1. Go to Authentication > Users
2. Create new user with HOD email
3. Go to Table Editor > users table
4. Find the new user and set:
   - `role` = 'hod'
   - `assigned_department` = 'Computer Science Engineering' (or appropriate dept)

Option B: Via SQL (Example)
```sql
-- Replace with actual HOD details
INSERT INTO auth.users (email, email_confirmed_at) 
VALUES ('hod.cse@college.edu', now());

INSERT INTO users (id, name, email, role, assigned_department) 
VALUES (
    (SELECT id FROM auth.users WHERE email = 'hod.cse@college.edu'),
    'Dr. CSE HOD Name',
    'hod.cse@college.edu',
    'hod',
    'Computer Science Engineering'
);
```

### Step 3: Access Control Implementation

The system implements these access levels:

#### HOD Role Permissions:
- ✅ View attendance data for assigned department only
- ✅ View all semesters in their department
- ✅ Access to low attendance student lists
- ✅ Department-wide statistics and reports
- ❌ Cannot edit attendance (read-only)
- ❌ Cannot view other departments

#### Security Features:
- Row Level Security (RLS) enforces department boundaries
- HODs can only access their assigned department's data
- All queries are filtered by department automatically

## How to Access HOD Dashboard

### For HOD Users:
1. Login with HOD credentials
2. The system automatically detects HOD role
3. HOD Dashboard will be available in navigation
4. Dashboard shows assigned department's data only

### For Admins:
- Admins can view all departments
- Can switch between department views
- Full access to all HOD features across departments

## Staff vs HOD Access

### Current Staff Access:
- Mark attendance for classes they teach
- View student attendance in their classes
- Edit timetables (if staff/admin role)

### New HOD Access:
- View entire department attendance overview
- Monitor all students across all semesters
- Identify students needing attention
- Department-wide performance metrics

## HOD Dashboard Features

### 1. Summary Cards
```
┌─────────────────┬─────────────────┐
│ Total Students  │ Avg Attendance  │
│      245        │      82.5%      │
└─────────────────┴─────────────────┘
┌─────────────────┬─────────────────┐
│ Today Present   │ Today Absent    │
│      198        │       47        │
└─────────────────┴─────────────────┘
```

### 2. Semester-wise Breakdown
- Expandable cards for each semester
- Quick stats: student count, average attendance
- Detailed view with individual student records

### 3. Low Attendance Alerts
- Red-flagged students below 75%
- Sortable by attendance percentage
- Contact information for intervention

## Should You Make This Transparent to All Staff?

### Recommendation: Create HOD Role (Not Transparent)

**Reasons for HOD-only access:**
1. **Privacy**: Student data should be on need-to-know basis
2. **Hierarchy**: Department overview is HOD responsibility
3. **Focus**: Staff should focus on their own classes
4. **Security**: Reduces potential data access issues

**If you choose transparency:**
- All staff would see all department data
- Might violate privacy principles
- Could cause confusion about responsibilities

## Database Schema Changes

### New Columns in `users` table:
```sql
- role: TEXT (values: 'student', 'staff', 'admin', 'hod')
- assigned_department: TEXT (for HOD users)
```

### New Functions:
- `get_department_attendance_summary()` - Overall dept stats
- Department-wide attendance views with RLS

## Migration Guide

### For Existing Users:
1. Run the SQL migration script
2. Update existing admin/staff roles if needed:
```sql
UPDATE users SET role = 'admin' WHERE is_admin = true;
UPDATE users SET role = 'staff' WHERE role IS NULL AND is_admin = false;
```

### For New HOD Setup:
1. Create HOD user account
2. Assign department in users table
3. HOD can immediately access their department dashboard

## Testing Checklist

### HOD User Testing:
- [ ] Can login with HOD credentials
- [ ] Sees only assigned department data
- [ ] Cannot access other departments
- [ ] Dashboard loads department statistics
- [ ] Can view semester-wise breakdown
- [ ] Low attendance list shows correctly

### Security Testing:
- [ ] HOD cannot access other departments
- [ ] Staff still have their normal access
- [ ] Students cannot access HOD features
- [ ] Admin can still access everything

## Future Enhancements

1. **Email Notifications**: Alert HOD about low attendance
2. **Report Generation**: Export department reports
3. **Trend Analysis**: Attendance trends over time
4. **Integration**: Connect with academic calendar
5. **Mobile Push**: Important attendance alerts

This implementation provides your HOD with the comprehensive department overview they requested while maintaining proper security and role boundaries.
