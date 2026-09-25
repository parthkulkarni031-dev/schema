DROP DATABASE IF EXISTS hospital_bed_management;
CREATE DATABASE hospital_bed_management;
USE hospital_bed_management;

-- ============================================================
-- CLEANUP
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;

DROP TRIGGER IF EXISTS trg_patient_check_dob_ins;
DROP TRIGGER IF EXISTS trg_patient_check_dob_upd;

DROP TRIGGER IF EXISTS trg_admission_check_date_ins;
DROP TRIGGER IF EXISTS trg_admission_check_date_upd;

DROP TRIGGER IF EXISTS trg_admission_check_bed_ins;
DROP TRIGGER IF EXISTS trg_admission_check_bed_upd;

DROP TRIGGER IF EXISTS trg_admission_check_overlap_ins;
DROP TRIGGER IF EXISTS trg_admission_check_overlap_upd;

DROP TRIGGER IF EXISTS trg_bed_status_occupy;
DROP TRIGGER IF EXISTS trg_bed_status_release;
DROP TRIGGER IF EXISTS trg_bed_status_transfer;

DROP TABLE IF EXISTS ADMISSION;
DROP TABLE IF EXISTS BED;
DROP TABLE IF EXISTS PATIENT;
DROP TABLE IF EXISTS DOCTOR;
DROP TABLE IF EXISTS WARD;

SET FOREIGN_KEY_CHECKS = 1;


-- ============================================================
-- 1. WARD TABLE
-- ============================================================

CREATE TABLE WARD (
    Ward_ID INT AUTO_INCREMENT PRIMARY KEY,
    Ward_Name VARCHAR(100) NOT NULL,
    Ward_Type VARCHAR(50) NOT NULL,
    Floor_No INT NOT NULL,

    CONSTRAINT uq_ward_name
        UNIQUE (Ward_Name),

    CONSTRAINT chk_ward_type
        CHECK (
            Ward_Type IN (
                'General',
                'ICU',
                'Emergency',
                'Pediatric',
                'Maternity',
                'Surgical',
                'Cardiology',
                'Orthopedic'
            )
        ),

    CONSTRAINT chk_floor
        CHECK (Floor_No BETWEEN 0 AND 20)
);


-- ============================================================
-- 2. DOCTOR TABLE
-- ============================================================

CREATE TABLE DOCTOR (
    Doctor_ID INT AUTO_INCREMENT PRIMARY KEY,
    Doctor_Name VARCHAR(100) NOT NULL,
    Specialization VARCHAR(100) NOT NULL,
    Phone VARCHAR(15) NOT NULL,
    Email VARCHAR(120) NOT NULL,
    Ward_ID INT NOT NULL,

    CONSTRAINT uq_doctor_phone
        UNIQUE (Phone),

    CONSTRAINT uq_doctor_email
        UNIQUE (Email),

    CONSTRAINT fk_doctor_ward
        FOREIGN KEY (Ward_ID)
        REFERENCES WARD(Ward_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);


-- ============================================================
-- 3. PATIENT TABLE
-- ============================================================

CREATE TABLE PATIENT (
    Patient_ID INT AUTO_INCREMENT PRIMARY KEY,
    Patient_Name VARCHAR(100) NOT NULL,
    Gender VARCHAR(10) NOT NULL,
    DOB DATE NOT NULL,
    Phone VARCHAR(15) NOT NULL,
    Address VARCHAR(200) NOT NULL,
    Blood_Group VARCHAR(5) NOT NULL,

    CONSTRAINT uq_patient_phone
        UNIQUE (Phone),

    CONSTRAINT chk_gender
        CHECK (
            Gender IN ('Male', 'Female', 'Other')
        ),

    CONSTRAINT chk_blood_group
        CHECK (
            Blood_Group IN (
                'A+',
                'A-',
                'B+',
                'B-',
                'AB+',
                'AB-',
                'O+',
                'O-'
            )
        )
);


-- ============================================================
-- 4. BED TABLE
-- ============================================================

CREATE TABLE BED (
    Bed_ID INT AUTO_INCREMENT PRIMARY KEY,
    Bed_Number VARCHAR(20) NOT NULL,
    Bed_Status VARCHAR(20) NOT NULL DEFAULT 'Available',
    Ward_ID INT NOT NULL,

    CONSTRAINT uq_bed_number_ward
        UNIQUE (Ward_ID, Bed_Number),

    CONSTRAINT chk_bed_status
        CHECK (
            Bed_Status IN (
                'Available',
                'Occupied',
                'Maintenance',
                'Reserved'
            )
        ),

    CONSTRAINT fk_bed_ward
        FOREIGN KEY (Ward_ID)
        REFERENCES WARD(Ward_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);


-- ============================================================
-- 5. ADMISSION TABLE
-- ============================================================

CREATE TABLE ADMISSION (
    Admission_ID INT AUTO_INCREMENT PRIMARY KEY,
    Admission_Date DATE NOT NULL,
    Discharge_Date DATE NULL,
    Diagnosis VARCHAR(200) NOT NULL,
    Patient_ID INT NOT NULL,
    Doctor_ID INT NOT NULL,
    Bed_ID INT NOT NULL,

    CONSTRAINT fk_admission_patient
        FOREIGN KEY (Patient_ID)
        REFERENCES PATIENT(Patient_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_admission_doctor
        FOREIGN KEY (Doctor_ID)
        REFERENCES DOCTOR(Doctor_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_admission_bed
        FOREIGN KEY (Bed_ID)
        REFERENCES BED(Bed_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT chk_admission_dates
        CHECK (
            Discharge_Date IS NULL
            OR Discharge_Date >= Admission_Date
        )
);


-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_doctor_ward
ON DOCTOR(Ward_ID);

CREATE INDEX idx_bed_ward
ON BED(Ward_ID);

CREATE INDEX idx_bed_status
ON BED(Bed_Status);

CREATE INDEX idx_admission_patient
ON ADMISSION(Patient_ID);

CREATE INDEX idx_admission_doctor
ON ADMISSION(Doctor_ID);

CREATE INDEX idx_admission_bed
ON ADMISSION(Bed_ID);

CREATE INDEX idx_admission_dates
ON ADMISSION(Admission_Date, Discharge_Date);


-- ============================================================
-- TRIGGERS
-- ============================================================


-- ============================================================
-- 1. PATIENT DOB VALIDATION - INSERT
-- ============================================================

DELIMITER $$

CREATE TRIGGER trg_patient_check_dob_ins
BEFORE INSERT ON PATIENT
FOR EACH ROW
BEGIN

    IF NEW.DOB > CURRENT_DATE THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'DOB cannot be in the future';

    END IF;

END$$

DELIMITER ;


-- ============================================================
-- 2. PATIENT DOB VALIDATION - UPDATE
-- ============================================================

DELIMITER $$

CREATE TRIGGER trg_patient_check_dob_upd
BEFORE UPDATE ON PATIENT
FOR EACH ROW
BEGIN

    IF NEW.DOB > CURRENT_DATE THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'DOB cannot be in the future';

    END IF;

END$$

DELIMITER ;


-- ============================================================
-- 3. ADMISSION DATE VALIDATION - INSERT
-- ============================================================

DELIMITER $$

CREATE TRIGGER trg_admission_check_date_ins
BEFORE INSERT ON ADMISSION
FOR EACH ROW
BEGIN

    IF NEW.Admission_Date > CURRENT_DATE THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Admission date cannot be in the future';

    END IF;

END$$

DELIMITER ;


-- ============================================================
-- 4. ADMISSION DATE VALIDATION - UPDATE
-- ============================================================

DELIMITER $$

CREATE TRIGGER trg_admission_check_date_upd
BEFORE UPDATE ON ADMISSION
FOR EACH ROW
BEGIN

    IF NEW.Admission_Date > CURRENT_DATE THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Admission date cannot be in the future';

    END IF;

END$$

DELIMITER ;


-- ============================================================
-- 5. CHECK BED - INSERT
-- ============================================================
-- Allows a bed to be used when it is Available.
-- Also permits reuse of a bed when there is no overlapping
-- active admission.

DELIMITER $$

CREATE TRIGGER trg_admission_check_bed_ins
BEFORE INSERT ON ADMISSION
FOR EACH ROW
BEGIN

    DECLARE current_status VARCHAR(20);
    DECLARE active_count INT DEFAULT 0;

    SELECT Bed_Status
    INTO current_status
    FROM BED
    WHERE Bed_ID = NEW.Bed_ID;

    IF current_status IS NULL THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Selected bed does not exist';

    END IF;

    SELECT COUNT(*)
    INTO active_count
    FROM ADMISSION
    WHERE Bed_ID = NEW.Bed_ID
      AND Admission_Date <= COALESCE(
            NEW.Discharge_Date,
            '9999-12-31'
          )
      AND COALESCE(
            Discharge_Date,
            '9999-12-31'
          ) >= NEW.Admission_Date;

    IF current_status IN ('Maintenance', 'Reserved') THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Selected bed is not available';

    END IF;

    IF active_count > 0 THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Selected bed already has an overlapping admission';

    END IF;

END$$

DELIMITER ;


-- ============================================================
-- 6. CHECK BED - UPDATE
-- ============================================================

DELIMITER $$

CREATE TRIGGER trg_admission_check_bed_upd
BEFORE UPDATE ON ADMISSION
FOR EACH ROW
BEGIN

    DECLARE current_status VARCHAR(20);
    DECLARE active_count INT DEFAULT 0;

    SELECT Bed_Status
    INTO current_status
    FROM BED
    WHERE Bed_ID = NEW.Bed_ID;

    IF current_status IS NULL THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Selected bed does not exist';

    END IF;

    IF NEW.Bed_ID <> OLD.Bed_ID THEN

        IF current_status IN ('Maintenance', 'Reserved') THEN

            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Selected bed is not available';

        END IF;

        SELECT COUNT(*)
        INTO active_count
        FROM ADMISSION
        WHERE Bed_ID = NEW.Bed_ID
          AND Admission_ID <> OLD.Admission_ID
          AND Admission_Date <= COALESCE(
                NEW.Discharge_Date,
                '9999-12-31'
              )
          AND COALESCE(
                Discharge_Date,
                '9999-12-31'
              ) >= NEW.Admission_Date;

        IF active_count > 0 THEN

            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
            'Selected bed already has an overlapping admission';

        END IF;

    END IF;

END$$

DELIMITER ;


-- ============================================================
-- 7. OVERLAPPING ADMISSIONS - INSERT
-- ============================================================

DELIMITER $$

CREATE TRIGGER trg_admission_check_overlap_ins
BEFORE INSERT ON ADMISSION
FOR EACH ROW
BEGIN

    IF EXISTS (

        SELECT 1
        FROM ADMISSION
        WHERE Bed_ID = NEW.Bed_ID

          AND Admission_Date <= COALESCE(
                NEW.Discharge_Date,
                '9999-12-31'
              )

          AND COALESCE(
                Discharge_Date,
                '9999-12-31'
              ) >= NEW.Admission_Date

    ) THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Bed conflict: this bed already has an overlapping admission';

    END IF;

END$$

DELIMITER ;


-- ============================================================
-- 8. OVERLAPPING ADMISSIONS - UPDATE
-- ============================================================

DELIMITER $$

CREATE TRIGGER trg_admission_check_overlap_upd
BEFORE UPDATE ON ADMISSION
FOR EACH ROW
BEGIN

    IF EXISTS (

        SELECT 1
        FROM ADMISSION
        WHERE Bed_ID = NEW.Bed_ID

          AND Admission_ID <> OLD.Admission_ID

          AND Admission_Date <= COALESCE(
                NEW.Discharge_Date,
                '9999-12-31'
              )

          AND COALESCE(
                Discharge_Date,
                '9999-12-31'
              ) >= NEW.Admission_Date

    ) THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Bed conflict: this bed already has an overlapping admission';

    END IF;

END$$

DELIMITER ;


-- ============================================================
-- 9. MARK BED OCCUPIED AFTER NEW ADMISSION
-- ============================================================

DELIMITER $$

CREATE TRIGGER trg_bed_status_occupy
AFTER INSERT ON ADMISSION
FOR EACH ROW
BEGIN

    IF NEW.Discharge_Date IS NULL THEN

        UPDATE BED
        SET Bed_Status = 'Occupied'
        WHERE Bed_ID = NEW.Bed_ID;

    END IF;

END$$

DELIMITER ;


-- ============================================================
-- 10. RELEASE BED AFTER DISCHARGE
-- ============================================================

DELIMITER $$

CREATE TRIGGER trg_bed_status_release
AFTER UPDATE ON ADMISSION
FOR EACH ROW
BEGIN

    IF OLD.Discharge_Date IS NULL
       AND NEW.Discharge_Date IS NOT NULL THEN

        IF NOT EXISTS (

            SELECT 1
            FROM ADMISSION
            WHERE Bed_ID = NEW.Bed_ID
              AND Discharge_Date IS NULL
              AND Admission_ID <> NEW.Admission_ID

        ) THEN

            UPDATE BED
            SET Bed_Status = 'Available'
            WHERE Bed_ID = NEW.Bed_ID
              AND Bed_Status = 'Occupied';

        END IF;

    END IF;

END$$

DELIMITER ;


-- ============================================================
-- 11. BED TRANSFER HANDLING
-- ============================================================

DELIMITER $$

CREATE TRIGGER trg_bed_status_transfer
AFTER UPDATE ON ADMISSION
FOR EACH ROW
BEGIN

    IF OLD.Bed_ID <> NEW.Bed_ID THEN

        -- Release old bed if no active admission is using it
        IF NOT EXISTS (

            SELECT 1
            FROM ADMISSION
            WHERE Bed_ID = OLD.Bed_ID
              AND Discharge_Date IS NULL
              AND Admission_ID <> NEW.Admission_ID

        ) THEN

            UPDATE BED
            SET Bed_Status = 'Available'
            WHERE Bed_ID = OLD.Bed_ID
              AND Bed_Status = 'Occupied';

        END IF;


        -- Occupy new bed ONLY if the admission is active
        IF NEW.Discharge_Date IS NULL THEN

            UPDATE BED
            SET Bed_Status = 'Occupied'
            WHERE Bed_ID = NEW.Bed_ID;

        END IF;

    END IF;

END$$

DELIMITER ;


-- ============================================================
-- VERIFICATION
-- ============================================================

SHOW TABLES;


-- ============================================================
-- DESCRIBE TABLES
-- ============================================================

DESCRIBE WARD;
DESCRIBE DOCTOR;
DESCRIBE PATIENT;
DESCRIBE BED;
DESCRIBE ADMISSION;


-- ============================================================
-- SHOW CONSTRAINTS
-- ============================================================

SHOW CREATE TABLE WARD;
SHOW CREATE TABLE DOCTOR;
SHOW CREATE TABLE PATIENT;
SHOW CREATE TABLE BED;
SHOW CREATE TABLE ADMISSION;


-- ============================================================
-- SHOW TRIGGERS
-- ============================================================

SHOW TRIGGERS;
