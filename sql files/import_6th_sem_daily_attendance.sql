-- ============================================================================
-- DAILY ATTENDANCE DATA IMPORT SCRIPT FOR 6TH SEMESTER CSE-A
-- ============================================================================
-- This script imports 15 days of daily attendance data (Dec 4-20, 2025)
-- for 6th semester CSE Section A students into the daily_attendance table
-- 
-- Run this in Supabase SQL Editor
-- ============================================================================

-- ============================================================================
-- STEP 1: Create a temporary table for the CSV data
-- ============================================================================
CREATE TEMP TABLE temp_attendance_import (
    sno INTEGER,
    reg_no VARCHAR(20),
    student_name VARCHAR(100),
    dec_04 CHAR(1),
    dec_05 CHAR(1),
    dec_06 CHAR(1),
    dec_08 CHAR(1),
    dec_09 CHAR(1),
    dec_10 CHAR(1),
    dec_11 CHAR(1),
    dec_12 CHAR(1),
    dec_13 CHAR(1),
    dec_15 CHAR(1),
    dec_16 CHAR(1),
    dec_17 CHAR(1),
    dec_18 CHAR(1),
    dec_19 CHAR(1),
    dec_20 CHAR(1),
    present_days INTEGER,
    attendance_percent INTEGER
);

-- ============================================================================
-- STEP 2: Insert the raw attendance data
-- ============================================================================
INSERT INTO temp_attendance_import VALUES
(1,'210823104001','AATHI BALA KUMAR B','P','P','P','P','P','P','P','P','P','P','P','P','P','P','P',15,100),
(2,'210823104002','ABEL C JOY','P','P','P','P','P','P','P','P','P','P','P','P','P','P','P',15,100),
(3,'210823104003','ABINAYA T','A','A','A','P','P','P','A','P','A','P','P','P','P','A','A',8,53),
(4,'210823104004','ABISHA JEBAMANI K','P','A','P','P','A','P','P','P','P','A','A','A','P','P','P',10,67),
(5,'210823104005','ABISHEK PAULSON S','A','P','A','A','P','P','A','A','A','A','A','A','A','A','A',3,20),
(6,'210823104006','ABY ROSY M','P','A','A','P','P','P','P','P','P','A','P','P','P','P','P',12,80),
(7,'210823104007','AKSHAYA PRABHA M','A','A','A','P','P','P','P','P','P','P','P','P','P','P','P',12,80),
(8,'210823104008','ANGELIN MARY S','A','A','A','A','P','P','P','P','P','P','P','P','P','P','P',11,73),
(9,'210823104009','ANISHA SWEETY J','A','P','P','P','P','P','P','P','P','P','P','P','P','P','P',14,93),
(10,'210823104010','ANNESHARON A S','A','P','A','P','P','P','P','A','A','A','P','P','P','P','A',9,60),
(11,'210823104011','ANNIE DORAH ABEL','P','P','P','P','P','P','P','P','P','P','P','P','P','P','P',15,100),
(12,'210823104012','ANTONY MELVIN T','A','A','A','P','P','P','P','P','P','P','P','P','P','P','A',11,73),
(13,'210823104013','ARPUTHA STEPHIN A','A','A','A','P','P','P','P','P','P','P','P','P','P','P','P',12,80),
(14,'210823104014','ARTHI M','P','A','A','P','P','A','A','A','A','A','P','P','P','P','P',8,53),
(15,'210823104015','ARUNACHALAM R','A','A','A','A','P','P','P','A','A','A','A','A','A','A','A',3,20),
(16,'210823104016','ASBOURN JOEL I','A','A','P','P','P','A','P','P','A','P','P','P','A','A','A',7,47),
(17,'210823104017','ASLIN BRIMA P H','A','A','P','A','P','P','P','P','P','P','P','P','P','P','P',12,80),
(18,'210823104018','ASWITHA K','A','P','P','P','P','P','P','P','A','P','P','P','P','P','P',13,87),
(19,'210823104020','BALAMURUGAN M','A','P','P','P','P','P','P','P','P','P','P','P','P','P','P',14,93),
(20,'210823104021','BLESSING RAJA P','P','A','A','P','P','P','P','A','P','P','P','P','P','P','P',12,80),
(21,'210823104022','BOAZ K','A','P','A','A','P','P','P','P','P','A','P','A','P','A','A',8,53),
(22,'210823104023','CHANDRA MOHAN C','A','A','A','A','A','P','P','P','P','P','P','P','P','P','P',10,67),
(23,'210823104024','CHRISTYBAI JENCY K','P','A','A','P','P','P','P','P','P','A','P','P','P','P','A',11,73),
(24,'210823104025','DANIYEL K L','A','A','A','P','P','P','P','P','P','A','A','A','A','A','A',6,40),
(25,'210823104026','DEEPA G C','P','P','P','P','P','P','P','P','A','P','P','P','P','P','P',14,93),
(26,'210823104027','DEEPAK S','A','A','A','P','P','P','P','P','P','P','P','P','A','P','P',11,73),
(27,'210823104028','DHANUSH A','A','P','A','P','P','P','P','A','A','A','P','P','P','P','P',10,67),
(28,'210823104029','DHARNESH S','A','A','A','P','P','A','A','P','P','P','P','A','P','A','A',7,47),
(29,'210823104030','DHARSHANA R','P','A','A','P','P','P','P','P','P','P','P','P','P','P','A',12,80),
(30,'210823104031','DHEEKSHA B','A','A','A','P','P','P','A','P','P','P','P','P','A','A','A',8,53),
(31,'210823104032','DHIVIYESH J','A','A','A','A','A','A','A','A','A','A','A','A','A','A','A',0,0),
(32,'210823104033','DON SINTO SAJI','A','A','A','P','P','P','P','P','P','P','P','P','A','P','P',11,73),
(33,'210823104034','EASWARAMURTHY P','A','A','A','P','P','A','P','A','P','P','P','P','P','A','A',9,60),
(34,'210823104035','ELANGO B','A','A','A','P','A','P','P','A','A','A','P','A','A','A','A',4,27),
(35,'210823104036','ELAVARASEN S K','P','A','A','P','P','P','P','P','A','A','P','P','P','P','P',10,67),
(36,'210823104037','ENOCH M','A','P','P','A','P','P','P','P','P','A','P','P','P','P','P',12,80),
(37,'210823104038','GAYATHRI K','A','A','A','A','P','P','A','P','A','P','P','P','P','A','A',7,47),
(38,'210823104039','GAYATHRI K','A','A','A','P','P','P','P','P','P','P','P','P','P','A','A',10,67),
(39,'210823104040','GOKULAKRISHNAN S','P','P','P','P','P','P','P','A','P','A','P','P','P','P','P',13,87),
(40,'210823104041','GOWTHAM A','A','A','A','A','P','P','P','A','A','A','A','A','A','A','A',4,27),
(41,'210823104043','HARIHARAN D','A','A','A','A','P','P','P','P','A','A','P','P','P','A','A',7,47),
(42,'210823104044','HARIPRIYA V S','P','A','A','P','P','P','P','A','A','A','P','P','A','A','A',7,47),
(43,'210823104046','HEMALATHA S','A','A','A','A','P','P','P','A','A','P','P','A','A','A','A',6,40),
(44,'210823104047','HEMAVATHI A','A','A','A','P','A','A','A','A','A','A','P','A','A','A','A',2,13),
(45,'210823104048','INDIRESH D','P','P','P','P','P','P','P','P','P','P','P','P','P','P','P',15,100),
(46,'210823104049','ISAI RAMYA G','A','P','P','P','A','P','P','P','P','P','P','P','P','P','A',12,80),
(47,'210823104051','JAFFI JOANNA F','A','A','A','A','P','P','P','P','P','P','P','P','P','P','P',11,73),
(48,'210823104052','JAKIN K','A','P','A','A','P','P','P','P','A','P','A','A','A','P','A',8,53),
(49,'210823104053','JAYACHITRA B','P','A','A','P','P','P','A','P','P','P','A','A','A','P','P',8,53),
(50,'210823104054','JEBARSON P','A','A','A','A','P','P','P','P','P','P','P','P','P','P','P',11,73),
(51,'210823104055','JEBIN JEBARAJ D','A','A','A','P','P','P','P','A','P','A','P','A','A','A','A',6,40),
(52,'210823104057','JENIFER POOMANI J','A','A','A','A','P','P','P','P','P','P','P','P','P','P','P',11,73),
(53,'210823104058','JESSICA M','P','P','P','P','P','P','P','P','P','P','P','P','P','P','P',15,100),
(54,'210823104059','JOHN WESLY S','P','P','P','P','P','P','P','P','P','P','P','A','A','A','A',12,80),
(55,'210823104060','JOSELIN SARANISHA D','A','A','A','P','P','P','P','P','A','P','P','P','P','P','P',11,73),
(56,'210823104061','KARTHIKAISELVI P','A','A','A','A','A','A','P','A','A','A','A','A','A','A','A',1,7),
(57,'210823104062','KARTHIKEYAN D','A','P','A','P','P','P','A','P','P','P','P','P','P','P','P',12,80),
(58,'210823104063','KARTHIKEYAN D','A','A','A','P','P','P','A','P','A','A','A','A','A','A','A',6,40);

-- ============================================================================
-- STEP 3: Insert daily attendance records
-- ============================================================================
-- Each day becomes a separate row in daily_attendance table

-- Dec 04, 2025
INSERT INTO daily_attendance (registration_no, date, is_present)
SELECT reg_no, '2025-12-04'::date, (dec_04 = 'P')
FROM temp_attendance_import
ON CONFLICT (registration_no, date) DO UPDATE 
SET is_present = EXCLUDED.is_present, marked_at = NOW();

-- Dec 05, 2025
INSERT INTO daily_attendance (registration_no, date, is_present)
SELECT reg_no, '2025-12-05'::date, (dec_05 = 'P')
FROM temp_attendance_import
ON CONFLICT (registration_no, date) DO UPDATE 
SET is_present = EXCLUDED.is_present, marked_at = NOW();

-- Dec 06, 2025
INSERT INTO daily_attendance (registration_no, date, is_present)
SELECT reg_no, '2025-12-06'::date, (dec_06 = 'P')
FROM temp_attendance_import
ON CONFLICT (registration_no, date) DO UPDATE 
SET is_present = EXCLUDED.is_present, marked_at = NOW();

-- Dec 08, 2025
INSERT INTO daily_attendance (registration_no, date, is_present)
SELECT reg_no, '2025-12-08'::date, (dec_08 = 'P')
FROM temp_attendance_import
ON CONFLICT (registration_no, date) DO UPDATE 
SET is_present = EXCLUDED.is_present, marked_at = NOW();

-- Dec 09, 2025
INSERT INTO daily_attendance (registration_no, date, is_present)
SELECT reg_no, '2025-12-09'::date, (dec_09 = 'P')
FROM temp_attendance_import
ON CONFLICT (registration_no, date) DO UPDATE 
SET is_present = EXCLUDED.is_present, marked_at = NOW();

-- Dec 10, 2025
INSERT INTO daily_attendance (registration_no, date, is_present)
SELECT reg_no, '2025-12-10'::date, (dec_10 = 'P')
FROM temp_attendance_import
ON CONFLICT (registration_no, date) DO UPDATE 
SET is_present = EXCLUDED.is_present, marked_at = NOW();

-- Dec 11, 2025
INSERT INTO daily_attendance (registration_no, date, is_present)
SELECT reg_no, '2025-12-11'::date, (dec_11 = 'P')
FROM temp_attendance_import
ON CONFLICT (registration_no, date) DO UPDATE 
SET is_present = EXCLUDED.is_present, marked_at = NOW();

-- Dec 12, 2025
INSERT INTO daily_attendance (registration_no, date, is_present)
SELECT reg_no, '2025-12-12'::date, (dec_12 = 'P')
FROM temp_attendance_import
ON CONFLICT (registration_no, date) DO UPDATE 
SET is_present = EXCLUDED.is_present, marked_at = NOW();

-- Dec 13, 2025
INSERT INTO daily_attendance (registration_no, date, is_present)
SELECT reg_no, '2025-12-13'::date, (dec_13 = 'P')
FROM temp_attendance_import
ON CONFLICT (registration_no, date) DO UPDATE 
SET is_present = EXCLUDED.is_present, marked_at = NOW();

-- Dec 15, 2025
INSERT INTO daily_attendance (registration_no, date, is_present)
SELECT reg_no, '2025-12-15'::date, (dec_15 = 'P')
FROM temp_attendance_import
ON CONFLICT (registration_no, date) DO UPDATE 
SET is_present = EXCLUDED.is_present, marked_at = NOW();

-- Dec 16, 2025
INSERT INTO daily_attendance (registration_no, date, is_present)
SELECT reg_no, '2025-12-16'::date, (dec_16 = 'P')
FROM temp_attendance_import
ON CONFLICT (registration_no, date) DO UPDATE 
SET is_present = EXCLUDED.is_present, marked_at = NOW();

-- Dec 17, 2025
INSERT INTO daily_attendance (registration_no, date, is_present)
SELECT reg_no, '2025-12-17'::date, (dec_17 = 'P')
FROM temp_attendance_import
ON CONFLICT (registration_no, date) DO UPDATE 
SET is_present = EXCLUDED.is_present, marked_at = NOW();

-- Dec 18, 2025
INSERT INTO daily_attendance (registration_no, date, is_present)
SELECT reg_no, '2025-12-18'::date, (dec_18 = 'P')
FROM temp_attendance_import
ON CONFLICT (registration_no, date) DO UPDATE 
SET is_present = EXCLUDED.is_present, marked_at = NOW();

-- Dec 19, 2025
INSERT INTO daily_attendance (registration_no, date, is_present)
SELECT reg_no, '2025-12-19'::date, (dec_19 = 'P')
FROM temp_attendance_import
ON CONFLICT (registration_no, date) DO UPDATE 
SET is_present = EXCLUDED.is_present, marked_at = NOW();

-- Dec 20, 2025
INSERT INTO daily_attendance (registration_no, date, is_present)
SELECT reg_no, '2025-12-20'::date, (dec_20 = 'P')
FROM temp_attendance_import
ON CONFLICT (registration_no, date) DO UPDATE 
SET is_present = EXCLUDED.is_present, marked_at = NOW();

-- ============================================================================
-- STEP 4: Verify the import
-- ============================================================================
SELECT 'Total daily attendance records inserted:' as info, COUNT(*) as count
FROM daily_attendance 
WHERE date BETWEEN '2025-12-04' AND '2025-12-20';

-- Check a sample student's attendance
SELECT registration_no, date, is_present 
FROM daily_attendance 
WHERE registration_no = '210823104001' 
  AND date BETWEEN '2025-12-04' AND '2025-12-20'
ORDER BY date;

-- Summary by student
SELECT 
    registration_no,
    COUNT(*) as total_days,
    SUM(CASE WHEN is_present THEN 1 ELSE 0 END) as present_days,
    ROUND(100.0 * SUM(CASE WHEN is_present THEN 1 ELSE 0 END) / COUNT(*), 0) as percentage
FROM daily_attendance 
WHERE date BETWEEN '2025-12-04' AND '2025-12-20'
GROUP BY registration_no
ORDER BY registration_no
LIMIT 10;

-- ============================================================================
-- STEP 5: Cleanup temp table
-- ============================================================================
DROP TABLE IF EXISTS temp_attendance_import;

-- ============================================================================
-- DONE! The daily attendance data should now be visible in the app
-- ============================================================================
