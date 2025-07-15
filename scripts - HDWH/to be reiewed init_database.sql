/*
=========================================================================================
Master Script:      Create and Configure Hospital Data Warehouse (v1.0)
=========================================================================================
Script Purpose:
    This master script orchestrates the complete setup of the 'DataWarehouse' project.
    It creates the database, defines all necessary schemas, creates the Bronze layer
    tables, and deploys the stored procedure for data ingestion.

    This script is idempotent, meaning it can be run multiple times. It will drop and
    recreate the database to ensure a clean environment.

Execution Order:
    1. Drop and recreate the 'DataWarehouse' database.
    2. Create the 'bronze', 'silver', and 'gold' schemas.
    3. Create the Bronze staging table for outpatient data.
    4. Create the stored procedure to load data into the Bronze staging table.

WARNING:
    Running this script will permanently delete the entire 'DataWarehouse' database
    if it exists. Ensure you have backups if you are running this against an
    existing database with valuable data.
=========================================================================================
*/

-- Set context to the master database to manage database creation
USE master;
GO

PRINT '================================================================';
PRINT 'Phase 1: Creating the DataWarehouse Database and Schemas';
PRINT '================================================================';

-- Drop the database if it exists to ensure a clean start
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
    PRINT 'SUCCESS: Existing database ''DataWarehouse'' dropped.';
END
GO

-- Create the new 'DataWarehouse' database
CREATE DATABASE DataWarehouse;
PRINT 'SUCCESS: Database ''DataWarehouse'' created.';
GO

-- Switch context to the newly created database
USE DataWarehouse;
GO

-- Create the required schemas for our medallion architecture
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'bronze')
BEGIN
    EXEC('CREATE SCHEMA bronze');
    PRINT 'SUCCESS: Schema ''bronze'' created.';
END

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'silver')
BEGIN
    EXEC('CREATE SCHEMA silver');
    PRINT 'SUCCESS: Schema ''silver'' created.';
END

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'gold')
BEGIN
    EXEC('CREATE SCHEMA gold');
    PRINT 'SUCCESS: Schema ''gold'' created.';
END
GO

PRINT '================================================================';
PRINT 'Phase 2: Creating the Bronze Layer Table';
PRINT '================================================================';

-- Create the staging table for raw outpatient data
CREATE TABLE Bronze.stg_OutpatientData
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
    AppointmentStatus NVARCHAR(255),

    -- Metadata columns for auditing and data lineage
    LoadDateTimeUTC DATETIME2 DEFAULT GETUTCDATE(),
    SourceFileName NVARCHAR(255)
);
PRINT 'SUCCESS: Table ''Bronze.stg_OutpatientData'' created.';
GO

PRINT '================================================================';
PRINT 'Phase 3: Creating the Bronze Layer Ingestion Procedure';
PRINT '================================================================';

-- Create the stored procedure to load data into the staging table
CREATE OR ALTER PROCEDURE Bronze.Load_Staging_OutpatientData
AS
BEGIN
    -- Suppress the "(1 row affected)" messages to keep the log clean
    SET NOCOUNT ON;

    -- Declare variables for logging and performance timing
    DECLARE @start_time DATETIME2, @end_time DATETIME2, @batch_start_time DATETIME2, @batch_end_time DATETIME2;
    DECLARE @SourceFileName NVARCHAR(255) = 'outpatient_data_realistic.csv';
    DECLARE @FilePath NVARCHAR(512) = 'C:\DWH_Project\Hospital_Data_Warehouse\datasets -INP\source_crm\outpatient_data_realistic.csv';

    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '----------------------------------------------------------------';
        PRINT 'Executing Stored Procedure: Bronze.Load_Staging_OutpatientData';
        PRINT 'Source File: ' + @SourceFileName;
        PRINT '----------------------------------------------------------------';

        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: Bronze.stg_OutpatientData';
        TRUNCATE TABLE Bronze.stg_OutpatientData;

        PRINT '>> Inserting Data Into: Bronze.stg_OutpatientData';
        BULK INSERT Bronze.stg_OutpatientData
        FROM @FilePath
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
            TABLOCK
        );

        PRINT '>> Updating metadata (SourceFileName)';
        UPDATE Bronze.stg_OutpatientData
        SET SourceFileName = @SourceFileName
        WHERE SourceFileName IS NULL;

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        
        SET @batch_end_time = GETDATE();
        PRINT '----------------------------------------------------------------';
        PRINT 'SUCCESS: Bronze Layer loading procedure executed successfully.';
        PRINT '   - Total Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds.';
        PRINT '----------------------------------------------------------------';

    END TRY
    BEGIN CATCH
        PRINT '!! ERROR OCCURRED WHILE LOADING BRONZE LAYER !!';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        THROW; 
    END CATCH

    SET NOCOUNT OFF;
END
GO
PRINT 'SUCCESS: Stored Procedure ''Bronze.Load_Staging_OutpatientData'' created.';
GO

PRINT '================================================================';
PRINT 'Master script execution completed successfully.';
PRINT 'Your Data Warehouse environment is ready.';
PRINT 'You can now run "EXEC Bronze.Load_Staging_OutpatientData;" to load data.';
PRINT '================================================================';
GO