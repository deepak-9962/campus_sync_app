-- Check current users and their roles
SELECT email, role, name, id FROM users ORDER BY email;

-- Show the current authenticated user (if possible to determine)
-- This would need to be matched with the current session
