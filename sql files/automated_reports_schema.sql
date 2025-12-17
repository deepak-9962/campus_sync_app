-- ============================================================================
-- AUTOMATED REPORTS SCHEMA
-- Run this in Supabase SQL Editor to set up the required tables
-- ============================================================================

-- ============================================================================
-- 1. SCHEDULED REPORTS TABLE
-- Stores configuration for automated report generation
-- ============================================================================

CREATE TABLE IF NOT EXISTS scheduled_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_type TEXT NOT NULL CHECK (report_type IN ('dailyAttendance', 'weeklyLowAttendance', 'monthlyAnalytics', 'semesterConsolidation')),
    department TEXT NOT NULL,
    semester INTEGER,
    section TEXT,
    recipients JSONB DEFAULT '[]'::jsonb,
    frequency TEXT NOT NULL CHECK (frequency IN ('daily', 'weekly', 'monthly', 'semesterEnd')),
    scheduled_hour INTEGER NOT NULL DEFAULT 17 CHECK (scheduled_hour >= 0 AND scheduled_hour <= 23),
    scheduled_minute INTEGER NOT NULL DEFAULT 0 CHECK (scheduled_minute >= 0 AND scheduled_minute <= 59),
    enabled BOOLEAN DEFAULT true,
    created_by UUID REFERENCES auth.users(id),
    last_run TIMESTAMPTZ,
    next_run TIMESTAMPTZ,
    run_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_scheduled_reports_department ON scheduled_reports(department);
CREATE INDEX IF NOT EXISTS idx_scheduled_reports_next_run ON scheduled_reports(next_run) WHERE enabled = true;
CREATE INDEX IF NOT EXISTS idx_scheduled_reports_enabled ON scheduled_reports(enabled);

-- Enable RLS
ALTER TABLE scheduled_reports ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can view their department's scheduled reports" ON scheduled_reports;
CREATE POLICY "Users can view their department's scheduled reports" ON scheduled_reports
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND (
                users.role IN ('admin', 'hod') 
                OR users.is_admin = true
                OR (users.role = 'hod' AND users.assigned_department = scheduled_reports.department)
            )
        )
    );

DROP POLICY IF EXISTS "HOD and Admin can manage scheduled reports" ON scheduled_reports;
CREATE POLICY "HOD and Admin can manage scheduled reports" ON scheduled_reports
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND (
                users.role IN ('admin') 
                OR users.is_admin = true
                OR (users.role = 'hod' AND users.assigned_department = scheduled_reports.department)
            )
        )
    );

-- ============================================================================
-- 2. REPORT LOGS TABLE
-- Audit trail for generated reports
-- ============================================================================

CREATE TABLE IF NOT EXISTS report_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_type TEXT NOT NULL,
    department TEXT NOT NULL,
    semester INTEGER,
    section TEXT,
    generated_by TEXT,
    file_url TEXT,
    file_size INTEGER,
    generation_time_ms INTEGER,
    status TEXT DEFAULT 'success' CHECK (status IN ('success', 'failed', 'pending')),
    error_message TEXT,
    generated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_report_logs_department ON report_logs(department);
CREATE INDEX IF NOT EXISTS idx_report_logs_generated_at ON report_logs(generated_at DESC);
CREATE INDEX IF NOT EXISTS idx_report_logs_report_type ON report_logs(report_type);

-- Enable RLS
ALTER TABLE report_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can view report logs for their department" ON report_logs;
CREATE POLICY "Users can view report logs for their department" ON report_logs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND (
                users.role IN ('admin', 'hod', 'staff') 
                OR users.is_admin = true
            )
        )
    );

DROP POLICY IF EXISTS "System can insert report logs" ON report_logs;
CREATE POLICY "System can insert report logs" ON report_logs
    FOR INSERT WITH CHECK (true);

-- ============================================================================
-- 3. EMAIL QUEUE TABLE
-- Queue for pending email deliveries
-- ============================================================================

CREATE TABLE IF NOT EXISTS email_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient TEXT NOT NULL,
    subject TEXT NOT NULL,
    body TEXT NOT NULL,
    attachment_url TEXT,
    attachment_name TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed', 'cancelled')),
    attempts INTEGER DEFAULT 0,
    last_attempt TIMESTAMPTZ,
    error_message TEXT,
    scheduled_for TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    sent_at TIMESTAMPTZ
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_email_queue_status ON email_queue(status);
CREATE INDEX IF NOT EXISTS idx_email_queue_scheduled ON email_queue(scheduled_for) WHERE status = 'pending';

-- Enable RLS
ALTER TABLE email_queue ENABLE ROW LEVEL SECURITY;

-- Allow system to manage email queue
DROP POLICY IF EXISTS "System can manage email queue" ON email_queue;
CREATE POLICY "System can manage email queue" ON email_queue
    FOR ALL USING (true);

-- ============================================================================
-- 4. HELPER FUNCTIONS
-- ============================================================================

-- Function to increment run count
CREATE OR REPLACE FUNCTION increment_run_count(row_id UUID)
RETURNS INTEGER AS $$
DECLARE
    new_count INTEGER;
BEGIN
    UPDATE scheduled_reports 
    SET run_count = run_count + 1 
    WHERE id = row_id
    RETURNING run_count INTO new_count;
    
    RETURN new_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get due scheduled reports
CREATE OR REPLACE FUNCTION get_due_reports()
RETURNS SETOF scheduled_reports AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM scheduled_reports
    WHERE enabled = true
    AND next_run <= NOW()
    ORDER BY next_run;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update next run time based on frequency
CREATE OR REPLACE FUNCTION update_next_run(schedule_id UUID)
RETURNS VOID AS $$
DECLARE
    sched scheduled_reports%ROWTYPE;
    next_time TIMESTAMPTZ;
BEGIN
    SELECT * INTO sched FROM scheduled_reports WHERE id = schedule_id;
    
    IF sched IS NULL THEN
        RETURN;
    END IF;
    
    -- Calculate next run based on frequency
    CASE sched.frequency
        WHEN 'daily' THEN
            next_time := (CURRENT_DATE + INTERVAL '1 day' + 
                         (sched.scheduled_hour || ' hours')::INTERVAL + 
                         (sched.scheduled_minute || ' minutes')::INTERVAL);
        WHEN 'weekly' THEN
            -- Next Monday
            next_time := date_trunc('week', CURRENT_DATE + INTERVAL '1 week') + 
                         (sched.scheduled_hour || ' hours')::INTERVAL + 
                         (sched.scheduled_minute || ' minutes')::INTERVAL;
        WHEN 'monthly' THEN
            -- 1st of next month
            next_time := date_trunc('month', CURRENT_DATE + INTERVAL '1 month') + 
                         (sched.scheduled_hour || ' hours')::INTERVAL + 
                         (sched.scheduled_minute || ' minutes')::INTERVAL;
        WHEN 'semesterEnd' THEN
            -- End of semester (June 30 or December 31)
            IF EXTRACT(MONTH FROM CURRENT_DATE) <= 6 THEN
                next_time := make_date(EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER, 6, 30) + 
                             (sched.scheduled_hour || ' hours')::INTERVAL + 
                             (sched.scheduled_minute || ' minutes')::INTERVAL;
            ELSE
                next_time := make_date(EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER, 12, 31) + 
                             (sched.scheduled_hour || ' hours')::INTERVAL + 
                             (sched.scheduled_minute || ' minutes')::INTERVAL;
            END IF;
            
            IF next_time <= NOW() THEN
                next_time := make_date(EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER + 1, 6, 30) + 
                             (sched.scheduled_hour || ' hours')::INTERVAL + 
                             (sched.scheduled_minute || ' minutes')::INTERVAL;
            END IF;
        ELSE
            next_time := NOW() + INTERVAL '1 day';
    END CASE;
    
    UPDATE scheduled_reports 
    SET next_run = next_time, 
        last_run = NOW(),
        run_count = run_count + 1,
        updated_at = NOW()
    WHERE id = schedule_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 5. ANALYTICS VIEWS FOR REPORTS
-- ============================================================================

-- Daily attendance trends view
CREATE OR REPLACE VIEW daily_attendance_trends AS
SELECT 
    a.date,
    s.department,
    s.semester,
    s.section,
    COUNT(DISTINCT a.registration_no) as total_students,
    COUNT(DISTINCT CASE WHEN a.is_present THEN a.registration_no END) as present_count,
    COUNT(DISTINCT CASE WHEN NOT a.is_present THEN a.registration_no END) as absent_count,
    ROUND(
        COUNT(DISTINCT CASE WHEN a.is_present THEN a.registration_no END)::DECIMAL / 
        NULLIF(COUNT(DISTINCT a.registration_no), 0) * 100, 
        2
    ) as attendance_percentage
FROM attendance a
JOIN students s ON a.registration_no = s.registration_no
GROUP BY a.date, s.department, s.semester, s.section
ORDER BY a.date DESC, s.department, s.semester, s.section;

-- Monthly statistics view
CREATE OR REPLACE VIEW monthly_attendance_stats AS
SELECT 
    date_trunc('month', a.date) as month,
    s.department,
    s.semester,
    COUNT(DISTINCT a.date) as working_days,
    COUNT(DISTINCT s.registration_no) as total_students,
    ROUND(AVG(
        CASE WHEN a.is_present THEN 100 ELSE 0 END
    ), 2) as avg_attendance_percentage
FROM attendance a
JOIN students s ON a.registration_no = s.registration_no
GROUP BY date_trunc('month', a.date), s.department, s.semester
ORDER BY month DESC, s.department, s.semester;

-- Function to get daily trends for a date range
CREATE OR REPLACE FUNCTION get_daily_attendance_trends(
    p_department TEXT,
    p_semester INTEGER DEFAULT NULL,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS TABLE (
    date DATE,
    present INTEGER,
    absent INTEGER,
    percentage DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.date::DATE,
        COUNT(DISTINCT CASE WHEN a.is_present THEN a.registration_no END)::INTEGER as present,
        COUNT(DISTINCT CASE WHEN NOT a.is_present THEN a.registration_no END)::INTEGER as absent,
        ROUND(
            COUNT(DISTINCT CASE WHEN a.is_present THEN a.registration_no END)::DECIMAL / 
            NULLIF(COUNT(DISTINCT a.registration_no), 0) * 100, 
            2
        ) as percentage
    FROM attendance a
    JOIN students s ON a.registration_no = s.registration_no
    WHERE s.department ILIKE '%' || p_department || '%'
    AND (p_semester IS NULL OR s.semester = p_semester)
    AND (p_start_date IS NULL OR a.date >= p_start_date)
    AND (p_end_date IS NULL OR a.date <= p_end_date)
    GROUP BY a.date
    ORDER BY a.date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 6. CRON SETUP (requires pg_cron extension)
-- ============================================================================

-- Enable pg_cron extension (run as superuser)
-- CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule daily report check at 5 PM IST (11:30 AM UTC)
-- SELECT cron.schedule('check-daily-reports', '30 11 * * 1-6', 
--     $$SELECT net.http_post(
--         'https://YOUR_PROJECT_REF.supabase.co/functions/v1/process-scheduled-reports',
--         headers := '{"Authorization": "Bearer YOUR_SERVICE_ROLE_KEY"}'::jsonb
--     )$$
-- );

-- Schedule weekly report check on Monday at 8 AM IST (2:30 AM UTC)
-- SELECT cron.schedule('check-weekly-reports', '30 2 * * 1', 
--     $$SELECT net.http_post(
--         'https://YOUR_PROJECT_REF.supabase.co/functions/v1/process-scheduled-reports',
--         headers := '{"Authorization": "Bearer YOUR_SERVICE_ROLE_KEY"}'::jsonb,
--         body := '{"frequency": "weekly"}'::jsonb
--     )$$
-- );

-- Schedule monthly report check on 1st at 8 AM IST (2:30 AM UTC)
-- SELECT cron.schedule('check-monthly-reports', '30 2 1 * *', 
--     $$SELECT net.http_post(
--         'https://YOUR_PROJECT_REF.supabase.co/functions/v1/process-scheduled-reports',
--         headers := '{"Authorization": "Bearer YOUR_SERVICE_ROLE_KEY"}'::jsonb,
--         body := '{"frequency": "monthly"}'::jsonb
--     )$$
-- );

-- ============================================================================
-- 7. STORAGE BUCKET FOR REPORTS
-- ============================================================================

-- Create storage bucket for reports (run in Supabase Dashboard or via API)
-- INSERT INTO storage.buckets (id, name, public)
-- VALUES ('reports', 'reports', false);

-- Storage policies
-- CREATE POLICY "HOD and Admin can access reports" ON storage.objects
-- FOR ALL USING (
--     bucket_id = 'reports' AND
--     EXISTS (
--         SELECT 1 FROM users 
--         WHERE users.id = auth.uid() 
--         AND (users.role IN ('admin', 'hod') OR users.is_admin = true)
--     )
-- );

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON scheduled_reports TO authenticated;
GRANT SELECT, INSERT ON report_logs TO authenticated;
GRANT SELECT, INSERT, UPDATE ON email_queue TO authenticated;
GRANT EXECUTE ON FUNCTION increment_run_count TO authenticated;
GRANT EXECUTE ON FUNCTION get_due_reports TO authenticated;
GRANT EXECUTE ON FUNCTION update_next_run TO authenticated;
GRANT EXECUTE ON FUNCTION get_daily_attendance_trends TO authenticated;

-- ============================================================================
-- SAMPLE DATA (optional - for testing)
-- ============================================================================

-- Insert a sample scheduled report
-- INSERT INTO scheduled_reports (report_type, department, frequency, recipients, enabled)
-- VALUES (
--     'dailyAttendance',
--     'Computer Science and Engineering',
--     'daily',
--     '["hod@example.com"]'::jsonb,
--     true
-- );
