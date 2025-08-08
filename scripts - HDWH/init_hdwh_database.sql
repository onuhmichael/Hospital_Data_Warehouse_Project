/*
=============================================================
Outpatient Data Warehouse Initialization Script
=============================================================
Script Purpose:
    This script creates a new SQL Server database named 'op_datawarehouse', designed specifically 
    to support outpatient data management in a hospital setting. It follows a medallion architecture 
    with three schemas — 'bronze', 'silver', and 'gold' — to organize data across ingestion, 
    transformation, and analytics layers.

WARNING:
    Running this script will drop the entire 'op_datawarehouse' database if it exists. 
    All data in the database will be permanently deleted. Proceed with caution 
    and ensure you have proper backups before running this script.

Author: Michael Onuh
Date: 2025-07-17
=============================================================
*/

USE master;
GO

PRINT '================================================================';
PRINT 'Phase 1: Dropping Existing op_datawarehouse Database (if any)';
PRINT '================================================================';

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'op_datawarehouse')
BEGIN
    ALTER DATABASE op_datawarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE op_datawarehouse;
    PRINT '✅ SUCCESS: Existing database ''op_datawarehouse'' dropped.';
END
ELSE
BEGIN
    PRINT 'ℹ️ INFO: No existing ''op_datawarehouse'' database found.';
END
GO

PRINT '================================================================';
PRINT 'Phase 2: Creating New op_datawarehouse Database';
PRINT '================================================================';

CREATE DATABASE op_datawarehouse;
PRINT '✅ SUCCESS: Database ''op_datawarehouse'' created.';
GO

USE op_datawarehouse;
GO

PRINT '================================================================';
PRINT 'Phase 3: Creating Medallion Schemas (bronze, silver, gold)';
PRINT '================================================================';

-- Create bronze schema
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'bronze')
BEGIN
    EXEC('CREATE SCHEMA bronze AUTHORIZATION dbo');
    PRINT '✅ SUCCESS: Schema ''bronze'' created.';
END
ELSE
BEGIN
    PRINT 'ℹ️ INFO: Schema ''bronze'' already exists.';
END

-- Create silver schema
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'silver')
BEGIN
    EXEC('CREATE SCHEMA silver AUTHORIZATION dbo');
    PRINT '✅ SUCCESS: Schema ''silver'' created.';
END
ELSE
BEGIN
    PRINT 'ℹ️ INFO: Schema ''silver'' already exists.';
END

-- Create gold schema
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'gold')
BEGIN
    EXEC('CREATE SCHEMA gold AUTHORIZATION dbo');
    PRINT '✅ SUCCESS: Schema ''gold'' created.';
END
ELSE
BEGIN
    PRINT 'ℹ️ INFO: Schema ''gold'' already exists.';
END
GO
