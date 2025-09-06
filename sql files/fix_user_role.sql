-- First, let's see all users and their roles
SELECT email, role, name, created_at FROM users ORDER BY email;

-- To change a specific user from admin to staff, replace 'user@example.com' with the actual email
-- UPDATE users SET role = 'staff' WHERE email = 'user@example.com';

-- Example: If you want to change the admin user to staff
-- UPDATE users SET role = 'staff' WHERE role = 'admin' AND email = 'admin@yourcollege.com';

-- To create a new staff user (if needed), you would first need to sign up with the email,
-- then update their role:
-- UPDATE users SET role = 'staff' WHERE email = 'newstaff@yourcollege.com';
