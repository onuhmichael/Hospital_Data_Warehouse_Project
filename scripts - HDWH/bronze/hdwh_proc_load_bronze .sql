/*
===============================================================================
Stored Procedure:   Load Bronze Layer (Source CSV → bronze.stg_OutpatientData)
===============================================================================
Script Purpose:
    This stored procedure loads outpatient data into the 'bronze' schema from 
    external CSV files. It performs the following actions:

    1. Truncates the staging table 'bronze.stg_OutpatientData' to ensure a clean load.
    2. Uses the BULK INSERT command to efficiently load data from the source CSV file.
    3. Dynamically generates a unique error log file for each run to avoid file conflicts.
    4. Logs the process, including start time, end time, and duration.

Parameters:
    None.
    This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.Load_Staging_OutpatientData;
===============================================================================
*/

CREATE OR ALTER PROCEDURE bronze.Load_Staging_OutpatientData
AS
BEGIN
    SET NOCOUNT ON;

    -- Declare timestamps for logging
    DECLARE @start_time DATETIME2 = SYSDATETIME();
    DECLARE @batch_start_time DATETIME2 = SYSDATETIME();

    -- Define source file and path
    DECLARE @SourceFileName NVARCHAR(255) = 'outpatient_data_realistic.csv';
    DECLARE @FilePath NVARCHAR(512) = 'C:\Users\onuhm\Desktop\op-data\op-data-set.csv';

    -- Generate a unique error file name using timestamp
    DECLARE @ErrorFile NVARCHAR(512) = 'C:\Users\onuhm\Desktop\op-data\bulk_errors_' + 
        FORMAT(SYSDATETIME(), 'yyyyMMdd_HHmmss') + '.log';

    -- Prepare dynamic SQL for BULK INSERT
    DECLARE @sql NVARCHAR(MAX);

    BEGIN TRY
        PRINT '================================================================';
        PRINT 'Executing Stored Procedure: bronze.Load_Staging_OutpatientData';
        PRINT 'Start Time: ' + CAST(@start_time AS NVARCHAR);
        PRINT '================================================================';

        -- Step 1: Truncate the staging table
        PRINT '>> Truncating Table: bronze.stg_OutpatientData';
        TRUNCATE TABLE bronze.stg_OutpatientData;

        -- Step 2: Perform BULK INSERT with dynamic error file
        PRINT '>> Bulk Inserting Data From File: ' + @SourceFileName;
        PRINT '>> Error File: ' + @ErrorFile;

        SET @sql = '
            BULK INSERT bronze.stg_OutpatientData
            FROM ''' + @FilePath + '''
            WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = '','',
                ROWTERMINATOR = ''\n'',
                TABLOCK,
                ERRORFILE = ''' + @ErrorFile + '''
            );
        ';
        EXEC sp_executesql @sql;

        -- Optional metadata update (commented out for now)
        /*
        PRINT '>> Updating metadata column: SourceFileName';
        IF COL_LENGTH('bronze.stg_OutpatientData', 'SourceFileName') IS NULL
        BEGIN
            ALTER TABLE bronze.stg_OutpatientData ADD SourceFileName NVARCHAR(255);
        END

        UPDATE bronze.stg_OutpatientData
        SET SourceFileName = @SourceFileName;
        */

        -- Step 3: Log duration
        DECLARE @end_time DATETIME2 = SYSDATETIME();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        DECLARE @batch_end_time DATETIME2 = SYSDATETIME();
        PRINT '================================================================';
        PRINT 'SUCCESS: bronze Layer loading is complete.';
        PRINT 'Total Procedure Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds.';
        PRINT '================================================================';

    END TRY
    BEGIN CATCH
        PRINT '================================================================';
        PRINT '!! ERROR OCCURRED WHILE LOADING bronze LAYER !!';
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT 'Error Line: ' + CAST(ERROR_LINE() AS NVARCHAR);
        PRINT '================================================================';
        THROW;
    END CATCH

    SET NOCOUNT OFF;
END
GO
