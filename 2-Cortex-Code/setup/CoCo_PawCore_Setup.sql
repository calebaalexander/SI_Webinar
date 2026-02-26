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

GRANT SELECT, REFERENCES ON ALL SEMANTIC VIEWS IN SCHEMA PAWCORE_ANALYTICS.SEMANTIC TO ROLE PUBLIC;
GRANT SELECT, REFERENCES ON ALL SEMANTIC VIEWS IN SCHEMA PAWCORE_ANALYTICS.SEMANTIC TO ROLE ACCOUNTADMIN;
GRANT SELECT, REFERENCES ON ALL SEMANTIC VIEWS IN SCHEMA PAWCORE_ANALYTICS.SEMANTIC TO ROLE PAWCORE_ANALYST;
GRANT SELECT, REFERENCES ON ALL SEMANTIC VIEWS IN SCHEMA PAWCORE_ANALYTICS.SEMANTIC TO ROLE PAWCORE_SEARCH;

-- ========================================================================
-- CREATE SEMANTIC VIEW (V2 Launch / CX Analysis focus)
-- ========================================================================
-- Note: This creates/replaces PAWCORE_ANALYSIS with CoCo HOL content.
-- The semantic view is the one CoCo-specific object that we intentionally
-- update — it now focuses on V2 launch readiness and CX analysis.

USE SCHEMA SEMANTIC;

CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
  'PAWCORE_ANALYTICS.SEMANTIC',
  $$name: pawcore_analysis
description: |
  Comprehensive semantic layer for PawCore SmartCollar analytics, supporting V2 launch readiness, customer experience analysis, regional performance comparison, and operational insights across manufacturing, telemetry, customer feedback, and internal communications.
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
  - name: regional_performance_comparison
    question: What are our top-performing regions based on device performance and customer satisfaction?
    sql: |
      SELECT
        t.region,
        COUNT(DISTINCT t.device_id) AS active_devices,
        AVG(t.battery_level) AS avg_battery_level,
        AVG(t.temperature) AS avg_temperature,
        AVG(cr.rating) AS avg_customer_rating,
        COUNT(DISTINCT cr.device_id) AS reviewed_devices
      FROM __device_telemetry AS t LEFT JOIN __customer_reviews AS cr ON t.device_id = cr.device_id GROUP BY t.region ORDER BY avg_customer_rating DESC
    verified_by: Analytics Team
  - name: quality_pass_rates_by_test
    question: Show me quality pass rates by test type over time
    sql: |
      SELECT
        test_type,
        AVG(CASE WHEN pass_fail = 'PASS' THEN 100 ELSE 0 END) AS pass_rate,
        COUNT(*) AS total_tests,
        SUM(CASE WHEN pass_fail = 'FAIL' THEN 1 ELSE 0 END) AS failures
      FROM __quality_logs GROUP BY test_type ORDER BY pass_rate DESC
    verified_by: Quality Team
  - name: customer_sentiment_by_region
    question: Which regions have the highest customer review scores?
    sql: |
      SELECT
        region,
        AVG(rating) AS avg_rating,
        COUNT(*) AS review_count,
        SUM(CASE WHEN rating >= 4 THEN 1 ELSE 0 END) AS positive_reviews,
        SUM(CASE WHEN rating <= 2 THEN 1 ELSE 0 END) AS negative_reviews
      FROM __customer_reviews GROUP BY region ORDER BY avg_rating DESC
    verified_by: CX Team
  - name: device_engagement_metrics
    question: How engaged are customers with their devices based on charging cycles and usage?
    sql: |
      SELECT
        region,
        lot_number,
        COUNT(DISTINCT device_id) AS device_count,
        AVG(charging_cycles) AS avg_charging_cycles,
        AVG(battery_level) AS avg_battery_level
      FROM __device_telemetry GROUP BY region, lot_number ORDER BY avg_charging_cycles DESC
    verified_by: Product Team
  - name: manufacturing_quality_overview
    question: How do manufacturing quality results compare across lots?
    sql: |-
      WITH quality_metrics AS (
        SELECT
          ql.lot_number,
          COUNT(*) AS test_count,
          SUM(CASE WHEN ql.pass_fail = 'PASS' THEN 1 ELSE 0 END) AS pass_count,
          SUM(CASE WHEN ql.pass_fail = 'FAIL' THEN 1 ELSE 0 END) AS failure_count,
          AVG(CASE WHEN ql.pass_fail = 'PASS' THEN 100 ELSE 0 END) AS pass_rate
        FROM __quality_logs AS ql
        GROUP BY ql.lot_number
      ),
      field_metrics AS (
        SELECT
          dt.lot_number,
          COUNT(DISTINCT dt.device_id) AS device_count,
          AVG(dt.battery_level) AS avg_battery_level,
          AVG(dt.temperature) AS avg_temperature
        FROM __device_telemetry AS dt
        GROUP BY dt.lot_number
      )
      SELECT
        qm.lot_number,
        qm.test_count,
        qm.pass_count,
        qm.failure_count,
        qm.pass_rate,
        fm.device_count,
        fm.avg_battery_level,
        fm.avg_temperature
      FROM quality_metrics AS qm
      LEFT OUTER JOIN field_metrics AS fm ON qm.lot_number = fm.lot_number
      ORDER BY qm.pass_rate DESC
    verified_by: Operations Team
module_custom_instructions:
  question_categorization: |-
    You are a specialized data analyst for PawCore, a smart pet collar manufacturing company in a growth phase. 
      
      BUSINESS CONTEXT:
      - PawCore manufactures SmartCollar devices with GPS, health sensors, and activity tracking
      - Key markets include Americas, EMEA, and APAC regions
      - Previous quality issues (Q4 2024) have been resolved — the company is now focused on growth
      - Preparing to launch SmartCollar V2 with extended battery, new sensors, and IP68 rating
      - Expanding into veterinary clinics, pet resorts, and new APAC markets
      
      DATA INTERPRETATION GUIDELINES:
      
      1. DEVICE TELEMETRY ANALYSIS:
         - Battery levels indicate device health and customer engagement
         - Charging cycles reflect how actively devices are being used
         - Regional patterns show market readiness for V2 launch
         - Temperature and humidity data supports environmental performance benchmarks
      
      2. QUALITY METRICS FOCUS:
         - Pass rates by test type show manufacturing readiness
         - Trends over time indicate quality stability (key for V2 launch approval)
         - Cross-lot comparisons validate consistency across production batches
         - High pass rates (>95%) signal readiness for new product introduction
      
      3. CUSTOMER SENTIMENT PRIORITIES:
         - Average ratings by region indicate market satisfaction and V2 demand
         - Review themes reveal feature requests and upsell opportunities
         - High-rated regions are candidates for early V2 launch
         - Customer engagement (reviews, usage) signals brand loyalty
      
      4. REGIONAL CONSIDERATIONS:
         - Americas is the largest revenue market
         - EMEA has recovered from previous issues and represents growth opportunity
         - APAC is an expansion target with different usage patterns
         - Regional performance data drives V2 launch sequencing decisions
      
      RESPONSE STYLE:
      - Provide specific metrics and percentages
      - Frame insights around V2 launch readiness and growth opportunities
      - Include actionable recommendations for product and business teams
      - Highlight regional strengths and areas for improvement
      - Connect data patterns to strategic business decisions
  sql_generation: |-
    You are a SQL generation specialist for PawCore smart collar analytics.
    
    DATABASE SCHEMA CONTEXT:
    - DEVICE_DATA.TELEMETRY: device_id, lot_number, battery_level, humidity_reading, temperature, timestamp, region, charging_cycles
    - MANUFACTURING.QUALITY_LOGS: lot_number, test_type, measurement_value, pass_fail, timestamp
    - SUPPORT.CUSTOMER_REVIEWS: device_id, lot_number, rating, review_text, region, review_date
    - SUPPORT.SLACK_MESSAGES: channel, user_name, message, timestamp
    
    SQL GENERATION GUIDELINES:
    
    1. BUSINESS-AWARE JOINS:
       - Join telemetry and quality data on lot_number for performance correlation
       - Connect customer reviews to device telemetry via device_id for satisfaction analysis
       - Use regional grouping for launch readiness comparisons
    
    2. KEY AGGREGATIONS:
       - Calculate pass rates by lot and test type for quality stability
       - Compute average ratings and sentiment by region for CX analysis
       - Measure device engagement via charging cycles and active device counts
       - Trend customer satisfaction over time to show recovery and growth
    
    3. LAUNCH READINESS METRICS:
       - Quality pass rates >95% indicate manufacturing readiness
       - Average customer ratings >3.5 suggest market readiness
       - Active device counts and engagement show installed base health
       - Regional ranking by combined metrics supports launch sequencing
    
    4. SQL BEST PRACTICES:
       - Use CTEs to separate business logic clearly
       - Include meaningful column aliases reflecting business metrics
       - Apply proper date filtering for relevant time periods
       - Structure results for executive consumption
       - Use CASE statements for business categorization$$,
  FALSE
);

-- ========================================================================
-- POST-SEMANTIC VIEW GRANTS
-- ========================================================================

GRANT SELECT, REFERENCES ON SEMANTIC VIEW PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_ANALYSIS TO ROLE PUBLIC;
GRANT SELECT, REFERENCES ON SEMANTIC VIEW PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_ANALYSIS TO ROLE ACCOUNTADMIN;
GRANT SELECT, REFERENCES ON SEMANTIC VIEW PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_ANALYSIS TO ROLE PAWCORE_ANALYST;
GRANT SELECT, REFERENCES ON SEMANTIC VIEW PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_ANALYSIS TO ROLE PAWCORE_SEARCH;

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

SHOW SEMANTIC VIEWS IN SCHEMA PAWCORE_ANALYTICS.SEMANTIC;

SELECT 'CoCo_PawCore Setup Complete!' as status,
       'Warehouse: PAWCORE_DEMO_WH (XSMALL)' as warehouse_info,
       'Database: PAWCORE_ANALYTICS' as database_info,
       'Cortex Search: PAWCORE_DOCUMENT_SEARCH' as search_service,
       'Semantic View: PAWCORE_ANALYSIS' as semantic_view,
       'Ready for CoCo Hands-On Labs!' as next_steps;
