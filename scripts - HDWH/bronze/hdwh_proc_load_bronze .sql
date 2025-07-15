/*
===============================================================================
Stored Procedure:   Bronze.Load_Staging_OutpatientData
===============================================================================
Script Purpose:
    This stored procedure orchestrates the loading of outpatient data into the 
    Bronze layer. It performs the following actions:

    1. Truncates the 'Bronze.stg_OutpatientData' table to ensure a fresh load.
    2. Uses the BULK INSERT command to efficiently load data from the source 
       'outpatient_data_realistic.csv' file.
    3. Updates the metadata columns (SourceFileName) for the newly loaded batch.
    4. Logs the process, including timing and success or error messages.

Parameters:
    None. This stored procedure is designed to run as a single, complete step.

Usage Example:
    EXEC Bronze.Load_Staging_OutpatientData;
===============================================================================
*/
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
        PRINT '================================================================';
        PRINT 'Executing Stored Procedure: Bronze.Load_Staging_OutpatientData';
        PRINT '================================================================';

        PRINT '----------------------------------------------------------------';
        PRINT 'Loading ERP Outpatient Data';
        PRINT 'Source File: ' + @SourceFileName;
        PRINT '----------------------------------------------------------------';

        SET @start_time = GETDATE();
        
        -- Step 1: Truncate the table to remove old data
        PRINT '>> Truncating Table: Bronze.stg_OutpatientData';
        TRUNCATE TABLE Bronze.stg_OutpatientData;

        -- Step 2: Insert new data from the CSV file
        PRINT '>> Inserting Data Into: Bronze.stg_OutpatientData';
        BULK INSERT Bronze.stg_OutpatientData
        FROM @FilePath
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a', -- Hex for Line Feed (\n), more reliable
            TABLOCK
        );

        -- Step 3: Update metadata for the newly loaded records
        PRINT '>> Updating metadata (SourceFileName)';
        UPDATE Bronze.stg_OutpatientData
        SET SourceFileName = @SourceFileName
        WHERE SourceFileName IS NULL;

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        SET @batch_end_time = GETDATE();
        PRINT '================================================================';
        PRINT 'SUCCESS: Bronze Layer loading is complete.';
        PRINT '   - Total Procedure Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds.';
        PRINT '================================================================';

    END TRY
    BEGIN CATCH
        PRINT '================================================================';
        PRINT '!! ERROR OCCURRED WHILE LOADING BRONZE LAYER !!';
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT 'Error Line: ' + CAST(ERROR_LINE() AS NVARCHAR);
        PRINT '================================================================';
        -- Re-throw the error to allow calling applications to handle it
        THROW; 
    END CATCH

    SET NOCOUNT OFF;
END
GO