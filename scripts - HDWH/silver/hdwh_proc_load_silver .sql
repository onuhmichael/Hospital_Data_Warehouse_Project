CREATE OR ALTER PROCEDURE silver.load_silver_dimensions AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;

    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '================================================';
        PRINT 'Starting Load of Silver Dim Tables';
        PRINT '================================================';

        -- DimPatient
        SET @start_time = GETDATE();
        TRUNCATE TABLE silver.Dim_DimPatient;
        INSERT INTO silver.Dim_DimPatient (
            PatientID, NHS_ID, PatientFirstName, PatientLastName, PatientDOB, PatientPostcode
        )
        SELECT PatientID, NHS_ID, PatientFirstName, PatientLastName, PatientDOB, PatientPostcode
        FROM (
            SELECT *,
                   ROW_NUMBER() OVER (PARTITION BY PatientID ORDER BY PatientDOB DESC) AS rn
            FROM bronze.Appointments
            WHERE PatientID IS NOT NULL
        ) src
        WHERE rn = 1;
        SET @end_time = GETDATE();
        PRINT '>> DimPatient Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -- DimClinic
        SET @start_time = GETDATE();
        TRUNCATE TABLE silver.Dim_DimClinic;
        INSERT INTO silver.Dim_DimClinic (ClinicName, Specialty)
        SELECT DISTINCT TRIM(ClinicName), TRIM(Specialty)
        FROM bronze.Appointments
        WHERE ClinicName IS NOT NULL;
        SET @end_time = GETDATE();
        PRINT '>> DimClinic Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -- DimProvider
        SET @start_time = GETDATE();
        TRUNCATE TABLE silver.Dim_DimProvider;
        INSERT INTO silver.Dim_DimProvider (ProviderID, ProviderName)
        SELECT DISTINCT TRIM(ProviderID), TRIM(ProviderName)
        FROM bronze.Appointments
        WHERE ProviderID IS NOT NULL;
        SET @end_time = GETDATE();
        PRINT '>> DimProvider Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -- DimDiagnosis
        SET @start_time = GETDATE();
        TRUNCATE TABLE silver.Dim_DimDiagnosis;
        INSERT INTO silver.Dim_DimDiagnosis (DiagnosisCode, DiagnosisDescription)
        SELECT DISTINCT TRIM(DiagnosisCode), TRIM(DiagnosisDescription)
        FROM bronze.Appointments
        WHERE DiagnosisCode IS NOT NULL;
        SET @end_time = GETDATE();
        PRINT '>> DimDiagnosis Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -- DimAppointmentStatus
        SET @start_time = GETDATE();
        TRUNCATE TABLE silver.Dim_DimAppointmentStatus;
        INSERT INTO silver.Dim_DimAppointmentStatus (AppointmentStatus)
        SELECT DISTINCT TRIM(AppointmentStatus)
        FROM bronze.Appointments
        WHERE AppointmentStatus IS NOT NULL;
        SET @end_time = GETDATE();
        PRINT '>> DimAppointmentStatus Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -- DimDepartment
        SET @start_time = GETDATE();
        TRUNCATE TABLE silver.Dim_Department;
        INSERT INTO silver.Dim_Department (DepartmentName)
        SELECT DISTINCT TRIM(Department)
        FROM bronze.Appointments
        WHERE Department IS NOT NULL;
        SET @end_time = GETDATE();
        PRINT '>> DimDepartment Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -- DimReferralSource
        SET @start_time = GETDATE();
        TRUNCATE TABLE silver.Dim_ReferralSource;
        INSERT INTO silver.Dim_ReferralSource (ReferralSource)
        SELECT DISTINCT TRIM(ReferralSource)
        FROM bronze.Appointments
        WHERE ReferralSource IS NOT NULL;
        SET @end_time = GETDATE();
        PRINT '>> DimReferralSource Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -- DimOutcome
        SET @start_time = GETDATE();
        TRUNCATE TABLE silver.Dim_Outcome;
        INSERT INTO silver.Dim_Outcome (Outcome)
        SELECT DISTINCT TRIM(Outcome)
        FROM bronze.Appointments
        WHERE Outcome IS NOT NULL;
        SET @end_time = GETDATE();
        PRINT '>> DimOutcome Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -- FactAppointment
        SET @start_time = GETDATE();
        TRUNCATE TABLE silver.Fact_Appointment;
        INSERT INTO silver.Fact_Appointment (
            AppointmentID, AppointmentDate, PatientID, DepartmentName, ProviderID,
            Outcome, ReferralSource, NoShowFlag
        )
        SELECT
            AppointmentID,
            AppointmentDate,
            PatientID,
            TRIM(Department),
            TRIM(ProviderID),
            TRIM(Outcome),
            TRIM(ReferralSource),
            CASE WHEN Outcome = 'No-Show' THEN 1 ELSE 0 END
        FROM bronze.Appointments
        WHERE AppointmentID IS NOT NULL AND AppointmentDate IS NOT NULL;
        SET @end_time = GETDATE();
        PRINT '>> FactAppointment Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        SET @batch_end_time = GETDATE();
        PRINT '==========================================';
        PRINT '✅ Silver Dim & Fact Table Load Completed';
        PRINT '   - Total Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '==========================================';

    END TRY
    BEGIN CATCH
        PRINT '==========================================';
        PRINT '❌ Error occurred during Silver Table Load';
        PRINT 'Message: ' + ERROR_MESSAGE();
        PRINT 'Code: ' + CAST(ERROR_NUMBER() AS NVARCHAR) + ' | State: ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '==========================================';
    END CATCH
END;
GO
