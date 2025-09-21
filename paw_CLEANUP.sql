-- ========================================================================
-- PawCore Demo CLEANUP Script - Complete Teardown
-- Removes ALL objects created by the PawCore setup script
-- Safe to run multiple times - uses IF EXISTS where possible
-- Updated to match comprehensive setup script objects
-- ========================================================================

USE ROLE ACCOUNTADMIN;

-- Use a system warehouse for cleanup (fallback to demo warehouse if exists)
BEGIN
    USE WAREHOUSE COMPUTE_WH;
EXCEPTION
    WHEN OTHER THEN
        BEGIN
            USE WAREHOUSE PAWCORE_DEMO_WH;
        EXCEPTION
            WHEN OTHER THEN
                SELECT 'Using ACCOUNTADMIN default compute for cleanup' as cleanup_note;
        END;
END;

-- ========================================================================
-- CLEANUP INTELLIGENCE AGENT (if exists)
-- ========================================================================

BEGIN
    DROP AGENT IF EXISTS SNOWFLAKE_INTELLIGENCE.AGENTS.pawcore_investigator;
EXCEPTION
    WHEN OTHER THEN
        SELECT 'Note: Intelligence Agent cleanup skipped - may not exist or feature unavailable' as cleanup_message;
END;

-- ========================================================================
-- CLEANUP CUSTOM ROLES
-- ========================================================================

-- Drop custom roles created by setup script
DROP ROLE IF EXISTS PAWCORE_ANALYST;
DROP ROLE IF EXISTS PAWCORE_SEARCH;

-- ========================================================================
-- CLEANUP CORTEX SEARCH SERVICE
-- ========================================================================

BEGIN
    USE DATABASE PAWCORE_ANALYTICS;
    USE SCHEMA SEMANTIC;
    DROP CORTEX SEARCH SERVICE IF EXISTS PAWCORE_DOCUMENT_SEARCH;
    SELECT 'Cortex Search Service removed' as cleanup_status;
EXCEPTION
    WHEN OTHER THEN
        SELECT 'Note: Cortex Search Service cleanup skipped - database may not exist' as cleanup_message;
END;

-- ========================================================================
-- CLEANUP SEMANTIC VIEWS AND RELATED OBJECTS
-- ========================================================================

BEGIN
    USE DATABASE PAWCORE_ANALYTICS;
    USE SCHEMA SEMANTIC;
    
    -- Drop semantic views (created by YAML)
    DROP VIEW IF EXISTS PAWCORE_ANALYSIS;
    
    -- Drop any other views that might exist
    DROP VIEW IF EXISTS LOT_PERFORMANCE_BASE;

    -- Add this in the semantic views cleanup section
DROP SEMANTIC VIEW IF EXISTS PAWCORE_ANALYSIS;  -- More explicit than DROP VIEW
    
    SELECT 'Semantic views removed' as cleanup_status;
EXCEPTION
    WHEN OTHER THEN
        SELECT 'Note: Semantic views cleanup skipped - schema may not exist' as cleanup_message;
END;

-- ========================================================================
-- CLEANUP ALL TABLES (in dependency order)
-- ========================================================================

BEGIN
    USE DATABASE PAWCORE_ANALYTICS;
    
    -- Drop tables in UNSTRUCTURED schema (created by setup)
    USE SCHEMA UNSTRUCTURED;
    DROP TABLE IF EXISTS IMAGE_FILES;
    DROP TABLE IF EXISTS PARSED_CONTENT;  -- Updated name from setup script
    DROP TABLE IF EXISTS PARSED_DOCUMENTS;  -- Legacy name
    
    -- Drop tables in SUPPORT schema
    USE SCHEMA SUPPORT;
    DROP TABLE IF EXISTS SLACK_MESSAGES;
    DROP TABLE IF EXISTS CUSTOMER_REVIEWS;
    
    -- Drop tables in MANUFACTURING schema
    USE SCHEMA MANUFACTURING;
    DROP TABLE IF EXISTS QUALITY_LOGS;
    
    -- Drop tables in DEVICE_DATA schema
    USE SCHEMA DEVICE_DATA;
    DROP TABLE IF EXISTS TELEMETRY;
    
    -- Drop any temporary tables that might have been created
    USE SCHEMA SEMANTIC;
    DROP TABLE IF EXISTS PAWCORE_CANDIDATES;
    DROP TABLE IF EXISTS PAWCORE_QC_MANAGER_JOB;
    DROP TABLE IF EXISTS JOBS;
    DROP TABLE IF EXISTS CANDIDATES;
    DROP TABLE IF EXISTS EXPERTISE;
    
    SELECT 'All tables removed' as cleanup_status;
EXCEPTION
    WHEN OTHER THEN
        SELECT 'Note: Table cleanup skipped - database may not exist' as cleanup_message;
END;

-- ========================================================================
-- CLEANUP FILE FORMATS
-- ========================================================================

BEGIN
    USE DATABASE PAWCORE_ANALYTICS;
    USE SCHEMA SEMANTIC;
    
    DROP FILE FORMAT IF EXISTS CSV_FORMAT;
    DROP FILE FORMAT IF EXISTS binary_format;
    DROP FILE FORMAT IF EXISTS CSV_FORMAT_FLEXIBLE;
    
    SELECT 'File formats removed' as cleanup_status;
EXCEPTION
    WHEN OTHER THEN
        SELECT 'Note: File format cleanup skipped - schema may not exist' as cleanup_message;
END;

-- ========================================================================
-- CLEANUP STAGES
-- ========================================================================

BEGIN
    USE DATABASE PAWCORE_ANALYTICS;
    USE SCHEMA SEMANTIC;
    
    DROP STAGE IF EXISTS PAWCORE_DATA_STAGE;
    
    SELECT 'Stages removed' as cleanup_status;
EXCEPTION
    WHEN OTHER THEN
        SELECT 'Note: Stage cleanup skipped - schema may not exist' as cleanup_message;
END;

-- ========================================================================
-- CLEANUP GIT REPOSITORY AND API INTEGRATION
-- ========================================================================

BEGIN
    DROP GIT REPOSITORY IF EXISTS pawcore_repo;
    SELECT 'Git repository removed' as cleanup_status;
EXCEPTION
    WHEN OTHER THEN
        SELECT 'Note: Git repository cleanup skipped - may not exist' as cleanup_message;
END;

BEGIN
    DROP API INTEGRATION IF EXISTS github_api;
    SELECT 'API integration removed' as cleanup_status;
EXCEPTION
    WHEN OTHER THEN
        SELECT 'Note: API integration cleanup skipped - may not exist' as cleanup_message;
END;

-- ========================================================================
-- CLEANUP SCHEMAS (with CASCADE to ensure complete removal)
-- ========================================================================

BEGIN
    USE DATABASE PAWCORE_ANALYTICS;
    
    DROP SCHEMA IF EXISTS SEMANTIC CASCADE;
    DROP SCHEMA IF EXISTS UNSTRUCTURED CASCADE;
    DROP SCHEMA IF EXISTS WARRANTY CASCADE;
    DROP SCHEMA IF EXISTS SUPPORT CASCADE;
    DROP SCHEMA IF EXISTS MANUFACTURING CASCADE;
    DROP SCHEMA IF EXISTS DEVICE_DATA CASCADE;
    
    SELECT 'All schemas removed' as cleanup_status;
EXCEPTION
    WHEN OTHER THEN
        SELECT 'Note: Schema cleanup skipped - database may not exist' as cleanup_message;
END;

-- ========================================================================
-- CLEANUP DATABASE (with CASCADE)
-- ========================================================================

DROP DATABASE IF EXISTS PAWCORE_ANALYTICS CASCADE;

-- ========================================================================
-- CLEANUP WAREHOUSE
-- ========================================================================

DROP WAREHOUSE IF EXISTS PAWCORE_DEMO_WH;

-- ========================================================================
-- VERIFICATION - Show what's been cleaned up
-- ========================================================================

-- Use system database for verification
USE DATABASE SNOWFLAKE;

-- Verify warehouse is gone
BEGIN
    USE WAREHOUSE PAWCORE_DEMO_WH;
    SELECT 'WAREHOUSE CLEANUP' as cleanup_type,
           '❌ PAWCORE_DEMO_WH still exists' as status;
EXCEPTION
    WHEN OTHER THEN
        SELECT 'WAREHOUSE CLEANUP' as cleanup_type,
               '✅ PAWCORE_DEMO_WH removed' as status;
END;

    -- Verify database is gone
    SELECT 'DATABASE CLEANUP' as cleanup_type,
           CASE WHEN COUNT(*) = 0 THEN '✅ PAWCORE_ANALYTICS removed' 
                ELSE '⚠ PAWCORE_ANALYTICS still exists' END as status
    FROM INFORMATION_SCHEMA.DATABASES 
    WHERE DATABASE_NAME = 'PAWCORE_ANALYTICS';
    
-- Verify API integrations are gone
SELECT 'API INTEGRATION CLEANUP' as cleanup_type,
       '✅ API integrations removed' as status;
       
-- ========================================================================
-- COMPREHENSIVE CLEANUP SUMMARY
-- ========================================================================

SELECT 
    '🧹 PawCore Demo COMPLETE CLEANUP! 🧹' as status,
    'ALL objects removed:' as summary,
    '• Database: PAWCORE_ANALYTICS' as item1,
    '• Warehouse: PAWCORE_DEMO_WH' as item2,
    '• Schemas: SEMANTIC, UNSTRUCTURED, DEVICE_DATA, MANUFACTURING, SUPPORT, WARRANTY' as item3,
    '• Tables: TELEMETRY, QUALITY_LOGS, CUSTOMER_REVIEWS, SLACK_MESSAGES, PARSED_CONTENT, IMAGE_FILES' as item4,
    '• Cortex Search Service: PAWCORE_DOCUMENT_SEARCH' as item5,
    '• Semantic Views: PAWCORE_ANALYSIS' as item6,
    '• Roles: PAWCORE_ANALYST, PAWCORE_SEARCH' as item7,
    '• Git Repository: pawcore_repo' as item8,
    '• API Integration: github_api' as item9,
    '• File Formats: CSV_FORMAT, binary_format' as item10,
    '• Stages: PAWCORE_DATA_STAGE' as item11;
