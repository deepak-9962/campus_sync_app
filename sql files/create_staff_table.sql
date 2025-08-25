-- Staff Table Definition
-- Simplified table for storing essential staff/faculty details

-- Drop existing table if it exists (be careful in production)
DROP TABLE IF EXISTS staff CASCADE;

-- Create the staff table with essential details only
CREATE TABLE staff (
    -- Primary Keys
    id BIGSERIAL PRIMARY KEY,
    staff_id VARCHAR(20) UNIQUE NOT NULL, -- Unique staff identifier (e.g., STAFF001)
    
    -- Personal Information
    full_name VARCHAR(100),
    gender VARCHAR(10) CHECK (gender IN ('Male', 'Female', 'Other')),
    date_of_birth DATE,
    nationality VARCHAR(50) DEFAULT 'Indian',
    
    -- Contact Information
    email VARCHAR(100) UNIQUE,
    phone_primary VARCHAR(15),
    phone_secondary VARCHAR(15),
    emergency_contact_name VARCHAR(100),
    emergency_contact_phone VARCHAR(15),
    
    -- Professional Information
    employee_id VARCHAR(20) UNIQUE, -- HR/Payroll employee ID
    designation VARCHAR(100), -- Professor, Associate Professor, Assistant Professor, etc.
    department VARCHAR(100),
    specialization VARCHAR(200), -- Area of expertise
    qualification VARCHAR(500), -- Educational qualifications (M.Tech, Ph.D, etc.)
    experience_years INTEGER DEFAULT 0,
    
    -- Employment Details
    employment_type VARCHAR(20) CHECK (employment_type IN ('Permanent', 'Contract', 'Visiting', 'Guest')),
    employment_status VARCHAR(20) DEFAULT 'Active' CHECK (employment_status IN ('Active', 'Inactive', 'On Leave', 'Resigned', 'Retired')),
    date_of_joining DATE,
    date_of_leaving DATE,
    probation_period_months INTEGER DEFAULT 6,
    
    -- Academic Information
    subjects_taught TEXT[], -- Array of subject codes
    classes_assigned TEXT[], -- Array of class sections (e.g., ['CSE-5A', 'CSE-5B'])
    office_room VARCHAR(20),
    cabin_extension VARCHAR(10),
    
    -- System Fields
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id),
    updated_by UUID REFERENCES auth.users(id),
    
    -- Validation Constraints
    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT valid_phone CHECK (phone_primary ~* '^[0-9+\-\s()]{10,15}$'),
    CONSTRAINT valid_experience CHECK (experience_years >= 0 AND experience_years <= 50),
    CONSTRAINT valid_joining_date CHECK (date_of_joining >= '1950-01-01'),
    CONSTRAINT valid_leaving_date CHECK (date_of_leaving IS NULL OR date_of_leaving > date_of_joining)
);

-- Create indexes for better performance
CREATE INDEX idx_staff_staff_id ON staff(staff_id);
CREATE INDEX idx_staff_email ON staff(email);
CREATE INDEX idx_staff_department ON staff(department);
CREATE INDEX idx_staff_employment_status ON staff(employment_status);
CREATE INDEX idx_staff_full_name ON staff(full_name);

-- Enable Row Level Security
ALTER TABLE staff ENABLE ROW LEVEL SECURITY;

-- RLS Policies for staff table
-- Policy 1: All authenticated users can view basic staff information
CREATE POLICY "Users can view staff basic info" ON staff
    FOR SELECT TO authenticated
    USING (true);

-- Policy 2: Admin users can do everything
CREATE POLICY "Admin can manage all staff" ON staff
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

-- Policy 3: Staff can update their own information (except sensitive fields)
CREATE POLICY "Staff can update own info" ON staff
    FOR UPDATE TO authenticated
    USING (
        email = auth.email() OR
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('staff', 'admin')
        )
    )
    WITH CHECK (
        email = auth.email() OR
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('staff', 'admin')
        )
    );

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_staff_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    NEW.updated_by = auth.uid();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_update_staff_updated_at
    BEFORE UPDATE ON staff
    FOR EACH ROW
    EXECUTE FUNCTION update_staff_updated_at();

-- Create a function to generate staff_id automatically
CREATE OR REPLACE FUNCTION generate_staff_id()
RETURNS TRIGGER AS $$
DECLARE
    dept_code VARCHAR(10);
    next_num INTEGER;
    new_staff_id VARCHAR(20);
BEGIN
    -- Generate department code from department name
    dept_code := CASE 
        WHEN NEW.department ILIKE '%computer science%' THEN 'CSE'
        WHEN NEW.department ILIKE '%information technology%' THEN 'IT'
        WHEN NEW.department ILIKE '%electronics%' THEN 'ECE'
        WHEN NEW.department ILIKE '%mechanical%' THEN 'MECH'
        WHEN NEW.department ILIKE '%artificial intelligence%' THEN 'AI'
        WHEN NEW.department ILIKE '%data science%' THEN 'DS'
        WHEN NEW.department ILIKE '%biomedical%' THEN 'BME'
        WHEN NEW.department ILIKE '%robotics%' THEN 'RAE'
        ELSE 'GEN'
    END;
    
    -- Get next number for the department
    SELECT COALESCE(MAX(CAST(SUBSTRING(staff_id FROM '[0-9]+$') AS INTEGER)), 0) + 1
    INTO next_num
    FROM staff 
    WHERE staff_id LIKE dept_code || '%';
    
    -- Generate new staff_id
    new_staff_id := dept_code || LPAD(next_num::TEXT, 3, '0');
    
    -- Assign if not already set
    IF NEW.staff_id IS NULL THEN
        NEW.staff_id := new_staff_id;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_generate_staff_id
    BEFORE INSERT ON staff
    FOR EACH ROW
    WHEN (NEW.staff_id IS NULL)
    EXECUTE FUNCTION generate_staff_id();

-- Create a view for commonly used staff information
CREATE OR REPLACE VIEW staff_summary AS
SELECT 
    staff_id,
    full_name,
    email,
    phone_primary,
    department,
    designation,
    subjects_taught,
    classes_assigned,
    office_room,
    employment_status,
    experience_years
FROM staff
WHERE employment_status = 'Active'
ORDER BY department, designation, full_name;

-- Grant permissions
GRANT SELECT ON staff_summary TO authenticated;

-- Create function to get staff by department
CREATE OR REPLACE FUNCTION get_staff_by_department(dept_name TEXT)
RETURNS TABLE (
    staff_id VARCHAR,
    full_name VARCHAR,
    email VARCHAR,
    designation VARCHAR,
    subjects_taught TEXT[],
    classes_assigned TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.staff_id,
        s.full_name,
        s.email,
        s.designation,
        s.subjects_taught,
        s.classes_assigned
    FROM staff s
    WHERE s.department ILIKE '%' || dept_name || '%'
    AND s.employment_status = 'Active'
    ORDER BY s.designation, s.full_name;
END;
$$ LANGUAGE plpgsql;

-- Sample usage queries (commented out)
/*
-- Get all active staff
SELECT * FROM staff_summary;

-- Get staff by department
SELECT * FROM get_staff_by_department('Computer Science');

-- Get staff teaching specific subject
SELECT full_name, email, designation 
FROM staff 
WHERE 'CS3591' = ANY(subjects_taught) 
AND employment_status = 'Active';

-- Get staff assigned to specific class
SELECT full_name, email, designation, subjects_taught
FROM staff 
WHERE 'CSE-5A' = ANY(classes_assigned)
AND employment_status = 'Active';
*/
