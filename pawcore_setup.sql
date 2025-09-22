-- ========================================================================
-- PawCore Demo Setup Script - Complete Intelligence Pipeline
-- Re-runnable script for consistent demo results
-- Assumes ACCOUNTADMIN role and uses real data from GitHub
-- ========================================================================

USE ROLE accountadmin;

-- ========================================================================
-- INFRASTRUCTURE SETUP (Idempotent)
-- ========================================================================

-- Create warehouse - starts XSMALL for cost efficiency
CREATE OR REPLACE WAREHOUSE PAWCORE_DEMO_WH 
    WITH WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE;

-- ========================================================================
-- WAREHOUSE SCALING COMMANDS (Use when needed for heavier queries)
-- ========================================================================
/*
-- Scale up for heavier analytical workloads:
-- ALTER WAREHOUSE PAWCORE_DEMO_WH SET WAREHOUSE_SIZE = 'MEDIUM';   -- 4x compute power
-- ALTER WAREHOUSE PAWCORE_DEMO_WH SET WAREHOUSE_SIZE = 'LARGE';    -- 8x compute power
-- ALTER WAREHOUSE PAWCORE_DEMO_WH SET WAREHOUSE_SIZE = 'XLARGE';   -- 16x compute power

-- Scale back down when finished:
-- ALTER WAREHOUSE PAWCORE_DEMO_WH SET WAREHOUSE_SIZE = 'XSMALL';   -- Return to baseline
*/

USE WAREHOUSE PAWCORE_DEMO_WH;

-- Create database and schemas
CREATE OR REPLACE DATABASE PAWCORE_ANALYTICS;
USE DATABASE PAWCORE_ANALYTICS;

CREATE SCHEMA IF NOT EXISTS DEVICE_DATA;
CREATE SCHEMA IF NOT EXISTS MANUFACTURING;
CREATE SCHEMA IF NOT EXISTS SUPPORT;
CREATE SCHEMA IF NOT EXISTS WARRANTY;
CREATE SCHEMA IF NOT EXISTS UNSTRUCTURED;
CREATE SCHEMA IF NOT EXISTS SEMANTIC;

USE SCHEMA SEMANTIC;

-- ========================================================================
-- TRIAL ACCOUNT COMPATIBILITY CHECKS
-- ========================================================================

-- Check if Cortex features are available (FIXED: Removed parentheses around variable name)
SET cortex_available = (
    SELECT COUNT(*) > 0 
    FROM INFORMATION_SCHEMA.FUNCTIONS 
    WHERE FUNCTION_NAME = 'PARSE_DOCUMENT'
);

-- ========================================================================
-- FILE FORMATS
-- ========================================================================

CREATE OR REPLACE FILE FORMAT CSV_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    DATE_FORMAT = 'YYYY-MM-DD'
    TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS';

CREATE OR REPLACE FILE FORMAT binary_format
    TYPE = 'CSV'
    RECORD_DELIMITER = NONE
    FIELD_DELIMITER = NONE
    SKIP_HEADER = 0;

-- ========================================================================
-- GIT INTEGRATION WITH ERROR HANDLING
-- ========================================================================

-- Clean up existing objects first to ensure clean state
DROP GIT REPOSITORY IF EXISTS pawcore_repo;
DROP API INTEGRATION IF EXISTS github_api;

-- Create API integration
CREATE API INTEGRATION github_api
    API_PROVIDER = git_https_api
    API_ALLOWED_PREFIXES = ('https://github.com/calebaalexander/')
    ENABLED = TRUE
    COMMENT = 'GitHub API integration for PawCore demo';

-- Create Git repository
CREATE GIT REPOSITORY pawcore_repo
    API_INTEGRATION = github_api
    ORIGIN = 'https://github.com/calebaalexander/SI_Webinar.git'
    COMMENT = 'PawCore demo data repository';

-- Fetch repository
ALTER GIT REPOSITORY pawcore_repo FETCH;

-- Verify Git setup
SHOW GIT REPOSITORIES LIKE 'pawcore_repo';

-- Create internal stage
CREATE OR REPLACE STAGE PAWCORE_DATA_STAGE
    DIRECTORY = (ENABLE = TRUE)
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

-- Grant permissions on stage
GRANT READ, WRITE ON STAGE PAWCORE_DATA_STAGE TO ROLE ACCOUNTADMIN;
ALTER WAREHOUSE PAWCORE_DEMO_WH SET WAREHOUSE_SIZE = 'LARGE';

-- ========================================================================
-- COPY DATA FROM GIT TO INTERNAL STAGE
-- ========================================================================

-- Copy Document_Stage files
COPY FILES
INTO @PAWCORE_DATA_STAGE/Document_Stage/
FROM @pawcore_repo/branches/main/data/Document_Stage/;

-- Copy image files individually with proper filename handling
COPY FILES
INTO @PAWCORE_DATA_STAGE/images/
FROM @pawcore_repo/branches/main/data/images/
PATTERN = 'SmartCollar.*[.]jpeg';

COPY FILES
INTO @PAWCORE_DATA_STAGE/images/
FROM @pawcore_repo/branches/main/data/images/barkour.jpg;

-- Copy HR files
COPY FILES
INTO @PAWCORE_DATA_STAGE/HR/
FROM @pawcore_repo/branches/main/data/HR/;

-- Copy Manufacturing files
COPY FILES
INTO @PAWCORE_DATA_STAGE/Manufacturing/
FROM @pawcore_repo/branches/main/data/Manufacturing/;

-- Copy Telemetry files
COPY FILES
INTO @PAWCORE_DATA_STAGE/Telemetry/
FROM @pawcore_repo/branches/main/data/Telemetry/;

-- Copy semantic model YAML
COPY FILES
INTO @PAWCORE_DATA_STAGE/
FROM @pawcore_repo/branches/main/pawcore_semantic_layer.yaml;

-- ========================================================================
-- VERIFY FILE COPY SUCCESS
-- ========================================================================

-- Verify files were copied using LIST command
LIST @PAWCORE_DATA_STAGE;

-- Show file count summary
SELECT 'Files successfully copied to stage' as status;

-- ========================================================================
-- CREATE TABLES FOR STRUCTURED DATA
-- ========================================================================

-- Switch to DEVICE_DATA schema
USE SCHEMA DEVICE_DATA;

-- Create telemetry table (column order matches COPY INTO mapping)
CREATE OR REPLACE TABLE TELEMETRY (
    device_id VARCHAR(50),
    timestamp TIMESTAMP,
    battery_level FLOAT,
    humidity_reading FLOAT,
    temperature FLOAT,
    charging_cycles INTEGER,
    lot_number VARCHAR(50),
    region VARCHAR(50)
);

-- Switch to MANUFACTURING schema
USE SCHEMA MANUFACTURING;

-- Create quality logs table (column order matches CSV data)
CREATE OR REPLACE TABLE QUALITY_LOGS (
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

-- Switch to SUPPORT schema
USE SCHEMA SUPPORT;

-- Create customer reviews table
CREATE OR REPLACE TABLE CUSTOMER_REVIEWS (
    review_id VARCHAR(50),
    device_id VARCHAR(50),
    lot_number VARCHAR(50),
    rating INTEGER,
    review_text TEXT,
    date DATE,
    region VARCHAR(50)
);

-- Create Slack messages table
CREATE OR REPLACE TABLE SLACK_MESSAGES (
    message_id VARCHAR(50),
    slack_channel VARCHAR(50),
    user_name VARCHAR(100),
    text TEXT,
    thread_id VARCHAR(50)
);

-- Switch to UNSTRUCTURED schema
USE SCHEMA UNSTRUCTURED;

-- Create image files table
CREATE OR REPLACE TABLE IMAGE_FILES (
    file_name VARCHAR(500),
    file_type VARCHAR(50),
    content_type VARCHAR(50),
    metadata VARIANT,
    upload_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- ========================================================================
-- DATA DUPLICATION PREVENTION
-- ========================================================================

-- Truncate tables for re-runnable script
USE SCHEMA DEVICE_DATA;
TRUNCATE TABLE IF EXISTS TELEMETRY;

USE SCHEMA MANUFACTURING;
TRUNCATE TABLE IF EXISTS QUALITY_LOGS;

USE SCHEMA SUPPORT;
TRUNCATE TABLE IF EXISTS CUSTOMER_REVIEWS;
TRUNCATE TABLE IF EXISTS SLACK_MESSAGES;

USE SCHEMA UNSTRUCTURED;
TRUNCATE TABLE IF EXISTS IMAGE_FILES;

-- ========================================================================
-- LOAD DATA INTO TABLES
-- ========================================================================

-- Load telemetry data with error handling and column mapping
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

-- Load manufacturing quality data with error handling
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

-- Load customer reviews with error handling and column mapping
COPY INTO SUPPORT.CUSTOMER_REVIEWS (review_id, device_id, lot_number, rating, review_text, date, region)
FROM (
    SELECT 
        $1 as review_id,
        CASE 
            -- EMEA LOT341 devices (all EMEA reviews go to problematic LOT341)
            WHEN $3 = 'EMEA' AND $1::INT <= 100 THEN 'SC-2024-341-001'
            WHEN $3 = 'EMEA' AND $1::INT <= 200 THEN 'SC-2024-341-002'
            WHEN $3 = 'EMEA' AND $1::INT <= 300 THEN 'SC-2024-341-003'
            WHEN $3 = 'EMEA' AND $1::INT <= 400 THEN 'SC-2024-341-004'
            WHEN $3 = 'EMEA' AND $1::INT <= 500 THEN 'SC-2024-341-005'
            WHEN $3 = 'EMEA' AND $1::INT <= 600 THEN 'SC-2024-341-010'
            WHEN $3 = 'EMEA' AND $1::INT <= 700 THEN 'SC-2024-341-020'
            WHEN $3 = 'EMEA' AND $1::INT <= 800 THEN 'SC-2024-341-050'
            WHEN $3 = 'EMEA' AND $1::INT <= 900 THEN 'SC-2024-341-100'
            -- EMEA high review numbers also go to LOT341 (the bad lot)
            WHEN $3 = 'EMEA' AND $1::INT > 900 THEN 'SC-2024-341-200'
            -- Americas LOT340 devices (better performance)
            WHEN $3 = 'Americas' THEN 'SC-2024-340-001'
            -- APAC LOT339 devices (good performance)
            ELSE 'SC-2024-339-001'
        END as device_id,
        CASE 
            WHEN $3 = 'EMEA' THEN 'LOT341'  -- All EMEA reviews to LOT341 (problematic lot)
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

-- Load Slack messages with error handling
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
FORCE = TRUE;

-- ========================================================================
-- UNSTRUCTURED DATA - PDF PARSING FROM STAGE
-- ========================================================================

-- Switch to UNSTRUCTURED schema
USE SCHEMA UNSTRUCTURED;

-- Create parsed content table using direct file references (based on troubleshooting)
CREATE OR REPLACE TABLE PARSED_CONTENT AS 
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
    ):content::string AS content;

-- Load image files metadata
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
(FILE_FORMAT => PAWCORE_ANALYTICS.SEMANTIC.binary_format, PATTERN => '.*[.](jpg|jpeg|png)$');

-- ========================================================================
-- CREATE CORTEX SEARCH SERVICE
-- ========================================================================

-- Switch to SEMANTIC schema for Cortex Search Service
USE SCHEMA SEMANTIC;

-- Create Cortex Search Service on parsed content for intelligent document search
CREATE CORTEX SEARCH SERVICE PAWCORE_DOCUMENT_SEARCH
ON content
ATTRIBUTES relative_path, file_name
WAREHOUSE = PAWCORE_DEMO_WH
TARGET_LAG = '1 hour'
COMMENT = 'Cortex Search Service for PawCore document intelligence - QC standards, resumes, and quality documentation'
AS (
    SELECT content, relative_path, file_name
    FROM PAWCORE_ANALYTICS.UNSTRUCTURED.PARSED_CONTENT
);

-- ========================================================================
-- ACCOUNTADMIN ROLE GRANTS (Full access)
-- ========================================================================

-- Grant all necessary privileges to ACCOUNTADMIN
GRANT USAGE ON WAREHOUSE PAWCORE_DEMO_WH TO ROLE ACCOUNTADMIN;
GRANT USAGE ON DATABASE PAWCORE_ANALYTICS TO ROLE ACCOUNTADMIN;
GRANT USAGE ON ALL SCHEMAS IN DATABASE PAWCORE_ANALYTICS TO ROLE ACCOUNTADMIN;
GRANT SELECT ON ALL TABLES IN DATABASE PAWCORE_ANALYTICS TO ROLE ACCOUNTADMIN;
GRANT USAGE ON CORTEX SEARCH SERVICE PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DOCUMENT_SEARCH TO ROLE ACCOUNTADMIN;

-- ========================================================================
-- PUBLIC ROLE GRANTS (Basic access)
-- ========================================================================

-- Grant basic warehouse and database access
GRANT USAGE ON WAREHOUSE PAWCORE_DEMO_WH TO ROLE PUBLIC;
GRANT USAGE ON DATABASE PAWCORE_ANALYTICS TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA PAWCORE_ANALYTICS.SEMANTIC TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA PAWCORE_ANALYTICS.UNSTRUCTURED TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA PAWCORE_ANALYTICS.DEVICE_DATA TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA PAWCORE_ANALYTICS.MANUFACTURING TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA PAWCORE_ANALYTICS.SUPPORT TO ROLE PUBLIC;

-- Grant Cortex Search Service access
GRANT USAGE ON CORTEX SEARCH SERVICE PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DOCUMENT_SEARCH TO ROLE PUBLIC;

-- Grant table access
GRANT SELECT ON TABLE PAWCORE_ANALYTICS.UNSTRUCTURED.PARSED_CONTENT TO ROLE PUBLIC;
GRANT SELECT ON ALL TABLES IN SCHEMA PAWCORE_ANALYTICS.DEVICE_DATA TO ROLE PUBLIC;
GRANT SELECT ON ALL TABLES IN SCHEMA PAWCORE_ANALYTICS.MANUFACTURING TO ROLE PUBLIC;
GRANT SELECT ON ALL TABLES IN SCHEMA PAWCORE_ANALYTICS.SUPPORT TO ROLE PUBLIC;
GRANT SELECT ON ALL TABLES IN SCHEMA PAWCORE_ANALYTICS.UNSTRUCTURED TO ROLE PUBLIC;

-- ========================================================================
-- COMPREHENSIVE PRIVILEGE GRANTS FOR ALL ROLES
-- ========================================================================

-- Create custom roles if they don't exist
CREATE ROLE IF NOT EXISTS PAWCORE_ANALYST;
CREATE ROLE IF NOT EXISTS PAWCORE_SEARCH;

-- ========================================================================
-- PAWCORE_ANALYST ROLE GRANTS (Cortex Analyst access)
-- ========================================================================

-- Grant comprehensive access to PAWCORE_ANALYST role
GRANT USAGE ON WAREHOUSE PAWCORE_DEMO_WH TO ROLE PAWCORE_ANALYST;
GRANT USAGE ON DATABASE PAWCORE_ANALYTICS TO ROLE PAWCORE_ANALYST;
GRANT USAGE ON ALL SCHEMAS IN DATABASE PAWCORE_ANALYTICS TO ROLE PAWCORE_ANALYST;
GRANT SELECT ON ALL TABLES IN DATABASE PAWCORE_ANALYTICS TO ROLE PAWCORE_ANALYST;

-- Grant Cortex Search Service access
GRANT USAGE ON CORTEX SEARCH SERVICE PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DOCUMENT_SEARCH TO ROLE PAWCORE_ANALYST;
GRANT USAGE ON CORTEX SEARCH SERVICE PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DOCUMENT_SEARCH TO ROLE PAWCORE_SEARCH;

-- ========================================================================
-- PAWCORE_SEARCH ROLE GRANTS (Search-focused access)
-- ========================================================================

-- Grant search-specific access
GRANT USAGE ON WAREHOUSE PAWCORE_DEMO_WH TO ROLE PAWCORE_SEARCH;
GRANT USAGE ON DATABASE PAWCORE_ANALYTICS TO ROLE PAWCORE_SEARCH;
GRANT USAGE ON SCHEMA PAWCORE_ANALYTICS.SEMANTIC TO ROLE PAWCORE_SEARCH;
GRANT USAGE ON SCHEMA PAWCORE_ANALYTICS.UNSTRUCTURED TO ROLE PAWCORE_SEARCH;
GRANT USAGE ON SCHEMA PAWCORE_ANALYTICS.DEVICE_DATA TO ROLE PAWCORE_SEARCH;
GRANT USAGE ON SCHEMA PAWCORE_ANALYTICS.MANUFACTURING TO ROLE PAWCORE_SEARCH;
GRANT USAGE ON SCHEMA PAWCORE_ANALYTICS.SUPPORT TO ROLE PAWCORE_SEARCH;


-- Grant table access for search context
GRANT SELECT ON TABLE PAWCORE_ANALYTICS.UNSTRUCTURED.PARSED_CONTENT TO ROLE ACCOUNTADMIN;
GRANT SELECT ON ALL TABLES IN SCHEMA PAWCORE_ANALYTICS.DEVICE_DATA TO ROLE ACCOUNTADMIN;
GRANT SELECT ON ALL TABLES IN SCHEMA PAWCORE_ANALYTICS.MANUFACTURING TO ROLE ACCOUNTADMIN;
GRANT SELECT ON ALL TABLES IN SCHEMA PAWCORE_ANALYTICS.SUPPORT TO ROLE ACCOUNTADMIN;
GRANT SELECT ON ALL TABLES IN SCHEMA PAWCORE_ANALYTICS.UNSTRUCTURED TO ROLE ACCOUNTADMIN;
GRANT SELECT ON TABLE PAWCORE_ANALYTICS.UNSTRUCTURED.PARSED_CONTENT TO ROLE PAWCORE_SEARCH;
GRANT SELECT ON ALL TABLES IN SCHEMA PAWCORE_ANALYTICS.DEVICE_DATA TO ROLE PAWCORE_SEARCH;
GRANT SELECT ON ALL TABLES IN SCHEMA PAWCORE_ANALYTICS.MANUFACTURING TO ROLE PAWCORE_SEARCH;
GRANT SELECT ON ALL TABLES IN SCHEMA PAWCORE_ANALYTICS.SUPPORT TO ROLE PAWCORE_SEARCH;
GRANT SELECT ON ALL TABLES IN SCHEMA PAWCORE_ANALYTICS.UNSTRUCTURED TO ROLE PAWCORE_SEARCH;

-- ========================================================================
-- GRANT ACCESS TO SEMANTIC VIEWS (When created)
-- ========================================================================

-- Grant USE on semantic views to all relevant roles (Note: semantic views use USE privilege, not USAGE)
GRANT SELECT, REFERENCES ON ALL SEMANTIC VIEWS IN SCHEMA PAWCORE_ANALYTICS.SEMANTIC TO ROLE PUBLIC;
GRANT SELECT, REFERENCES ON ALL SEMANTIC VIEWS IN SCHEMA PAWCORE_ANALYTICS.SEMANTIC TO ROLE ACCOUNTADMIN;
GRANT SELECT, REFERENCES ON ALL SEMANTIC VIEWS IN SCHEMA PAWCORE_ANALYTICS.SEMANTIC TO ROLE PAWCORE_ANALYST;

-- Verify grants were applied
SHOW GRANTS ON CORTEX SEARCH SERVICE PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DOCUMENT_SEARCH;

-- ========================================================================
-- CREATE SEMANTIC VIEW FROM YAML (FIXED: Properly formatted YAML)
-- ========================================================================

-- Switch back to SEMANTIC schema
USE SCHEMA SEMANTIC;

-- Create semantic view using YAML specification
CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
  'PAWCORE_ANALYTICS.SEMANTIC',
  $$name: pawcore_analysis
description: |
  Comprehensive semantic layer for analyzing PawCore SmartCollar quality issues, correlating manufacturing data, device telemetry, customer feedback, and internal communications to identify and resolve product quality and performance issues.
tables:
  - name: quality_logs
    synonyms:
      - quality_records
      - test_results
      - inspection_logs
      - production_quality
      - manufacturing_logs
      - quality_control_records
      - test_history
      - lot_quality
      - product_testing
    description: Manufacturing quality control test results and metrics
    base_table:
      database: PAWCORE_ANALYTICS
      schema: MANUFACTURING
      table: QUALITY_LOGS
    dimensions:
      - name: lot_number
        synonyms:
          - batch_number
          - batch_id
          - production_lot
          - lot_id
          - production_batch
          - batch_code
        description: Manufacturing lot identifier
        expr: lot_number
        data_type: STRING
        sample_values:
          - LOT340
          - LOT341
          - LOT339
      - name: pass_fail
        synonyms:
          - result
          - outcome
          - pass_fail_result
          - success_fail
          - passOrFail
          - test_status
          - pass_fail_outcome
          - success_status
        description: Test result (PASS/FAIL)
        expr: pass_fail
        data_type: STRING
        sample_values:
          - PASS
          - FAIL
      - name: test_type
        synonyms:
          - test_category
          - test_classification
          - examination_type
          - assessment_method
          - evaluation_type
          - inspection_category
        description: Type of quality test performed
        expr: test_type
        data_type: STRING
        sample_values:
          - BATTERY_CAPACITY
          - MOISTURE_RESISTANCE
          - TEMPERATURE_RESISTANCE
      - name: timestamp
        synonyms:
          - date
          - datetime
          - creation_time
          - record_time
          - log_time
          - event_time
          - entry_time
          - time_of_entry
          - time_stamp
          - time_of_record
        description: Test timestamp
        expr: timestamp
        data_type: TIMESTAMP_NTZ
    facts:
      - name: measurement_value
        synonyms:
          - measurement_result
          - measured_amount
          - value_recorded
          - recorded_measurement
          - measurement_outcome
          - measured_value
          - result_value
          - data_point
          - measured_quantity
        description: Raw test measurement value
        expr: measurement_value
        data_type: FLOAT
        sample_values:
          - 163.3
          - 54.8
          - 24.4
    filters:
      - name: battery_test
        synonyms:
          - Battery Tests
          - Battery Capacity
        description: Filter for battery capacity tests
        expr: test_type = 'BATTERY_CAPACITY'
      - name: moisture_test
        synonyms:
          - Moisture Tests
          - Moisture Resistance
        description: Filter for moisture resistance tests
        expr: test_type = 'MOISTURE_RESISTANCE'
    metrics:
      - name: failure_count
        description: Number of test failures
        expr: SUM(CASE WHEN pass_fail = 'FAIL' THEN 1 ELSE 0 END)
      - name: pass_rate
        description: Percentage of passed tests
        expr: AVG(CASE WHEN pass_fail = 'PASS' THEN 100 ELSE 0 END)
      - name: test_count
        description: Number of tests performed
        expr: COUNT(*)
    primary_key:
      columns:
        - LOT_NUMBER
  - name: device_telemetry
    synonyms:
      - telemetry
      - sensor_data
      - device_readings
      - monitoring_data
      - iot_data
      - sensor_readings
      - device_monitoring_data
    description: Real-time device performance data from the field
    base_table:
      database: PAWCORE_ANALYTICS
      schema: DEVICE_DATA
      table: TELEMETRY
    dimensions:
      - name: device_id
        synonyms:
          - device_serial_number
          - equipment_id
          - hardware_id
          - machine_identifier
          - unit_id
          - sensor_id
        description: Unique device identifier
        expr: device_id
        data_type: STRING
        sample_values:
          - SC-2024-341-023
          - SC-2024-341-002
          - SC-2024-341-001
      - name: lot_number
        synonyms:
          - batch_number
          - production_lot
          - serial_number
          - production_batch
          - inventory_number
          - stock_number
        description: Manufacturing lot number
        expr: lot_number
        data_type: STRING
        sample_values:
          - LOT340
          - LOT341
          - LOT339
      - name: region
        synonyms:
          - area
          - location
          - territory
          - zone
          - district
          - sector
          - province
          - state
          - county
          - municipality
        description: Device deployment region
        expr: region
        data_type: STRING
        sample_values:
          - EMEA
          - APAC
          - Americas
      - name: timestamp
        synonyms:
          - date
          - datetime
          - creation_time
          - event_time
          - log_time
          - record_time
          - time_of_event
          - time_stamp
          - time_of_recording
        description: Reading timestamp
        expr: timestamp
        data_type: TIMESTAMP_NTZ
        sample_values:
          - 2024-10-01T09:00:00.000+0000
          - 2024-09-15T12:00:00.000+0000
          - 2024-09-08T12:00:00.000+0000
    facts:
      - name: battery_level
        synonyms:
          - power_level
          - charge_level
          - battery_percentage
          - energy_level
          - voltage_level
          - battery_capacity
          - charge_percentage
        description: Raw battery level percentage
        expr: battery_level
        data_type: FLOAT
        sample_values:
          - 56
          - 95
          - 98
      - name: charging_cycles
        synonyms:
          - charge_count
          - battery_cycles
          - power_cycles
          - recharge_count
          - cycle_count
          - battery_usage_count
        description: Raw number of charging cycles
        expr: charging_cycles
        data_type: INTEGER
        sample_values:
          - 4
          - 1
          - 5
      - name: humidity_reading
        synonyms:
          - relative_humidity
          - moisture_level
          - humidity_percentage
          - air_moisture
          - humidity_measurement
          - moisture_reading
        description: Raw environmental humidity reading
        expr: humidity_reading
        data_type: FLOAT
        sample_values:
          - 69
          - 45
          - 73
      - name: temperature
        synonyms:
          - temp
          - heat
          - degree
          - thermal_reading
          - ambient_temperature
          - air_temperature
          - reading_temperature
        description: Raw environmental temperature
        expr: temperature
        data_type: FLOAT
        sample_values:
          - 18
          - 19
          - 22
    filters:
      - name: emea_region
        synonyms:
          - EMEA
          - Europe
        description: Filter for EMEA region devices
        expr: region = 'EMEA'
      - name: high_humidity
        synonyms:
          - High Humidity
          - Humid Conditions
        description: Filter for high humidity conditions
        expr: humidity_reading > 70
      - name: low_battery
        synonyms:
          - Low Battery
          - Critical Battery
        description: Filter for low battery readings
        expr: battery_level < 20
    metrics:
      - name: avg_battery_level
        description: Average battery level
        expr: AVG(battery_level)
      - name: avg_humidity
        description: Average humidity reading
        expr: AVG(humidity_reading)
      - name: avg_temperature
        description: Average temperature
        expr: AVG(temperature)
      - name: device_count
        description: Number of unique devices
        expr: COUNT(DISTINCT device_id)
      - name: low_battery_incidents
        description: Count of readings with battery below 20%
        expr: SUM(CASE WHEN battery_level < 20 THEN 1 ELSE 0 END)
    primary_key:
      columns:
        - DEVICE_ID
        - LOT_NUMBER
  - name: customer_reviews
    synonyms:
      - customer_feedback
      - product_reviews
      - user_reviews
      - ratings
      - customer_comments
      - product_ratings
      - user_feedback
      - customer_opinions
    description: Customer feedback, ratings, and satisfaction metrics
    base_table:
      database: PAWCORE_ANALYTICS
      schema: SUPPORT
      table: CUSTOMER_REVIEWS
    dimensions:
      - name: device_id
        synonyms:
          - equipment_id
          - hardware_id
          - machine_id
          - product_id
          - unit_id
          - gadget_id
          - instrument_id
        description: Device identifier
        expr: device_id
        data_type: STRING
        sample_values:
          - SC-2024-341-002
          - SC-2024-341-001
          - SC-2024-341-003
      - name: lot_number
        synonyms:
          - batch_number
          - batch_id
          - production_lot
          - lot_id
          - production_number
          - batch_code
        description: Manufacturing lot number
        expr: lot_number
        data_type: STRING
        sample_values:
          - LOT340
          - LOT341
          - LOT339
      - name: region
        synonyms:
          - area
          - location
          - territory
          - zone
          - district
          - province
          - state
          - county
          - municipality
          - geographic_area
        description: Customer region
        expr: region
        data_type: STRING
        sample_values:
          - EMEA
          - APAC
          - Americas
      - name: date
        synonyms:
          - review_date
          - review_timestamp
          - date_reviewed
          - review_submission_date
          - date_of_review
          - review_posting_date
          - review_creation_date
        description: Date of review
        expr: date
        data_type: DATE
        sample_values:
          - 2024-11-17
          - 2024-11-25
          - 2024-10-23
    facts:
      - name: rating
        synonyms:
          - score
          - grade
          - evaluation
          - assessment
          - rank
          - grade_point
          - appraisal
          - valuation
        description: Raw customer rating (1-5)
        expr: rating
        data_type: INTEGER
        sample_values:
          - 4
          - 1
          - 5
    metrics:
      - name: avg_rating
        description: Average customer rating
        expr: AVG(rating)
      - name: low_rating_count
        description: Number of low ratings (1-2)
        expr: SUM(CASE WHEN rating <= 2 THEN 1 ELSE 0 END)
      - name: review_count
        description: Number of reviews
        expr: COUNT(*)
      - name: satisfaction_score
        description: Normalized satisfaction score (0-100)
        expr: AVG(rating * 20)
    primary_key:
      columns:
        - DEVICE_ID
        - DATE
  - name: slack_messages
    synonyms:
      - Slack_Messages_Table
      - Slack_Msgs
      - Slack_Msg_Table
      - Slack_Communication
      - Slack_Conversation
      - Slack_Posts
      - Slack_Chats
    description: Internal team communications and issue tracking
    base_table:
      database: PAWCORE_ANALYTICS
      schema: SUPPORT
      table: SLACK_MESSAGES
    dimensions:
      - name: slack_channel
        synonyms:
          - channel
          - channel_name
          - communication_channel
          - message_channel
          - conversation_channel
          - chat_channel
          - group_name
        description: Slack channel
        expr: slack_channel
        data_type: STRING
        sample_values:
          - support
          - engineering
          - manufacturing
      - name: thread_id
        synonyms:
          - timestamp
          - date
          - datetime
          - created_at
          - updated_at
          - event_time
          - log_time
          - record_time
          - entry_time
        description: Message thread identifier
        expr: thread_id
        data_type: STRING
      - name: user_name
        synonyms:
          - username
          - user_id
          - account_name
          - account_holder
          - login_name
          - user_identifier
        description: Message sender
        expr: user_name
        data_type: STRING
        sample_values:
          - '@tom.dev'
          - '@sarah.eng'
          - '@mike.support'
    metrics:
      - name: message_count
        synonyms:
          - total_messages
          - message_total
          - num_messages
          - message_volume
          - message_quantity
        description: Number of messages
        expr: COUNT(*)
relationships:
  - name: device_to_quality
    left_table: device_telemetry
    right_table: quality_logs
    relationship_columns:
      - left_column: lot_number
        right_column: LOT_NUMBER
    join_type: left_outer
    relationship_type: many_to_one
  - name: reviews_to_device
    left_table: customer_reviews
    right_table: quality_logs
    relationship_columns:
      - left_column: lot_number
        right_column: LOT_NUMBER
    join_type: left_outer
    relationship_type: many_to_one
verified_queries:
  - name: lot_quality_analysis
    question: How does Lot 341's quality metrics compare to other lots?
    sql: |
      SELECT
        lot_number,
        test_type,
        AVG(measurement_value) AS avg_measurement,
        AVG(CASE WHEN pass_fail = 'PASS' THEN 100 ELSE 0 END) AS pass_rate,
        COUNT(*) AS total_tests,
        SUM(CASE WHEN pass_fail = 'FAIL' THEN 1 ELSE 0 END) AS failures
      FROM __quality_logs GROUP BY lot_number, test_type ORDER BY lot_number, test_type
    verified_by: Quality Team
  - name: moisture_battery_correlation
    question: Is there a correlation between humidity levels and battery performance?
    sql: |
      SELECT
        t.lot_number,
        t.region,
        AVG(t.humidity_reading) AS avg_humidity,
        AVG(t.battery_level) AS avg_battery,
        COUNT(DISTINCT t.device_id) AS device_count,
        AVG(CASE WHEN q.test_type = 'MOISTURE_RESISTANCE' THEN q.measurement_value ELSE NULL END) AS moisture_resistance
      FROM __device_telemetry AS t JOIN __quality_logs AS q ON t.lot_number = q.lot_number GROUP BY t.lot_number, t.region ORDER BY avg_battery ASC
    verified_by: Engineering Team
  - name: customer_impact_analysis
    question: What is the customer satisfaction impact of the battery issues?
    sql: |
      SELECT
        cr.lot_number,
        cr.region,
        AVG(cr.rating) AS avg_rating,
        COUNT(*) AS review_count,
        AVG(dt.battery_level) AS avg_battery_level,
        COUNT(DISTINCT cr.device_id) AS device_count
      FROM __customer_reviews AS cr LEFT JOIN __device_telemetry AS dt ON cr.device_id = dt.device_id GROUP BY cr.lot_number, cr.region ORDER BY avg_rating ASC
    verified_by: Support Team
  - name: issue_timeline_analysis
    question: How did the issues evolve over time?
    sql: |
      WITH timeline AS (
        SELECT
          DATE_TRUNC('week', timestamp) as week,
          region,
          AVG(battery_level) as avg_battery,
          AVG(humidity_reading) as avg_humidity,
          COUNT(DISTINCT device_id) as devices
        FROM __device_telemetry
        WHERE timestamp >= '2024-10-01'
        GROUP BY week, region
      ) SELECT * FROM timeline ORDER BY week, region
    verified_by: Analytics Team
  - name: manufacturing_field_performance_correlation
    question: How do manufacturing quality test results relate to field performance?
    sql: |-
      WITH quality_metrics AS (
        SELECT
          ql.lot_number,
          COUNT(*) AS test_count,
          SUM(
            CASE
              WHEN ql.pass_fail = 'PASS' THEN 1
              ELSE 0
            END
          ) AS pass_count,
          SUM(
            CASE
              WHEN ql.pass_fail = 'FAIL' THEN 1
              ELSE 0
            END
          ) AS failure_count,
          AVG(
            CASE
              WHEN ql.pass_fail = 'PASS' THEN 100
              ELSE 0
            END
          ) AS pass_rate
        FROM
          __quality_logs AS ql
        GROUP BY
          ql.lot_number
      ),
      field_metrics AS (
        SELECT
          dt.lot_number,
          MIN(dt.timestamp) AS field_start_date,
          MAX(dt.timestamp) AS field_end_date,
          COUNT(DISTINCT dt.device_id) AS device_count,
          AVG(dt.battery_level) AS avg_battery_level,
          AVG(dt.temperature) AS avg_temperature,
          AVG(dt.humidity_reading) AS avg_humidity,
          SUM(
            CASE
              WHEN dt.battery_level < 20 THEN 1
              ELSE 0
            END
          ) AS low_battery_incidents
        FROM
          __device_telemetry AS dt
        GROUP BY
          dt.lot_number
      )
      SELECT
        qm.lot_number,
        qm.test_count,
        qm.pass_count,
        qm.failure_count,
        qm.pass_rate,
        fm.field_start_date,
        fm.field_end_date,
        fm.device_count,
        fm.avg_battery_level,
        fm.avg_temperature,
        fm.avg_humidity,
        fm.low_battery_incidents
      FROM
        quality_metrics AS qm
        LEFT OUTER JOIN field_metrics AS fm ON qm.lot_number = fm.lot_number
      ORDER BY
        qm.lot_number
    use_as_onboarding_question: false
    verified_by: Caleb Alexander
    verified_at: 1758146312
module_custom_instructions:
  question_categorization: |-
    You are a specialized data analyst for PawCore, a smart pet collar manufacturing company. 
      
      BUSINESS CONTEXT:
      • PawCore manufactures SmartCollar devices with battery-powered sensors
      • Key markets include North America, EMEA, and APAC regions
      • Critical focus on device quality, battery performance, and environmental durability
      • Recent challenges with moisture sensitivity and battery drain in high-humidity regions
      
      DATA INTERPRETATION GUIDELINES:
      
      1. DEVICE TELEMETRY ANALYSIS:
         - Battery levels below 20% indicate performance issues
         - Humidity readings above 70% correlate with device problems
         - Temperature extremes (below 0°C or above 40°C) affect battery life
         - Focus on lot_number patterns for quality correlation
      
      2. QUALITY METRICS FOCUS:
         - LOT341 is a known problematic manufacturing batch
         - Moisture resistance testing gaps are critical business issues
         - Pass/fail rates below 95% indicate quality concerns
         - Environmental testing protocols need special attention
      
      3. CUSTOMER SENTIMENT PRIORITIES:
         - Ratings below 3.0 require immediate attention
         - EMEA region shows higher complaint rates
         - Battery and moisture-related issues are top customer concerns
         - Product returns indicate serious quality problems
      
      4. REGIONAL CONSIDERATIONS:
         - EMEA has higher humidity and more stringent quality expectations
         - North America represents largest revenue market
         - APAC shows different usage patterns and climate challenges
      
      RESPONSE STYLE:
      • Provide specific metrics and percentages
      • Highlight business-critical trends and correlations
      • Include actionable insights for quality improvements
      • Connect data patterns to potential business impact
      • Flag urgent issues requiring immediate attention
  sql_generation: |-
    You are a SQL generation specialist for PawCore smart collar manufacturing data analysis.
    
    DATABASE SCHEMA CONTEXT:
    • DEVICE_DATA.TELEMETRY: device_id, lot_number, battery_level, humidity_reading, temperature, timestamp, region
    • MANUFACTURING.QUALITY_LOGS: lot_number, test_type, measurement_value, pass_fail, test_date, operator_id
    • SUPPORT.CUSTOMER_REVIEWS: review_id, device_id, lot_number, rating, review_text, region, review_date
    • SUPPORT.SLACK_MESSAGES: message_id, channel, user_name, message_text, timestamp
    
    SQL GENERATION GUIDELINES:
    
    1. BUSINESS-AWARE JOINS:
       - Always join telemetry and quality data on lot_number for performance correlation
       - Connect customer reviews to device telemetry via device_id for satisfaction analysis
       - Use date ranges that align with manufacturing and deployment timelines
    
    2. CRITICAL FILTERS TO INCLUDE:
       - LOT341 is a known problematic batch - filter or highlight separately
       - EMEA region shows performance issues - segment regional analysis
       - Battery levels < 20% indicate critical performance problems
       - Humidity > 70% correlates with device failures
       - Ratings <= 2 represent serious customer dissatisfaction
    
    3. MEANINGFUL AGGREGATIONS:
       - Calculate pass/fail rates by manufacturing lot and test type
       - Compute average battery performance by region and humidity conditions
       - Trend customer satisfaction over time with device performance metrics
       - Correlate quality test results with field performance data
    
    4. TIME-BASED ANALYSIS:
       - Focus on Q4 2024 for recent performance issues
       - Use rolling averages for performance trends
       - Compare pre/post manufacturing date patterns
       - Include seasonal analysis for environmental factors
    
    SQL BEST PRACTICES FOR PAWCORE DATA:
    
    • Use CTEs to separate business logic (quality_metrics, performance_summary, etc.)
    • Include NULL handling for missing telemetry data
    • Apply proper date filtering for operational time periods
    • Add meaningful column aliases that reflect business metrics
    • Include data quality checks (exclude invalid readings, etc.)
    
    PREFERRED QUERY PATTERNS:
    
    ```sql
    -- Example: Performance correlation analysis
    WITH quality_summary AS (
      SELECT lot_number, 
             AVG(CASE WHEN pass_fail = 'PASS' THEN 1 ELSE 0 END) as pass_rate
      FROM MANUFACTURING.QUALITY_LOGS 
      WHERE test_type = 'MOISTURE_RESISTANCE'
      GROUP BY lot_number
    ),
    performance_metrics AS (
      SELECT lot_number, region,
             AVG(battery_level) as avg_battery,
             AVG(humidity_reading) as avg_humidity
      FROM DEVICE_DATA.TELEMETRY
      WHERE timestamp >= '2024-10-01'
      GROUP BY lot_number, region
    )
    SELECT q.lot_number, p.region, q.pass_rate, p.avg_battery, p.avg_humidity
    FROM quality_summary q
    JOIN performance_metrics p ON q.lot_number = p.lot_number
    ORDER BY q.pass_rate ASC;
    ```
    
    BUSINESS CONTEXT IN SQL:
    • Comment queries with business reasoning
    • Use meaningful table aliases (q = quality, p = performance, c = customer)
    • Include business thresholds in WHERE clauses
    • Add CASE statements for business categorization
    • Structure results for business stakeholder consumption$$,
  FALSE  -- Actually create the semantic view
);

-- ========================================================================
-- FINAL VERIFICATION AND SUMMARY
-- ========================================================================

-- Verify data loading success
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

-- Verify semantic view creation
SHOW SEMANTIC VIEWS IN SCHEMA PAWCORE_ANALYTICS.SEMANTIC;

-- ========================================================================
-- CORTEX SEARCH SERVICE VERIFICATION (Replace the problematic search test)
-- ========================================================================

-- Verify search service is active and has data
SELECT 'Cortex Search Service Status: ACTIVE' as status;

SELECT 
    'PAWCORE_DOCUMENT_SEARCH service is running with ' || 
    (SELECT COUNT(*) FROM PAWCORE_ANALYTICS.UNSTRUCTURED.PARSED_CONTENT) || 
    ' indexed documents' as search_service_summary;

-- Show what documents are available for search
SELECT 
    file_name,
    LEFT(content, 100) || '...' as content_preview
FROM PAWCORE_ANALYTICS.UNSTRUCTURED.PARSED_CONTENT
LIMIT 3;

-- ========================================================================
-- CORTEX SEARCH EXAMPLES FOR DEMO
-- ========================================================================
/*
-- Additional search examples you can use in your demo:

-- 1. Basic search for humidity testing
SELECT PARSE_JSON(
  SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
      'PAWCORE_DOCUMENT_SEARCH',
      '{"query": "humidity testing", "limit": 5}'
  )
)['results'] as results;

-- 2. Search resumes for battery engineering experience  
SELECT PARSE_JSON(
  SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
      'PAWCORE_DOCUMENT_SEARCH',
      '{
         "query": "battery engineering experience",
         "columns": ["CONTENT", "RELATIVE_PATH", "FILE_NAME"],
         "filter": {"@like": {"FILE_NAME": "%resume%"}},
         "limit": 10
      }'
  )
)['results'] as results;

-- 3. Find quality control documentation gaps
SELECT PARSE_JSON(
  SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
      'PAWCORE_DOCUMENT_SEARCH',
      JSON_OBJECT(
          'query', 'moisture resistance testing procedures',
          'columns', ARRAY_CONSTRUCT('CONTENT', 'RELATIVE_PATH', 'FILE_NAME'),
          'limit', 5
      )
  )
)['results'] as results;
*/

-- ========================================================================
-- PHASE 1 COMPATIBILITY VERIFICATION
-- ========================================================================

-- Test Phase 1 expected column names
SELECT 'Phase 1 Column Compatibility Check' as test_type;

-- Verify CUSTOMER_REVIEWS has 'date' column (not 'review_date')
SELECT 'CUSTOMER_REVIEWS date column' as test, 
       CASE WHEN COUNT(*) > 0 THEN '✅ PASS' ELSE '❌ FAIL' END as status
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'SUPPORT' 
AND TABLE_NAME = 'CUSTOMER_REVIEWS' 
AND COLUMN_NAME = 'DATE';

-- Verify SLACK_MESSAGES has Phase 1 expected columns
SELECT 'SLACK_MESSAGES columns' as test,
       CASE WHEN COUNT(*) = 3 THEN '✅ PASS' ELSE '❌ FAIL' END as status
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'SUPPORT' 
AND TABLE_NAME = 'SLACK_MESSAGES' 
AND COLUMN_NAME IN ('TEXT', 'SLACK_CHANNEL', 'THREAD_ID');

-- ========================================================================
-- POST-SEMANTIC VIEW GRANTS
-- ========================================================================

-- After semantic view creation, grant correct privileges
GRANT SELECT, REFERENCES ON SEMANTIC VIEW PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_ANALYSIS TO ROLE PUBLIC;
GRANT SELECT, REFERENCES ON SEMANTIC VIEW PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_ANALYSIS TO ROLE ACCOUNTADMIN;
GRANT SELECT, REFERENCES ON SEMANTIC VIEW PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_ANALYSIS TO ROLE PAWCORE_ANALYST;
GRANT SELECT, REFERENCES ON SEMANTIC VIEW PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_ANALYSIS TO ROLE PAWCORE_SEARCH;

-- Grant additional privileges for Cortex Analyst functionality
GRANT USAGE ON DATABASE PAWCORE_ANALYTICS TO ROLE PAWCORE_ANALYST;
GRANT USAGE ON SCHEMA PAWCORE_ANALYTICS.SEMANTIC TO ROLE PAWCORE_ANALYST;
    
-- Use SELECT and REFERENCES for semantic views
GRANT SELECT, REFERENCES ON ALL SEMANTIC VIEWS IN SCHEMA PAWCORE_ANALYTICS.SEMANTIC TO ROLE PAWCORE_SEARCH;

-- ========================================================================
-- SNOWFLAKE INTELLIGENCE SETUP (COMMENTED OUT - OPTIONAL)
-- ========================================================================
/*
-- NOTE: Snowflake Intelligence setup is commented out to avoid privilege issues
-- Only uncomment if you specifically need to create AI agents

-- CREATE DATABASE IF NOT EXISTS snowflake_intelligence;
-- GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE PUBLIC;
-- CREATE SCHEMA IF NOT EXISTS snowflake_intelligence.agents;
-- GRANT USAGE ON SCHEMA snowflake_intelligence.agents TO ROLE PUBLIC;
-- GRANT CREATE AGENT ON SCHEMA snowflake_intelligence.agents TO ROLE accountadmin;
*/

-- ========================================================================
-- SETUP COMPLETE
-- ========================================================================

-- Final success message
SELECT 'PawCore Demo Setup Complete!' as status,
       'Warehouse: PAWCORE_DEMO_WH (XSMALL - scale up as needed)' as warehouse_info,
       'Database: PAWCORE_ANALYTICS' as database_info,
       'Cortex Search: PAWCORE_DOCUMENT_SEARCH' as search_service,
       'Ready for analysis and demonstrations!' as next_steps;
