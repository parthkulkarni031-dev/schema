USE hospital_bed_management;


/* =========================================================
SECTION A
BASIC VERIFICATION
========================================================= */

SELECT COUNT(*) AS Total_Wards
FROM WARD;

SELECT COUNT(*) AS Total_Doctors
FROM DOCTOR;

SELECT COUNT(*) AS Total_Patients
FROM PATIENT;

SELECT COUNT(*) AS Total_Beds
FROM BED;

SELECT COUNT(*) AS Total_Admissions
FROM ADMISSION;


/* =========================================================
SECTION B
COMPLEX INNER JOIN
========================================================= */

/*
Display admission information along with:
Patient, Doctor, Bed and Ward.
*/

SELECT
    a.Admission_ID,
    p.Patient_Name,
    d.Doctor_Name,
    d.Specialization,
    b.Bed_Number,
    b.Bed_Status,
    w.Ward_Name,
    w.Ward_Type,
    a.Admission_Date,
    a.Discharge_Date,
    a.Diagnosis

FROM ADMISSION a

INNER JOIN PATIENT p
    ON a.Patient_ID = p.Patient_ID

INNER JOIN DOCTOR d
    ON a.Doctor_ID = d.Doctor_ID

INNER JOIN BED b
    ON a.Bed_ID = b.Bed_ID

INNER JOIN WARD w
    ON b.Ward_ID = w.Ward_ID

ORDER BY a.Admission_ID

LIMIT 30;


/* =========================================================
SECTION C
LEFT OUTER JOIN
========================================================= */

/*
Display all wards and their doctors.
*/

SELECT
    w.Ward_ID,
    w.Ward_Name,
    w.Ward_Type,
    d.Doctor_ID,
    d.Doctor_Name,
    d.Specialization

FROM WARD w

LEFT JOIN DOCTOR d
    ON w.Ward_ID = d.Ward_ID

ORDER BY w.Ward_ID;


/* =========================================================
SECTION D
RIGHT OUTER JOIN
========================================================= */

SELECT
    d.Doctor_ID,
    d.Doctor_Name,
    d.Specialization,
    w.Ward_Name,
    w.Ward_Type

FROM DOCTOR d

RIGHT JOIN WARD w
    ON d.Ward_ID = w.Ward_ID

ORDER BY w.Ward_ID;


/* =========================================================
SECTION E
SELF JOIN
========================================================= */

/*
Find doctors working in the same ward.

NOTE:
The current data.sql inserts one doctor per ward,
so this query may return zero rows.
The SQL itself is correct.
*/

SELECT
    d1.Doctor_Name AS Doctor_1,
    d2.Doctor_Name AS Doctor_2,
    w.Ward_Name

FROM DOCTOR d1

INNER JOIN DOCTOR d2
    ON d1.Ward_ID = d2.Ward_ID
    AND d1.Doctor_ID < d2.Doctor_ID

INNER JOIN WARD w
    ON d1.Ward_ID = w.Ward_ID

ORDER BY w.Ward_Name

LIMIT 30;


/* =========================================================
SECTION F
AGGREGATE + GROUP BY
========================================================= */

/*
Count doctors in every ward.
*/

SELECT
    w.Ward_ID,
    w.Ward_Name,
    COUNT(d.Doctor_ID) AS Number_Of_Doctors

FROM WARD w

LEFT JOIN DOCTOR d
    ON w.Ward_ID = d.Ward_ID

GROUP BY
    w.Ward_ID,
    w.Ward_Name

ORDER BY Number_Of_Doctors DESC;


/* =========================================================
SECTION G
GROUP BY + HAVING
========================================================= */

/*
Find wards having more than one doctor.

With the current data, this will return zero rows
because there is one doctor per ward.
*/

SELECT
    w.Ward_Name,
    COUNT(d.Doctor_ID) AS Doctor_Count

FROM WARD w

JOIN DOCTOR d
    ON w.Ward_ID = d.Ward_ID

GROUP BY
    w.Ward_ID,
    w.Ward_Name

HAVING COUNT(d.Doctor_ID) > 1

ORDER BY Doctor_Count DESC;


/* =========================================================
SECTION H
ADMISSION COUNT BY WARD
========================================================= */

SELECT
    w.Ward_Name,
    w.Ward_Type,
    COUNT(a.Admission_ID) AS Total_Admissions

FROM WARD w

LEFT JOIN BED b
    ON w.Ward_ID = b.Ward_ID

LEFT JOIN ADMISSION a
    ON b.Bed_ID = a.Bed_ID

GROUP BY
    w.Ward_ID,
    w.Ward_Name,
    w.Ward_Type

ORDER BY Total_Admissions DESC;


/* =========================================================
SECTION I
CORRELATED SUBQUERY
========================================================= */

/*
Find patients whose number of admissions
is greater than the average admission count
among all patients.
*/

SELECT
    p.Patient_ID,
    p.Patient_Name

FROM PATIENT p

WHERE
(
    SELECT COUNT(*)
    FROM ADMISSION a
    WHERE a.Patient_ID = p.Patient_ID
)
>
(
    SELECT AVG(admission_count)

    FROM
    (
        SELECT
            p2.Patient_ID,
            COUNT(a2.Admission_ID) AS admission_count

        FROM PATIENT p2

        LEFT JOIN ADMISSION a2
            ON p2.Patient_ID = a2.Patient_ID

        GROUP BY p2.Patient_ID

    ) AS x
)

ORDER BY p.Patient_ID;


/* =========================================================
SECTION J
SUBQUERY
========================================================= */

/*
Find doctors who have handled at least one admission.
*/

SELECT
    Doctor_ID,
    Doctor_Name,
    Specialization

FROM DOCTOR

WHERE Doctor_ID IN
(
    SELECT DISTINCT Doctor_ID
    FROM ADMISSION
)

ORDER BY Doctor_ID;


/* =========================================================
SECTION K
NESTED AGGREGATE QUERY
========================================================= */

/*
Find wards whose admission count is greater
than the average admission count per ward.
*/

SELECT
    w.Ward_Name,
    COUNT(a.Admission_ID) AS Admission_Count

FROM WARD w

JOIN BED b
    ON w.Ward_ID = b.Ward_ID

JOIN ADMISSION a
    ON b.Bed_ID = a.Bed_ID

GROUP BY
    w.Ward_ID,
    w.Ward_Name

HAVING COUNT(a.Admission_ID)
>
(
    SELECT AVG(cnt)

    FROM
    (
        SELECT
            b2.Ward_ID,
            COUNT(a2.Admission_ID) AS cnt

        FROM BED b2

        LEFT JOIN ADMISSION a2
            ON b2.Bed_ID = a2.Bed_ID

        GROUP BY b2.Ward_ID

    ) AS ward_counts
)

ORDER BY Admission_Count DESC;


/* =========================================================
SECTION L
AVAILABLE BEDS
========================================================= */

SELECT
    b.Bed_ID,
    b.Bed_Number,
    w.Ward_Name,
    w.Ward_Type,
    b.Bed_Status

FROM BED b

JOIN WARD w
    ON b.Ward_ID = w.Ward_ID

WHERE b.Bed_Status = 'Available'

ORDER BY
    w.Ward_ID,
    b.Bed_Number;


/* =========================================================
SECTION M
OCCUPIED / RESERVED / MAINTENANCE BED SUMMARY
========================================================= */

SELECT
    Bed_Status,
    COUNT(*) AS Total_Beds

FROM BED

GROUP BY Bed_Status

ORDER BY Total_Beds DESC;


/* =========================================================
SECTION N
VIEW 1
ADMISSION REPORT
========================================================= */

CREATE OR REPLACE VIEW vw_admission_report AS

SELECT
    a.Admission_ID,
    p.Patient_ID,
    p.Patient_Name,
    p.Gender,
    d.Doctor_ID,
    d.Doctor_Name,
    d.Specialization,
    b.Bed_ID,
    b.Bed_Number,
    w.Ward_ID,
    w.Ward_Name,
    w.Ward_Type,
    a.Admission_Date,
    a.Discharge_Date,
    a.Diagnosis

FROM ADMISSION a

JOIN PATIENT p
    ON a.Patient_ID = p.Patient_ID

JOIN DOCTOR d
    ON a.Doctor_ID = d.Doctor_ID

JOIN BED b
    ON a.Bed_ID = b.Bed_ID

JOIN WARD w
    ON b.Ward_ID = w.Ward_ID;


/* Test View 1 */

SELECT *
FROM vw_admission_report
LIMIT 20;


/* =========================================================
SECTION O
VIEW 2
WARD BED SUMMARY
========================================================= */

CREATE OR REPLACE VIEW vw_ward_bed_summary AS

SELECT
    w.Ward_ID,
    w.Ward_Name,
    w.Ward_Type,

    COUNT(b.Bed_ID) AS Total_Beds,

    SUM(
        CASE
            WHEN b.Bed_Status = 'Available'
            THEN 1
            ELSE 0
        END
    ) AS Available_Beds,

    SUM(
        CASE
            WHEN b.Bed_Status = 'Occupied'
            THEN 1
            ELSE 0
        END
    ) AS Occupied_Beds,

    SUM(
        CASE
            WHEN b.Bed_Status = 'Maintenance'
            THEN 1
            ELSE 0
        END
    ) AS Maintenance_Beds,

    SUM(
        CASE
            WHEN b.Bed_Status = 'Reserved'
            THEN 1
            ELSE 0
        END
    ) AS Reserved_Beds

FROM WARD w

LEFT JOIN BED b
    ON w.Ward_ID = b.Ward_ID

GROUP BY
    w.Ward_ID,
    w.Ward_Name,
    w.Ward_Type;


/* Test View 2 */

SELECT *
FROM vw_ward_bed_summary
ORDER BY Total_Beds DESC;


/* =========================================================
SECTION P
STORED PROCEDURE
========================================================= */

/*
Procedure:
Admit a patient to an available bed.

Parameters:
p_patient_id
p_doctor_id
p_bed_id
p_diagnosis

The Admission_ID is generated automatically by
AUTO_INCREMENT.
*/

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_admit_patient $$

CREATE PROCEDURE sp_admit_patient
(
    IN p_patient_id INT,
    IN p_doctor_id INT,
    IN p_bed_id INT,
    IN p_diagnosis VARCHAR(200)
)

BEGIN

    DECLARE v_bed_status VARCHAR(20);
    DECLARE v_new_admission_id INT;

    START TRANSACTION;


    /* Check bed and lock its row */

    SELECT Bed_Status
    INTO v_bed_status

    FROM BED

    WHERE Bed_ID = p_bed_id

    FOR UPDATE;


    /* Check whether bed exists */

    IF v_bed_status IS NULL THEN

        ROLLBACK;

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Bed does not exist';


    /* Check whether bed is available */

    ELSEIF v_bed_status <> 'Available' THEN

        ROLLBACK;

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Bed is not available';


    ELSE

        /* Insert admission */

        INSERT INTO ADMISSION
        (
            Admission_Date,
            Discharge_Date,
            Diagnosis,
            Patient_ID,
            Doctor_ID,
            Bed_ID
        )

        VALUES
        (
            CURDATE(),
            NULL,
            p_diagnosis,
            p_patient_id,
            p_doctor_id,
            p_bed_id
        );


        /* Get automatically generated ID */

        SET v_new_admission_id = LAST_INSERT_ID();


        /*
        The schema trigger automatically changes
        the bed status to Occupied.
        */


        COMMIT;


        SELECT
            v_new_admission_id AS New_Admission_ID,
            'Patient admitted successfully' AS Message;

    END IF;

END $$

DELIMITER ;


/* =========================================================
TEST STORED PROCEDURE
========================================================= */

/*
Find an available bed first.
*/

SELECT *
FROM BED
WHERE Bed_Status = 'Available'
LIMIT 5;


/*
Example procedure call.

Bed 1 is used here because the historical
admission associated with it has already ended,
so it can be reused.
*/

CALL sp_admit_patient
(
    1,
    1,
    1,
    'Routine medical observation'
);


/* Verify new admission */

SELECT *
FROM ADMISSION
ORDER BY Admission_ID DESC
LIMIT 5;


/* Verify bed */

SELECT *
FROM BED
WHERE Bed_ID = 1;


/* =========================================================
SECTION Q
TRIGGER VERIFICATION
========================================================= */

/*
The required triggers are already created in schema.sql.

Display all triggers.
*/

SHOW TRIGGERS;


/*
Check current active admissions.
*/

SELECT
    Admission_ID,
    Patient_ID,
    Doctor_ID,
    Bed_ID,
    Admission_Date,
    Discharge_Date,
    Diagnosis

FROM ADMISSION

WHERE Discharge_Date IS NULL

ORDER BY Admission_ID;


/*
Check occupied beds.
*/

SELECT
    Bed_ID,
    Bed_Number,
    Bed_Status,
    Ward_ID

FROM BED

WHERE Bed_Status = 'Occupied'

ORDER BY Bed_ID;


/* =========================================================
TEST DISCHARGE TRIGGER
========================================================= */

/*
The stored procedure creates an active admission.
The following updates it to discharge the patient.

Use the most recent admission generated by
the stored procedure.
*/

SELECT
    Admission_ID,
    Patient_ID,
    Bed_ID,
    Admission_Date,
    Discharge_Date

FROM ADMISSION

WHERE Discharge_Date IS NULL

ORDER BY Admission_ID DESC
LIMIT 5;


/*
Example:

UPDATE ADMISSION
SET Discharge_Date = CURDATE()
WHERE Admission_ID = 201;

The schema trigger will automatically release
the bed.
*/


/* =========================================================
SECTION R
INDEXING
========================================================= */

/*
The following indexes are ALREADY created in schema.sql:

idx_admission_patient
idx_admission_doctor
idx_admission_bed
idx_admission_dates
idx_bed_ward
idx_bed_status
idx_doctor_ward

Therefore, they are NOT recreated here.
This prevents duplicate-index errors.
*/


/* Additional performance indexes */

CREATE INDEX IF NOT EXISTS idx_admission_date
ON ADMISSION(Admission_Date);

CREATE INDEX IF NOT EXISTS idx_admission_doctor_date
ON ADMISSION(Doctor_ID, Admission_Date);

CREATE INDEX IF NOT EXISTS idx_bed_status_ward
ON BED(Bed_Status, Ward_ID);


/* Verify indexes */

SHOW INDEX FROM ADMISSION;

SHOW INDEX FROM BED;


/* =========================================================
SECTION S
EXPLAIN BEFORE / AFTER INDEX
========================================================= */

/*
Query 1
Find admissions handled by Doctor 10
after a particular date.
*/

EXPLAIN

SELECT
    a.Admission_ID,
    a.Patient_ID,
    a.Doctor_ID,
    a.Admission_Date

FROM ADMISSION a

WHERE a.Doctor_ID = 10
AND a.Admission_Date >= '2024-06-01';


/*
Query 2
Find available beds in Ward 10.
*/

EXPLAIN

SELECT
    b.Bed_ID,
    b.Bed_Number,
    b.Ward_ID

FROM BED b

WHERE b.Bed_Status = 'Available'
AND b.Ward_ID = 10;


/*
MySQL 8.0 detailed execution plan.

Run this only if your MySQL version
supports EXPLAIN ANALYZE.
*/

EXPLAIN ANALYZE

SELECT
    a.Admission_ID,
    a.Patient_ID,
    a.Doctor_ID,
    a.Admission_Date

FROM ADMISSION a

WHERE a.Doctor_ID = 10
AND a.Admission_Date >= '2024-06-01';


/* =========================================================
SECTION T
PERFORMANCE QUERY
========================================================= */

EXPLAIN ANALYZE

SELECT
    d.Doctor_Name,
    COUNT(a.Admission_ID) AS Total_Admissions

FROM DOCTOR d

LEFT JOIN ADMISSION a
    ON d.Doctor_ID = a.Doctor_ID

WHERE d.Doctor_ID = 10

GROUP BY
    d.Doctor_ID,
    d.Doctor_Name;


/* =========================================================
SECTION U
TRANSACTION / ACID DEMONSTRATION
========================================================= */

START TRANSACTION;


/*
Reserve an available bed.
*/

UPDATE BED

SET Bed_Status = 'Reserved'

WHERE Bed_ID = 10
AND Bed_Status = 'Available';


/*
Verify before COMMIT.
*/

SELECT *
FROM BED
WHERE Bed_ID = 10;


/*
Commit the transaction.
*/

COMMIT;


/*
Verify after COMMIT.
*/

SELECT *
FROM BED
WHERE Bed_ID = 10;


/* =========================================================
SECTION V
FINAL REPORT
========================================================= */

SELECT
    w.Ward_Name,
    w.Ward_Type,

    COUNT(DISTINCT b.Bed_ID) AS Total_Beds,

    COUNT(DISTINCT a.Admission_ID) AS Total_Admissions,

    COUNT(DISTINCT d.Doctor_ID) AS Doctors

FROM WARD w

LEFT JOIN BED b
    ON w.Ward_ID = b.Ward_ID

LEFT JOIN ADMISSION a
    ON b.Bed_ID = a.Bed_ID

LEFT JOIN DOCTOR d
    ON w.Ward_ID = d.Ward_ID

GROUP BY
    w.Ward_ID,
    w.Ward_Name,
    w.Ward_Type

ORDER BY Total_Admissions DESC;
