-- ========================================================================
-- PawCore Demo Setup Script - Complete Intelligence Pipeline
-- Re-runnable script for consistent demo results
-- Repository: https://github.com/calebaalexander/SI_Webinar.git
-- ========================================================================

-- Use accountadmin role throughout for demo simplicity
USE ROLE accountadmin;

-- Create dedicated warehouse for the demo
CREATE OR REPLACE WAREHOUSE PAWCORE_DEMO_WH 
    WITH WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE;

GRANT USAGE ON WAREHOUSE PAWCORE_DEMO_WH TO ROLE PUBLIC;

-- ========================================================================
-- DATABASE AND SCHEMA SETUP
-- ========================================================================

-- Create database and schemas
CREATE OR REPLACE DATABASE PAWCORE_ANALYTICS;
USE DATABASE PAWCORE_ANALYTICS;

CREATE SCHEMA IF NOT EXISTS DEVICE_DATA;
CREATE SCHEMA IF NOT EXISTS MANUFACTURING;
CREATE SCHEMA IF NOT EXISTS SUPPORT;
CREATE SCHEMA IF NOT EXISTS WARRANTY;
CREATE SCHEMA IF NOT EXISTS UNSTRUCTURED;
CREATE SCHEMA IF NOT EXISTS SEMANTIC;

-- Grant permissions to PUBLIC for demo access
GRANT USAGE ON DATABASE PAWCORE_ANALYTICS TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA DEVICE_DATA TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA MANUFACTURING TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA SUPPORT TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA WARRANTY TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA UNSTRUCTURED TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA SEMANTIC TO ROLE PUBLIC;

-- Grant all privileges for full access
GRANT ALL PRIVILEGES ON DATABASE PAWCORE_ANALYTICS TO ROLE PUBLIC;
GRANT ALL PRIVILEGES ON ALL SCHEMAS IN DATABASE PAWCORE_ANALYTICS TO ROLE PUBLIC;

USE SCHEMA SEMANTIC;

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
    ESCAPE = 'NONE'
    ESCAPE_UNENCLOSED_FIELD = '\134'
    DATE_FORMAT = 'YYYY-MM-DD'
    TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS'
    NULL_IF = ('NULL', 'null', '', 'N/A', 'n/a');

CREATE OR REPLACE FILE FORMAT binary_format
    TYPE = 'CSV'
    RECORD_DELIMITER = NONE
    FIELD_DELIMITER = NONE
    SKIP_HEADER = 0;

CREATE OR REPLACE FILE FORMAT TEXT_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = NONE
    RECORD_DELIMITER = NONE
    SKIP_HEADER = 0
    FIELD_OPTIONALLY_ENCLOSED_BY = NONE;

-- ========================================================================
-- GIT INTEGRATION 
-- ========================================================================

-- Create API Integration for GitHub (needs ACCOUNTADMIN)
CREATE OR REPLACE API INTEGRATION pawcore_git_api
    API_PROVIDER = git_https_api
    API_ALLOWED_PREFIXES = ('https://github.com/calebaalexander/')
    ENABLED = TRUE;

-- Grant usage on integration
GRANT USAGE ON INTEGRATION pawcore_git_api TO ROLE accountadmin;

-- Create Git repository integration
CREATE OR REPLACE GIT REPOSITORY pawcore_repo
    API_INTEGRATION = pawcore_git_api
    ORIGIN = 'https://github.com/calebaalexander/SI_Webinar.git'
    COMMENT = 'PawCore demo data repository';

-- Fetch latest content
ALTER GIT REPOSITORY pawcore_repo FETCH;

-- Create internal stage
CREATE OR REPLACE STAGE PAWCORE_DATA_STAGE
    DIRECTORY = (ENABLE = TRUE)
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

-- Grant read/write access on stage (CORRECTED - No USAGE for internal stages)
GRANT READ, WRITE ON STAGE PAWCORE_DATA_STAGE TO ROLE accountadmin;
GRANT READ, WRITE ON STAGE PAWCORE_DATA_STAGE TO ROLE PUBLIC;

-- Copy files from Git repository to internal stage
COPY FILES INTO @PAWCORE_DATA_STAGE
FROM @pawcore_repo/branches/main/;

-- ========================================================================
-- CREATE TABLES (with corrected column orders)
-- ========================================================================

-- Create telemetry table (CORRECTED column order)
USE SCHEMA DEVICE_DATA;
CREATE OR REPLACE TABLE TELEMETRY (
    device_id VARCHAR(50),        -- Column 1
    timestamp TIMESTAMP,          -- Column 2
    battery_level FLOAT,          -- Column 3
    humidity_reading FLOAT,       -- Column 4
    temperature FLOAT,            -- Column 5
    charging_cycles INTEGER,      -- Column 6
    lot_number VARCHAR(50),       -- Column 7
    region VARCHAR(50)            -- Column 8
);

-- Create manufacturing quality table (CORRECTED column order)
USE SCHEMA MANUFACTURING;
CREATE OR REPLACE TABLE QUALITY_LOGS (
    lot_number VARCHAR(50),       -- Column 1
    timestamp TIMESTAMP,          -- Column 2
    test_type VARCHAR(100),       -- Column 3
    measurement_value FLOAT,      -- Column 4
    pass_fail VARCHAR(10),        -- Column 5
    operator_id VARCHAR(50),      -- Column 6
    station_id VARCHAR(50)        -- Column 7
);

-- Create parsed documents table
USE SCHEMA UNSTRUCTURED;
CREATE OR REPLACE TABLE PARSED_DOCUMENTS (
    file_name VARCHAR(500),
    file_type VARCHAR(50),
    content_type VARCHAR(50),
    content TEXT,
    metadata VARIANT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- ========================================================================
-- LOAD DATA (with corrected paths and formats)
-- ========================================================================

-- Load telemetry data
COPY INTO DEVICE_DATA.TELEMETRY
FROM @PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DATA_STAGE/Telemetry/
FILE_FORMAT = (FORMAT_NAME = 'PAWCORE_ANALYTICS.SEMANTIC.CSV_FORMAT')
PATTERN = '.*[.]csv'
FORCE = TRUE;

-- Load manufacturing quality data
COPY INTO MANUFACTURING.QUALITY_LOGS
FROM @PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DATA_STAGE/Manufacturing/
FILE_FORMAT = (FORMAT_NAME = 'PAWCORE_ANALYTICS.SEMANTIC.CSV_FORMAT')
PATTERN = '.*[.]csv'
FORCE = TRUE;

-- Load HR PDFs using PARSE_DOCUMENT (CORRECTED)
INSERT INTO UNSTRUCTURED.PARSED_DOCUMENTS (file_name, file_type, content_type, content, metadata)
SELECT 
    REGEXP_SUBSTR(METADATA$FILENAME, '[^/]+$') as file_name,
    'PDF' as file_type,
    'text' as content_type,
    COALESCE(
        SNOWFLAKE.CORTEX.PARSE_DOCUMENT(
            '@PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DATA_STAGE',
            METADATA$FILENAME,
            {'mode':'LAYOUT'}
        ):content::string,
        'PARSE_FAILED: ' || METADATA$FILENAME
    ) as content,
    OBJECT_CONSTRUCT(
        'source', 'github',
        'timestamp', CURRENT_TIMESTAMP()::string,
        'file_type', 'pdf',
        'original_filename', METADATA$FILENAME
    ) as metadata
FROM @PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DATA_STAGE
(FILE_FORMAT => PAWCORE_ANALYTICS.SEMANTIC.binary_format)
WHERE METADATA$FILENAME ILIKE 'data/HR/%.pdf';

-- Load markdown files from Document_Stage (CORRECTED - specific file only)
INSERT INTO UNSTRUCTURED.PARSED_DOCUMENTS (file_name, file_type, content_type, content, metadata)
SELECT 
    REGEXP_SUBSTR(METADATA$FILENAME, '[^/]+$') as file_name,
    'MARKDOWN' as file_type,
    'text' as content_type,
    $1 as content,
    OBJECT_CONSTRUCT(
        'source', 'github',
        'timestamp', CURRENT_TIMESTAMP()::string,
        'file_type', 'markdown',
        'original_filename', METADATA$FILENAME
    ) as metadata
FROM @PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DATA_STAGE
(FILE_FORMAT => PAWCORE_ANALYTICS.SEMANTIC.TEXT_FORMAT)
WHERE METADATA$FILENAME = 'data/Document_Stage/Q4_2024_PawCore_Financial_Report.md';

-- Load CSV files from Document_Stage
INSERT INTO UNSTRUCTURED.PARSED_DOCUMENTS (file_name, file_type, content_type, content, metadata)
SELECT 
    REGEXP_SUBSTR(METADATA$FILENAME, '[^/]+$') as file_name,
    'CSV' as file_type,
    'text' as content_type,
    $1 as content,
    OBJECT_CONSTRUCT(
        'source', 'github',
        'timestamp', CURRENT_TIMESTAMP()::string,
        'file_type', 'csv',
        'original_filename', METADATA$FILENAME
    ) as metadata
FROM @PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DATA_STAGE
(FILE_FORMAT => PAWCORE_ANALYTICS.SEMANTIC.CSV_FORMAT)
WHERE METADATA$FILENAME ILIKE 'data/Document_Stage/%.csv';

-- ========================================================================
-- CREATE SEMANTIC VIEWS FOR CORTEX ANALYST
-- ========================================================================

-- Manufacturing Quality semantic view
USE SCHEMA SEMANTIC;
CREATE OR REPLACE SEMANTIC VIEW MANUFACTURING_QUALITY_VIEW
    TABLES (
        QUALITY as MANUFACTURING.QUALITY_LOGS primary key (LOT_NUMBER) 
            with synonyms=('quality data', 'test data') 
            comment='Manufacturing quality control data'
    )
    FACTS (
        QUALITY.MEASUREMENT_VALUE as measurement_value comment='Quality test measurement value'
    )
    DIMENSIONS (
        QUALITY.LOT_NUMBER as lot_number with synonyms=('lot', 'batch', 'LOT341', 'LOT340') comment='Manufacturing lot number',
        QUALITY.TEST_TYPE as test_type with synonyms=('test', 'check', 'MOISTURE_RESISTANCE', 'moisture resistance', 'FINAL_INSPECTION', 'CHARGING_CYCLE', 'BATTERY_CAPACITY', 'ENVIRONMENTAL_STRESS') comment='Type of quality test performed',
        QUALITY.PASS_FAIL as pass_fail with synonyms=('result', 'outcome', 'PASS', 'FAIL') comment='Pass/fail result'
    )
    COMMENT='Semantic view for manufacturing quality analysis';

-- Device Telemetry semantic view
CREATE OR REPLACE SEMANTIC VIEW DEVICE_TELEMETRY_VIEW
    TABLES (
        TELEMETRY as DEVICE_DATA.TELEMETRY primary key (device_id) 
            with synonyms=('device data', 'sensor data') 
            comment='Device telemetry data including battery and environmental readings'
    )
    FACTS (
        TELEMETRY.BATTERY_LEVEL as battery_level comment='Current battery level percentage',
        TELEMETRY.HUMIDITY_READING as humidity_reading comment='Environmental humidity reading',
        TELEMETRY.TEMPERATURE as temperature comment='Environmental temperature reading'
    )
    DIMENSIONS (
        TELEMETRY.DEVICE_ID as device_id with synonyms=('device', 'unit') comment='Unique device identifier',
        TELEMETRY.LOT_NUMBER as lot_number with synonyms=('lot', 'batch') comment='Manufacturing lot number',
        TELEMETRY.REGION as region with synonyms=('market', 'area') comment='Device deployment region'
    )
    COMMENT='Semantic view for device performance analysis';

-- ========================================================================
-- CREATE CORTEX SEARCH SERVICE
-- ========================================================================

-- Create Cortex Search service for document search
CREATE OR REPLACE CORTEX SEARCH SERVICE PAWCORE_DOCUMENT_SEARCH
ON content
ATTRIBUTES file_name, file_type, metadata
WAREHOUSE = PAWCORE_DEMO_WH
TARGET_LAG = '1 minute'
AS (
    SELECT 
        content,
        file_name,
        file_type,
        metadata
    FROM UNSTRUCTURED.PARSED_DOCUMENTS
    WHERE content IS NOT NULL 
    AND LENGTH(content) > 10
);

-- Grant usage on search service
GRANT USAGE ON CORTEX SEARCH SERVICE PAWCORE_DOCUMENT_SEARCH TO ROLE PUBLIC;

-- ========================================================================
-- CREATE CORRELATION VIEW
-- ========================================================================

-- Create correlation view for lot performance analysis
CREATE OR REPLACE VIEW LOT_PERFORMANCE_BASE AS
WITH lot_metrics AS (
    SELECT 
        q.lot_number,
        q.test_type,
        q.measurement_value,
        q.pass_fail,
        AVG(t.humidity_reading) as humidity_reading,
        AVG(t.battery_level) as battery_level,
        COUNT(DISTINCT t.device_id) as device_count,
        COUNT(*) as total_tests,
        SUM(CASE WHEN q.pass_fail = 'PASS' THEN 1 ELSE 0 END) as passed_tests
    FROM MANUFACTURING.QUALITY_LOGS q
    JOIN DEVICE_DATA.TELEMETRY t ON q.lot_number = t.lot_number
    WHERE q.test_type = 'MOISTURE_RESISTANCE'
    GROUP BY q.lot_number, q.test_type, q.measurement_value, q.pass_fail
)
SELECT 
    lot_number,
    test_type,
    measurement_value,
    pass_fail,
    humidity_reading,
    battery_level,
    device_count,
    (passed_tests * 100.0 / NULLIF(total_tests, 0)) as pass_rate
FROM lot_metrics;

-- ========================================================================
-- VERIFICATION QUERIES
-- ========================================================================

-- Verify data loading
SELECT 'TELEMETRY' as table_name, COUNT(*) as row_count FROM DEVICE_DATA.TELEMETRY
UNION ALL
SELECT 'QUALITY_LOGS' as table_name, COUNT(*) as row_count FROM MANUFACTURING.QUALITY_LOGS
UNION ALL
SELECT 'PARSED_DOCUMENTS' as table_name, COUNT(*) as row_count FROM UNSTRUCTURED.PARSED_DOCUMENTS;

-- Test correlation analysis
SELECT 
    lot_number,
    measurement_value as moisture_resistance,
    humidity_reading as avg_humidity,
    battery_level as avg_battery,
    device_count
FROM LOT_PERFORMANCE_BASE
ORDER BY lot_number;

-- ========================================================================
-- SETUP COMPLETE
-- ========================================================================

SELECT 'PawCore Intelligence Pipeline Setup Complete!' as status,
       'Ready for Cortex Analyst and Search queries' as next_steps;
