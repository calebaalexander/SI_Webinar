-- ========================================================================
-- CoCo_PawCore Setup Script - Non-Destructive, Additive Setup
-- ========================================================================
-- This script sets up the PawCore analytics environment for the
-- Cortex Code (CoCo) Hands-On Labs. It is designed to be:
--   1. SELF-CONTAINED: Creates everything from scratch for new participants
--   2. NON-DESTRUCTIVE: Uses IF NOT EXISTS so existing objects are preserved
--   3. RE-RUNNABLE: Safe to execute multiple times without side effects
--   4. COEXISTENT: Works alongside the previous Cortex_PawCore webinar objects
-- ========================================================================

USE ROLE ACCOUNTADMIN;

-- ========================================================================
-- INFRASTRUCTURE SETUP
-- ========================================================================

CREATE WAREHOUSE IF NOT EXISTS PAWCORE_DEMO_WH
    WITH WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE;

USE WAREHOUSE PAWCORE_DEMO_WH;

CREATE DATABASE IF NOT EXISTS PAWCORE_ANALYTICS;
USE DATABASE PAWCORE_ANALYTICS;

CREATE SCHEMA IF NOT EXISTS DEVICE_DATA;
CREATE SCHEMA IF NOT EXISTS MANUFACTURING;
CREATE SCHEMA IF NOT EXISTS SUPPORT;
CREATE SCHEMA IF NOT EXISTS WARRANTY;
CREATE SCHEMA IF NOT EXISTS UNSTRUCTURED;
CREATE SCHEMA IF NOT EXISTS SEMANTIC;

USE SCHEMA SEMANTIC;

-- ========================================================================
-- FILE FORMATS
-- ========================================================================

CREATE FILE FORMAT IF NOT EXISTS CSV_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    DATE_FORMAT = 'YYYY-MM-DD'
    TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS';

CREATE FILE FORMAT IF NOT EXISTS binary_format
    TYPE = 'CSV'
    RECORD_DELIMITER = NONE
    FIELD_DELIMITER = NONE
    SKIP_HEADER = 0;

-- ========================================================================
-- GIT INTEGRATION (Non-Destructive)
-- ========================================================================

CREATE API INTEGRATION IF NOT EXISTS github_api
    API_PROVIDER = git_https_api
    API_ALLOWED_PREFIXES = ('https://github.com/calebaalexander/')
    ENABLED = TRUE
    COMMENT = 'GitHub API integration for PawCore demo';

CREATE GIT REPOSITORY IF NOT EXISTS pawcore_repo
    API_INTEGRATION = github_api
    ORIGIN = 'https://github.com/calebaalexander/HandsOnLabs.git'
    COMMENT = 'PawCore demo data repository';

ALTER GIT REPOSITORY pawcore_repo FETCH;

-- ========================================================================
-- INTERNAL STAGE
-- ========================================================================

CREATE STAGE IF NOT EXISTS PAWCORE_DATA_STAGE
    DIRECTORY = (ENABLE = TRUE)
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

GRANT READ, WRITE ON STAGE PAWCORE_DATA_STAGE TO ROLE ACCOUNTADMIN;

ALTER WAREHOUSE PAWCORE_DEMO_WH SET WAREHOUSE_SIZE = 'LARGE';

-- ========================================================================
-- COPY DATA FROM GIT TO INTERNAL STAGE
-- ========================================================================
-- COPY FILES is additive — existing files at the target are not overwritten

COPY FILES
INTO @PAWCORE_DATA_STAGE/Document_Stage/
FROM @pawcore_repo/branches/main/2-Cortex-Code/data/Document_Stage/;

COPY FILES
INTO @PAWCORE_DATA_STAGE/images/
FROM @pawcore_repo/branches/main/2-Cortex-Code/data/images/
PATTERN = 'SmartCollar.*[.]jpeg';

COPY FILES
INTO @PAWCORE_DATA_STAGE/images/
FROM @pawcore_repo/branches/main/2-Cortex-Code/data/images/barkour.jpg;

COPY FILES
INTO @PAWCORE_DATA_STAGE/HR/
FROM @pawcore_repo/branches/main/2-Cortex-Code/data/HR/;

COPY FILES
INTO @PAWCORE_DATA_STAGE/Manufacturing/
FROM @pawcore_repo/branches/main/2-Cortex-Code/data/Manufacturing/;

COPY FILES
INTO @PAWCORE_DATA_STAGE/Telemetry/
FROM @pawcore_repo/branches/main/2-Cortex-Code/data/Telemetry/;

COPY FILES
INTO @PAWCORE_DATA_STAGE/
FROM @pawcore_repo/branches/main/2-Cortex-Code/setup/pawcore_semantic_layer.yaml;

LIST @PAWCORE_DATA_STAGE;

SELECT 'Files successfully copied to stage' as status;

-- ========================================================================
-- CREATE TABLES (IF NOT EXISTS)
-- ========================================================================

USE SCHEMA DEVICE_DATA;

CREATE TABLE IF NOT EXISTS TELEMETRY (
    device_id VARCHAR(50),
    timestamp TIMESTAMP,
    battery_level FLOAT,
    humidity_reading FLOAT,
    temperature FLOAT,
    charging_cycles INTEGER,
    lot_number VARCHAR(50),
    region VARCHAR(50)
);

USE SCHEMA MANUFACTURING;

CREATE TABLE IF NOT EXISTS QUALITY_LOGS (
    lot_number VARCHAR(50),
    timestamp TIMESTAMP,
    test_type VARCHAR(100),
    measurement_value FLOAT,
    pass_fail VARCHAR(10),
    operator_id VARCHAR(50),
    station_id VARCHAR(50),
    test_name VARCHAR(100),
    notes TEXT
);

USE SCHEMA SUPPORT;

CREATE TABLE IF NOT EXISTS CUSTOMER_REVIEWS (
    review_id VARCHAR(50),
    device_id VARCHAR(50),
    lot_number VARCHAR(50),
    rating INTEGER,
    review_text TEXT,
    date DATE,
    region VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS SLACK_MESSAGES (
    message_id VARCHAR(50),
    slack_channel VARCHAR(50),
    user_name VARCHAR(100),
    text TEXT,
    thread_id VARCHAR(50)
);

USE SCHEMA UNSTRUCTURED;

CREATE TABLE IF NOT EXISTS IMAGE_FILES (
    file_name VARCHAR(500),
    file_type VARCHAR(50),
    content_type VARCHAR(50),
    metadata VARIANT,
    upload_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- ========================================================================
-- LOAD DATA INTO TABLES (Truncate first to avoid duplication)
-- ========================================================================
-- Using TRUNCATE + FORCE=TRUE ensures fresh data load each time.
-- This prevents duplication when re-running the script.

TRUNCATE TABLE IF EXISTS DEVICE_DATA.TELEMETRY;
TRUNCATE TABLE IF EXISTS MANUFACTURING.QUALITY_LOGS;
TRUNCATE TABLE IF EXISTS SUPPORT.CUSTOMER_REVIEWS;
TRUNCATE TABLE IF EXISTS SUPPORT.SLACK_MESSAGES;

COPY INTO DEVICE_DATA.TELEMETRY (device_id, timestamp, battery_level, humidity_reading, temperature, charging_cycles, lot_number, region)
FROM (
    SELECT 
        $1 as device_id,
        $2 as timestamp, 
        $3 as battery_level,
        $4 as humidity_reading,
        $5 as temperature,
        $6 as charging_cycles,
        $7 as lot_number,
        $8 as region
    FROM @PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DATA_STAGE/Telemetry/
)
FILE_FORMAT = (
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('NULL', 'null')
    EMPTY_FIELD_AS_NULL = TRUE
    TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS'
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
)
PATTERN = '.*[.]csv'
ON_ERROR = 'CONTINUE'
FORCE = TRUE;

-- ========================================================================
-- UNSTRUCTURED DATA

COPY INTO MANUFACTURING.QUALITY_LOGS
FROM @PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DATA_STAGE/Manufacturing/
FILE_FORMAT = (
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('NULL', 'null')
    EMPTY_FIELD_AS_NULL = TRUE
    TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS'
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    TRIM_SPACE = TRUE
)
PATTERN = '.*[.]csv'
ON_ERROR = 'CONTINUE'
FORCE = TRUE;

COPY INTO SUPPORT.CUSTOMER_REVIEWS (review_id, device_id, lot_number, rating, review_text, date, region)
FROM (
    SELECT 
        $1 as review_id,
        CASE 
            WHEN $3 = 'EMEA' AND $1::INT <= 100 THEN 'SC-2024-341-001'
            WHEN $3 = 'EMEA' AND $1::INT <= 200 THEN 'SC-2024-341-002'
            WHEN $3 = 'EMEA' AND $1::INT <= 300 THEN 'SC-2024-341-003'
            WHEN $3 = 'EMEA' AND $1::INT <= 400 THEN 'SC-2024-341-004'
            WHEN $3 = 'EMEA' AND $1::INT <= 500 THEN 'SC-2024-341-005'
            WHEN $3 = 'EMEA' AND $1::INT <= 600 THEN 'SC-2024-341-010'
            WHEN $3 = 'EMEA' AND $1::INT <= 700 THEN 'SC-2024-341-020'
            WHEN $3 = 'EMEA' AND $1::INT <= 800 THEN 'SC-2024-341-050'
            WHEN $3 = 'EMEA' AND $1::INT <= 900 THEN 'SC-2024-341-100'
            WHEN $3 = 'EMEA' AND $1::INT > 900 THEN 'SC-2024-341-200'
            WHEN $3 = 'Americas' THEN 'SC-2024-340-001'
            ELSE 'SC-2024-339-001'
        END as device_id,
        CASE 
            WHEN $3 = 'EMEA' THEN 'LOT341'
            WHEN $3 = 'Americas' THEN 'LOT340'
            ELSE 'LOT339'
        END as lot_number,
        $6 as rating,
        $5 as review_text,
        $4 as date,
        $3 as region
    FROM @PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DATA_STAGE/Document_Stage/
)
FILE_FORMAT = (
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('NULL', 'null')
    EMPTY_FIELD_AS_NULL = TRUE
    DATE_FORMAT = 'YYYY-MM-DD'
    TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS'
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    TRIM_SPACE = TRUE
)
PATTERN = '.*customer_reviews.*[.]csv'
ON_ERROR = 'CONTINUE'
FORCE = TRUE;

COPY INTO SUPPORT.SLACK_MESSAGES (message_id, slack_channel, user_name, text, thread_id)
FROM @PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DATA_STAGE/Document_Stage/pawcore_slack.csv
FILE_FORMAT = (
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('NULL', 'null')
    EMPTY_FIELD_AS_NULL = TRUE
    TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS'
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    TRIM_SPACE = TRUE
)
ON_ERROR = 'CONTINUE'
FORCE = TRUE; - PDF PARSING (Only if table is empty or missing)
-- ========================================================================

USE SCHEMA UNSTRUCTURED;

CREATE TABLE IF NOT EXISTS PARSED_CONTENT (
    relative_path VARCHAR,
    file_name VARCHAR,
    content TEXT
);

INSERT INTO PARSED_CONTENT (relative_path, file_name, content)
SELECT relative_path, file_name, content
FROM (
    SELECT 
        'Document_Stage/QC_standards_SEPT24.pdf' as relative_path,
        'QC_standards_SEPT24.pdf' as file_name,
        SNOWFLAKE.CORTEX.PARSE_DOCUMENT(
            @PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DATA_STAGE,
            'Document_Stage/QC_standards_SEPT24.pdf',
            {'mode':'LAYOUT'}
        ):content::string AS content

    UNION ALL

    SELECT 
        'Manufacturing/quality_control_documentation.md' as relative_path,
        'quality_control_documentation.md' as file_name,
        SNOWFLAKE.CORTEX.PARSE_DOCUMENT(
            @PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DATA_STAGE,
            'Manufacturing/quality_control_documentation.md',
            {'mode':'LAYOUT'}
        ):content::string AS content

    UNION ALL

    SELECT 
        'HR/resume_good_experience.pdf' as relative_path,
        'resume_good_experience.pdf' as file_name,
        SNOWFLAKE.CORTEX.PARSE_DOCUMENT(
            @PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DATA_STAGE,
            'HR/resume_good_experience.pdf',
            {'mode':'LAYOUT'}
        ):content::string AS content

    UNION ALL

    SELECT 
        'HR/resume_perfect_match.pdf' as relative_path,
        'resume_perfect_match.pdf' as file_name,
        SNOWFLAKE.CORTEX.PARSE_DOCUMENT(
            @PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DATA_STAGE,
            'HR/resume_perfect_match.pdf',
            {'mode':'LAYOUT'}
        ):content::string AS content

    UNION ALL

    SELECT 
        'HR/resume_technical_wrong_focus.pdf' as relative_path,
        'resume_technical_wrong_focus.pdf' as file_name,
        SNOWFLAKE.CORTEX.PARSE_DOCUMENT(
            @PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DATA_STAGE,
            'HR/resume_technical_wrong_focus.pdf',
            {'mode':'LAYOUT'}
        ):content::string AS content

    UNION ALL

    SELECT 
        'HR/resume_wrong_experience_level.pdf' as relative_path,
        'resume_wrong_experience_level.pdf' as file_name,
        SNOWFLAKE.CORTEX.PARSE_DOCUMENT(
            @PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DATA_STAGE,
            'HR/resume_wrong_experience_level.pdf',
            {'mode':'LAYOUT'}
        ):content::string AS content

    UNION ALL

    SELECT 
        'HR/resume_wrong_industry.pdf' as relative_path,
        'resume_wrong_industry.pdf' as file_name,
        SNOWFLAKE.CORTEX.PARSE_DOCUMENT(
            @PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DATA_STAGE,
            'HR/resume_wrong_industry.pdf',
            {'mode':'LAYOUT'}
        ):content::string AS content
) AS new_docs
WHERE NOT EXISTS (SELECT 1 FROM PARSED_CONTENT LIMIT 1);

INSERT INTO IMAGE_FILES (file_name, file_type, content_type, metadata)
SELECT 
    REGEXP_SUBSTR(METADATA$FILENAME, '[^/]+$') as file_name,
    CASE 
        WHEN LOWER(METADATA$FILENAME) LIKE '%.jpg' OR LOWER(METADATA$FILENAME) LIKE '%.jpeg' THEN 'JPEG'
        WHEN LOWER(METADATA$FILENAME) LIKE '%.png' THEN 'PNG'
        ELSE 'UNKNOWN'
    END as file_type,
    'image' as content_type,
    OBJECT_CONSTRUCT(
        'source', 'github',
        'timestamp', CURRENT_TIMESTAMP()::string,
        'file_type', 'image',
        'path', 'images/' || METADATA$FILENAME
    ) as metadata
FROM @PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DATA_STAGE/images/ 
(FILE_FORMAT => PAWCORE_ANALYTICS.SEMANTIC.binary_format, PATTERN => '.*[.](jpg|jpeg|png)$')
WHERE NOT EXISTS (SELECT 1 FROM IMAGE_FILES LIMIT 1);

-- ========================================================================
-- CORTEX SEARCH SERVICE
-- ========================================================================

USE SCHEMA SEMANTIC;

CREATE CORTEX SEARCH SERVICE IF NOT EXISTS PAWCORE_DOCUMENT_SEARCH
ON content
ATTRIBUTES relative_path, file_name
WAREHOUSE = PAWCORE_DEMO_WH
TARGET_LAG = '1 hour'
COMMENT = 'Cortex Search Service for PawCore document intelligence'
AS (
    SELECT content, relative_path, file_name
    FROM PAWCORE_ANALYTICS.UNSTRUCTURED.PARSED_CONTENT
);

-- ========================================================================
-- ROLE SETUP & GRANTS
-- ========================================================================

CREATE ROLE IF NOT EXISTS PAWCORE_ANALYST;
CREATE ROLE IF NOT EXISTS PAWCORE_SEARCH;

GRANT USAGE ON WAREHOUSE PAWCORE_DEMO_WH TO ROLE ACCOUNTADMIN;
GRANT USAGE ON DATABASE PAWCORE_ANALYTICS TO ROLE ACCOUNTADMIN;
GRANT USAGE ON ALL SCHEMAS IN DATABASE PAWCORE_ANALYTICS TO ROLE ACCOUNTADMIN;
GRANT SELECT ON ALL TABLES IN DATABASE PAWCORE_ANALYTICS TO ROLE ACCOUNTADMIN;
GRANT USAGE ON CORTEX SEARCH SERVICE PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DOCUMENT_SEARCH TO ROLE ACCOUNTADMIN;

GRANT USAGE ON WAREHOUSE PAWCORE_DEMO_WH TO ROLE PUBLIC;
GRANT USAGE ON DATABASE PAWCORE_ANALYTICS TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA PAWCORE_ANALYTICS.SEMANTIC TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA PAWCORE_ANALYTICS.UNSTRUCTURED TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA PAWCORE_ANALYTICS.DEVICE_DATA TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA PAWCORE_ANALYTICS.MANUFACTURING TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA PAWCORE_ANALYTICS.SUPPORT TO ROLE PUBLIC;
GRANT USAGE ON CORTEX SEARCH SERVICE PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DOCUMENT_SEARCH TO ROLE PUBLIC;
GRANT SELECT ON TABLE PAWCORE_ANALYTICS.UNSTRUCTURED.PARSED_CONTENT TO ROLE PUBLIC;
GRANT SELECT ON ALL TABLES IN SCHEMA PAWCORE_ANALYTICS.DEVICE_DATA TO ROLE PUBLIC;
GRANT SELECT ON ALL TABLES IN SCHEMA PAWCORE_ANALYTICS.MANUFACTURING TO ROLE PUBLIC;
GRANT SELECT ON ALL TABLES IN SCHEMA PAWCORE_ANALYTICS.SUPPORT TO ROLE PUBLIC;
GRANT SELECT ON ALL TABLES IN SCHEMA PAWCORE_ANALYTICS.UNSTRUCTURED TO ROLE PUBLIC;

GRANT USAGE ON WAREHOUSE PAWCORE_DEMO_WH TO ROLE PAWCORE_ANALYST;
GRANT USAGE ON DATABASE PAWCORE_ANALYTICS TO ROLE PAWCORE_ANALYST;
GRANT USAGE ON ALL SCHEMAS IN DATABASE PAWCORE_ANALYTICS TO ROLE PAWCORE_ANALYST;
GRANT SELECT ON ALL TABLES IN DATABASE PAWCORE_ANALYTICS TO ROLE PAWCORE_ANALYST;
GRANT USAGE ON CORTEX SEARCH SERVICE PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DOCUMENT_SEARCH TO ROLE PAWCORE_ANALYST;

GRANT USAGE ON WAREHOUSE PAWCORE_DEMO_WH TO ROLE PAWCORE_SEARCH;
GRANT USAGE ON DATABASE PAWCORE_ANALYTICS TO ROLE PAWCORE_SEARCH;
GRANT USAGE ON SCHEMA PAWCORE_ANALYTICS.SEMANTIC TO ROLE PAWCORE_SEARCH;
GRANT USAGE ON SCHEMA PAWCORE_ANALYTICS.UNSTRUCTURED TO ROLE PAWCORE_SEARCH;
GRANT USAGE ON SCHEMA PAWCORE_ANALYTICS.DEVICE_DATA TO ROLE PAWCORE_SEARCH;
GRANT USAGE ON SCHEMA PAWCORE_ANALYTICS.MANUFACTURING TO ROLE PAWCORE_SEARCH;
GRANT USAGE ON SCHEMA PAWCORE_ANALYTICS.SUPPORT TO ROLE PAWCORE_SEARCH;
GRANT USAGE ON CORTEX SEARCH SERVICE PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DOCUMENT_SEARCH TO ROLE PAWCORE_SEARCH;
GRANT SELECT ON TABLE PAWCORE_ANALYTICS.UNSTRUCTURED.PARSED_CONTENT TO ROLE PAWCORE_SEARCH;
GRANT SELECT ON ALL TABLES IN SCHEMA PAWCORE_ANALYTICS.DEVICE_DATA TO ROLE PAWCORE_SEARCH;
GRANT SELECT ON ALL TABLES IN SCHEMA PAWCORE_ANALYTICS.MANUFACTURING TO ROLE PAWCORE_SEARCH;
GRANT SELECT ON ALL TABLES IN SCHEMA PAWCORE_ANALYTICS.SUPPORT TO ROLE PAWCORE_SEARCH;
GRANT SELECT ON ALL TABLES IN SCHEMA PAWCORE_ANALYTICS.UNSTRUCTURED TO ROLE PAWCORE_SEARCH;

-- ========================================================================
-- SCALE WAREHOUSE BACK DOWN
-- ========================================================================

ALTER WAREHOUSE PAWCORE_DEMO_WH SET WAREHOUSE_SIZE = 'XSMALL';

-- ========================================================================
-- FINAL VERIFICATION
-- ========================================================================

SELECT 'Data Loading Summary' as section;

SELECT 'TELEMETRY' as table_name, COUNT(*) as row_count FROM DEVICE_DATA.TELEMETRY
UNION ALL
SELECT 'QUALITY_LOGS' as table_name, COUNT(*) as row_count FROM MANUFACTURING.QUALITY_LOGS
UNION ALL
SELECT 'CUSTOMER_REVIEWS' as table_name, COUNT(*) as row_count FROM SUPPORT.CUSTOMER_REVIEWS
UNION ALL
SELECT 'SLACK_MESSAGES' as table_name, COUNT(*) as row_count FROM SUPPORT.SLACK_MESSAGES
UNION ALL
SELECT 'PARSED_CONTENT' as table_name, COUNT(*) as row_count FROM UNSTRUCTURED.PARSED_CONTENT
UNION ALL
SELECT 'IMAGE_FILES' as table_name, COUNT(*) as row_count FROM UNSTRUCTURED.IMAGE_FILES;

SELECT 'CoCo_PawCore Setup Complete!' as status,
       'Warehouse: PAWCORE_DEMO_WH (XSMALL)' as warehouse_info,
       'Database: PAWCORE_ANALYTICS' as database_info,
       'Cortex Search: PAWCORE_DOCUMENT_SEARCH' as search_service,
       'Ready for CoCo Hands-On Labs - Semantic View will be created live!' as next_steps;
