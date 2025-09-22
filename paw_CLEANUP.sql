-- ========================================================================
-- PawCore Demo CLEANUP Script - Simplified & Robust
-- Removes ALL objects created by the PawCore setup script
-- Handles missing objects gracefully
-- ========================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE PAWCORE_DEMO_WH;

-- Try to use PawCore warehouse, fallback to system warehouse if needed
BEGIN
    USE WAREHOUSE PAWCORE_DEMO_WH;
EXCEPTION
    WHEN OTHER THEN
        BEGIN
            USE WAREHOUSE COMPUTE_WH;
        EXCEPTION
            WHEN OTHER THEN
                SELECT 'Using default compute for cleanup' as cleanup_note;
        END;
END;

-- Set database context for cleanup (if it exists)
BEGIN
    USE DATABASE PAWCORE_ANALYTICS;
EXCEPTION
    WHEN OTHER THEN
        SELECT 'Database does not exist, using fully qualified names' as cleanup_note;
END;

-- ========================================================================
-- SIMPLE CLEANUP (No error handling needed with IF EXISTS)
-- ========================================================================

-- Drop custom roles
DROP ROLE IF EXISTS PAWCORE_ANALYST;
DROP ROLE IF EXISTS PAWCORE_SEARCH;

-- Drop Git repository and API integration first (no database dependency)
DROP GIT REPOSITORY IF EXISTS pawcore_repo;
DROP API INTEGRATION IF EXISTS github_api;

-- Drop Cortex Search Service (if database exists)
DROP CORTEX SEARCH SERVICE IF EXISTS PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DOCUMENT_SEARCH;

-- Drop semantic views (use correct syntax)
DROP SEMANTIC VIEW IF EXISTS PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_ANALYSIS;

-- Drop all tables with fully qualified names
DROP TABLE IF EXISTS PAWCORE_ANALYTICS.UNSTRUCTURED.IMAGE_FILES;
DROP TABLE IF EXISTS PAWCORE_ANALYTICS.UNSTRUCTURED.PARSED_CONTENT;
DROP TABLE IF EXISTS PAWCORE_ANALYTICS.UNSTRUCTURED.PARSED_DOCUMENTS;
DROP TABLE IF EXISTS PAWCORE_ANALYTICS.SUPPORT.SLACK_MESSAGES;
DROP TABLE IF EXISTS PAWCORE_ANALYTICS.SUPPORT.CUSTOMER_REVIEWS;
DROP TABLE IF EXISTS PAWCORE_ANALYTICS.MANUFACTURING.QUALITY_LOGS;
DROP TABLE IF EXISTS PAWCORE_ANALYTICS.DEVICE_DATA.TELEMETRY;

-- Drop file formats
DROP FILE FORMAT IF EXISTS PAWCORE_ANALYTICS.SEMANTIC.CSV_FORMAT;
DROP FILE FORMAT IF EXISTS PAWCORE_ANALYTICS.SEMANTIC.binary_format;

-- Drop stage
DROP STAGE IF EXISTS PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DATA_STAGE;

-- Drop schemas (CASCADE will handle any remaining objects)
DROP SCHEMA IF EXISTS PAWCORE_ANALYTICS.SEMANTIC CASCADE;
DROP SCHEMA IF EXISTS PAWCORE_ANALYTICS.UNSTRUCTURED CASCADE;
DROP SCHEMA IF EXISTS PAWCORE_ANALYTICS.WARRANTY CASCADE;
DROP SCHEMA IF EXISTS PAWCORE_ANALYTICS.SUPPORT CASCADE;
DROP SCHEMA IF EXISTS PAWCORE_ANALYTICS.MANUFACTURING CASCADE;
DROP SCHEMA IF EXISTS PAWCORE_ANALYTICS.DEVICE_DATA CASCADE;

-- Drop database LAST (CASCADE will handle any missed objects)
DROP DATABASE IF EXISTS PAWCORE_ANALYTICS CASCADE;

-- Drop warehouse LAST
DROP WAREHOUSE IF EXISTS PAWCORE_DEMO_WH;

-- ========================================================================
-- SIMPLE VERIFICATION (Use system database for final queries)
-- ========================================================================

USE DATABASE SNOWFLAKE;

SELECT '🧹 PawCore Cleanup Complete! 🧹' as status;

SELECT 'All PawCore demo objects have been removed' as message;

SELECT 'Ready for fresh setup!' as next_step;
