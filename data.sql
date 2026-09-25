USE hospital_bed_management;


/* =========================================================
1. INSERT 120 WARDS
========================================================= */

INSERT INTO WARD
(Ward_ID, Ward_Name, Ward_Type, Floor_No)

WITH RECURSIVE seq AS
(
    SELECT 1 AS n

    UNION ALL

    SELECT n + 1
    FROM seq
    WHERE n < 120
)

SELECT
    n,
    CONCAT('Ward ', n),

    CASE MOD(n,8)
        WHEN 0 THEN 'General'
        WHEN 1 THEN 'ICU'
        WHEN 2 THEN 'Emergency'
        WHEN 3 THEN 'Pediatric'
        WHEN 4 THEN 'Maternity'
        WHEN 5 THEN 'Surgical'
        WHEN 6 THEN 'Cardiology'
        ELSE 'Orthopedic'
    END,

    MOD(n,10) + 1

FROM seq;


/* =========================================================
2. INSERT 120 DOCTORS
========================================================= */

INSERT INTO DOCTOR
(
    Doctor_ID,
    Doctor_Name,
    Specialization,
    Phone,
    Email,
    Ward_ID
)

WITH RECURSIVE seq AS
(
    SELECT 1 AS n

    UNION ALL

    SELECT n + 1
    FROM seq
    WHERE n < 120
)

SELECT
    n,

    CONCAT(
        CASE MOD(n,10)
            WHEN 0 THEN 'Amit'
            WHEN 1 THEN 'Rahul'
            WHEN 2 THEN 'Priya'
            WHEN 3 THEN 'Neha'
            WHEN 4 THEN 'Rohit'
            WHEN 5 THEN 'Sneha'
            WHEN 6 THEN 'Vikas'
            WHEN 7 THEN 'Anjali'
            WHEN 8 THEN 'Karan'
            ELSE 'Pooja'
        END,
        ' Doctor'
    ),

    CASE MOD(n,8)
        WHEN 0 THEN 'General Medicine'
        WHEN 1 THEN 'Cardiology'
        WHEN 2 THEN 'Neurology'
        WHEN 3 THEN 'Orthopedics'
        WHEN 4 THEN 'Pediatrics'
        WHEN 5 THEN 'Surgery'
        WHEN 6 THEN 'Dermatology'
        ELSE 'Emergency Medicine'
    END,

    CONCAT('90000', LPAD(n,5,'0')),

    CONCAT('doctor',n,'@hbms.com'),

    n

FROM seq;


/* =========================================================
3. INSERT 150 PATIENTS
========================================================= */

INSERT INTO PATIENT
(
    Patient_ID,
    Patient_Name,
    Gender,
    DOB,
    Phone,
    Address,
    Blood_Group
)

WITH RECURSIVE seq AS
(
    SELECT 1 AS n

    UNION ALL

    SELECT n + 1
    FROM seq
    WHERE n < 150
)

SELECT
    n,

    CONCAT(
        CASE MOD(n,12)
            WHEN 0 THEN 'Aarav'
            WHEN 1 THEN 'Vivaan'
            WHEN 2 THEN 'Aditya'
            WHEN 3 THEN 'Arjun'
            WHEN 4 THEN 'Ishita'
            WHEN 5 THEN 'Ananya'
            WHEN 6 THEN 'Riya'
            WHEN 7 THEN 'Kavya'
            WHEN 8 THEN 'Rahul'
            WHEN 9 THEN 'Sneha'
            WHEN 10 THEN 'Rohan'
            ELSE 'Meera'
        END,
        ' Patient ',
        n
    ),

    CASE
        WHEN MOD(n,3) = 0 THEN 'Female'
        WHEN MOD(n,3) = 1 THEN 'Male'
        ELSE 'Other'
    END,

    DATE_ADD(
        '1970-01-01',
        INTERVAL MOD(n,12000) DAY
    ),

    CONCAT(
        '80000',
        LPAD(n,5,'0')
    ),

    CONCAT(
        'House ',
        n,
        ', Pune, Maharashtra'
    ),

    CASE MOD(n,8)
        WHEN 0 THEN 'A+'
        WHEN 1 THEN 'A-'
        WHEN 2 THEN 'B+'
        WHEN 3 THEN 'B-'
        WHEN 4 THEN 'AB+'
        WHEN 5 THEN 'AB-'
        WHEN 6 THEN 'O+'
        ELSE 'O-'
    END

FROM seq;


/* =========================================================
4. INSERT 240 BEDS
========================================================= */

INSERT INTO BED
(
    Bed_ID,
    Bed_Number,
    Bed_Status,
    Ward_ID
)

WITH RECURSIVE seq AS
(
    SELECT 1 AS n

    UNION ALL

    SELECT n + 1
    FROM seq
    WHERE n < 240
)

SELECT
    n,

    CONCAT(
        'B',
        LPAD(MOD(n-1,20)+1,3,'0')
    ),

    CASE
        WHEN MOD(n,20) = 0 THEN 'Maintenance'
        WHEN MOD(n,15) = 0 THEN 'Reserved'
        ELSE 'Available'
    END,

    CEIL(n/2)

FROM seq;


/* =========================================================
5. INSERT 200 HISTORICAL ADMISSIONS
========================================================= */

/*
   IMPORTANT:
   Only Available beds are selected.

   This prevents admissions from being assigned to:
   - Maintenance beds
   - Reserved beds

   Each admission receives a different available bed,
   so there is no bed-overlap problem.
*/

INSERT INTO ADMISSION
(
    Admission_ID,
    Admission_Date,
    Discharge_Date,
    Diagnosis,
    Patient_ID,
    Doctor_ID,
    Bed_ID
)

WITH RECURSIVE seq AS
(
    SELECT 1 AS n

    UNION ALL

    SELECT n + 1
    FROM seq
    WHERE n < 200
),

available_beds AS
(
    SELECT
        Bed_ID,
        ROW_NUMBER() OVER (
            ORDER BY Bed_ID
        ) AS rn
    FROM BED
    WHERE Bed_Status = 'Available'
)

SELECT
    s.n,

    DATE_ADD(
        '2024-01-01',
        INTERVAL MOD(s.n * 17, 700) DAY
    ),

    DATE_ADD(
        DATE_ADD(
            '2024-01-01',
            INTERVAL MOD(s.n * 17, 700) DAY
        ),
        INTERVAL MOD(s.n,10) + 1 DAY
    ),

    CASE MOD(s.n,10)
        WHEN 0 THEN 'Fever'
        WHEN 1 THEN 'Cardiac condition'
        WHEN 2 THEN 'Fracture'
        WHEN 3 THEN 'Respiratory infection'
        WHEN 4 THEN 'Diabetes'
        WHEN 5 THEN 'Hypertension'
        WHEN 6 THEN 'Pneumonia'
        WHEN 7 THEN 'Appendicitis'
        WHEN 8 THEN 'Migraine'
        ELSE 'Post-operative care'
    END,

    MOD(s.n-1,150) + 1,

    MOD(s.n-1,120) + 1,

    ab.Bed_ID

FROM seq s

JOIN available_beds ab
    ON ab.rn = s.n;


/* =========================================================
DATA VERIFICATION
========================================================= */

SELECT
    'WARD' AS Table_Name,
    COUNT(*) AS Total_Rows
FROM WARD

UNION ALL

SELECT
    'DOCTOR',
    COUNT(*)
FROM DOCTOR

UNION ALL

SELECT
    'PATIENT',
    COUNT(*)
FROM PATIENT

UNION ALL

SELECT
    'BED',
    COUNT(*)
FROM BED

UNION ALL

SELECT
    'ADMISSION',
    COUNT(*)
FROM ADMISSION;


/* =========================================================
SAMPLE RECORDS
========================================================= */

SELECT *
FROM WARD
LIMIT 10;

SELECT *
FROM DOCTOR
LIMIT 10;

SELECT *
FROM PATIENT
LIMIT 10;

SELECT *
FROM BED
LIMIT 10;

SELECT *
FROM ADMISSION
LIMIT 10;


/* =========================================================
ADDITIONAL VALIDATION
========================================================= */

/* Check that all 200 admissions exist */

SELECT COUNT(*) AS Total_Admissions
FROM ADMISSION;


/* Check for overlapping admissions on the same bed */

SELECT
    a1.Admission_ID AS Admission_1,
    a2.Admission_ID AS Admission_2,
    a1.Bed_ID
FROM ADMISSION a1
JOIN ADMISSION a2
    ON a1.Bed_ID = a2.Bed_ID
    AND a1.Admission_ID < a2.Admission_ID
    AND a1.Admission_Date <= COALESCE(
        a2.Discharge_Date,
        '9999-12-31'
    )
    AND COALESCE(
        a1.Discharge_Date,
        '9999-12-31'
    ) >= a2.Admission_Date;


/* Check beds used by admissions */

SELECT
    b.Bed_ID,
    b.Bed_Number,
    b.Bed_Status,
    COUNT(a.Admission_ID) AS Admission_Count
FROM BED b
LEFT JOIN ADMISSION a
    ON b.Bed_ID = a.Bed_ID
GROUP BY
    b.Bed_ID,
    b.Bed_Number,
    b.Bed_Status
ORDER BY b.Bed_ID
LIMIT 20;
