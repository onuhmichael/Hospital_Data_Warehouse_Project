
/*
===============================================================================
DDL Script: Recreate Silver Tables
===============================================================================
Script Purpose:
    Drops and recreates all tables in the 'silver' schema to redefine structure.
===============================================================================
*/

-- Drop and recreate Silver schema tables

-- DimPatient
DROP TABLE IF EXISTS silver.Dim_DimPatient;
CREATE TABLE silver.Dim_DimPatient (
    PatientID INT PRIMARY KEY,
    NHS_ID NVARCHAR(50),
    PatientFirstName NVARCHAR(100),
    PatientLastName NVARCHAR(100),
    PatientDOB DATE,
    PatientPostcode NVARCHAR(20)
);

-- DimClinic
DROP TABLE IF EXISTS silver.Dim_DimClinic;
CREATE TABLE silver.Dim_DimClinic (
    ClinicName NVARCHAR(100) PRIMARY KEY,
    Specialty NVARCHAR(100)
);

-- DimProvider
DROP TABLE IF EXISTS silver.Dim_DimProvider;
CREATE TABLE silver.Dim_DimProvider (
    ProviderID NVARCHAR(50) PRIMARY KEY,
    ProviderName NVARCHAR(100)
);

-- DimDiagnosis
DROP TABLE IF EXISTS silver.Dim_DimDiagnosis;
CREATE TABLE silver.Dim_DimDiagnosis (
    DiagnosisCode NVARCHAR(50) PRIMARY KEY,
    DiagnosisDescription NVARCHAR(255)
);

-- DimAppointmentStatus
DROP TABLE IF EXISTS silver.Dim_DimAppointmentStatus;
CREATE TABLE silver.Dim_DimAppointmentStatus (
    AppointmentStatus NVARCHAR(50) PRIMARY KEY
);

-- DimDepartment
DROP TABLE IF EXISTS silver.Dim_Department;
CREATE TABLE silver.Dim_Department (
    DepartmentName NVARCHAR(100) PRIMARY KEY
);

-- DimReferralSource
DROP TABLE IF EXISTS silver.Dim_ReferralSource;
CREATE TABLE silver.Dim_ReferralSource (
    ReferralSource NVARCHAR(100) PRIMARY KEY
);

-- DimOutcome
DROP TABLE IF EXISTS silver.Dim_Outcome;
CREATE TABLE silver.Dim_Outcome (
    Outcome NVARCHAR(50) PRIMARY KEY
);

-- FactAppointment
DROP TABLE IF EXISTS silver.Fact_Appointment;
CREATE TABLE silver.Fact_Appointment (
    AppointmentID INT PRIMARY KEY,
    AppointmentDate DATE,
    PatientID INT,
    DepartmentName NVARCHAR(100),
    ProviderID NVARCHAR(50),
    Outcome NVARCHAR(50),
    ReferralSource NVARCHAR(100),
    NoShowFlag BIT,
    FOREIGN KEY (PatientID) REFERENCES silver.Dim_DimPatient(PatientID),
    FOREIGN KEY (DepartmentName) REFERENCES silver.Dim_Department(DepartmentName),
    FOREIGN KEY (ProviderID) REFERENCES silver.Dim_DimProvider(ProviderID),
    FOREIGN KEY (Outcome) REFERENCES silver.Dim_Outcome(Outcome),
    FOREIGN KEY (ReferralSource) REFERENCES silver.Dim_ReferralSource(ReferralSource)
);
