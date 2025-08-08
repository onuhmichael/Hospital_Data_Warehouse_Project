/*
===============================================================================
DDL Script:         Create bronze Staging Table for Outpatient Data
===============================================================================
Script Purpose:
    This script creates the 'stg_OutpatientData' table within the 'bronze' 
    schema. The purpose of this table is to hold the raw, unaltered data 
    ingested from the outpatient ERP system's CSV files.

    The script is idempotent: it first checks for the schema and table, 
    dropping the table if it already exists, to ensure a clean deployment.

    Run this script to define or redefine the DDL structure of the bronze
    staging table.
===============================================================================
*/

-- Check if the bronze schema exists, and create it if it doesn't
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'bronze')
BEGIN
    EXEC('CREATE SCHEMA bronze');
END
GO

-- Drop the table if it already exists to allow for recreation
IF OBJECT_ID('bronze.stg_OutpatientData', 'U') IS NOT NULL
BEGIN
    DROP TABLE bronze.stg_OutpatientData;
END
GO

-- Create the staging table for raw outpatient data
CREATE TABLE bronze.stg_OutpatientData
(
    -- Data columns from the source CSV file
    AppointmentID NVARCHAR(255),
    AppointmentDateTime NVARCHAR(255),
    PatientID NVARCHAR(255),
    NHS_ID NVARCHAR(255),
    PatientFirstName NVARCHAR(255),
    PatientLastName NVARCHAR(255),
    PatientDOB NVARCHAR(255),
    PatientPostcode NVARCHAR(255),
    ClinicName NVARCHAR(255),
    Specialty NVARCHAR(255),
    ProviderID NVARCHAR(255),
    ProviderName NVARCHAR(255),
    DiagnosisCode NVARCHAR(255),
    DiagnosisDescription NVARCHAR(MAX),
    AppointmentStatus NVARCHAR(255)

  
);
GO

PRINT 'SUCCESS: The bronze.stg_OutpatientData table has been created successfully.';
GO
