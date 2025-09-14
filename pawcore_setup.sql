-- ========================================================================
-- PawCore Demo Setup Script - Complete Intelligence Pipeline
-- Re-runnable script for consistent demo results
-- Assumes ACCOUNTADMIN role and uses real data from GitHub
-- ========================================================================

USE ROLE accountadmin;

-- ========================================================================
-- INFRASTRUCTURE SETUP (Idempotent)
-- ========================================================================

-- Create warehouse
CREATE OR REPLACE WAREHOUSE PAWCORE_DEMO_WH 
    WITH WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE;

GRANT USAGE ON WAREHOUSE PAWCORE_DEMO_WH TO ROLE PUBLIC;

-- Create database and schemas
CREATE OR REPLACE DATABASE PAWCORE_ANALYTICS;
USE DATABASE PAWCORE_ANALYTICS;

CREATE SCHEMA IF NOT EXISTS DEVICE_DATA;
CREATE SCHEMA IF NOT EXISTS MANUFACTURING;
CREATE SCHEMA IF NOT EXISTS SUPPORT;
CREATE SCHEMA IF NOT EXISTS WARRANTY;
CREATE SCHEMA IF NOT EXISTS UNSTRUCTURED;
CREATE SCHEMA IF NOT EXISTS SEMANTIC;

-- Grant permissions
GRANT USAGE ON SCHEMA DEVICE_DATA TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA MANUFACTURING TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA SUPPORT TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA WARRANTY TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA UNSTRUCTURED TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA SEMANTIC TO ROLE PUBLIC;

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
    DATE_FORMAT = 'YYYY-MM-DD'
    TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS';

CREATE OR REPLACE FILE FORMAT binary_format
    TYPE = 'CSV'
    RECORD_DELIMITER = NONE
    FIELD_DELIMITER = NONE
    SKIP_HEADER = 0;

-- ========================================================================
-- GIT INTEGRATION
-- ========================================================================

CREATE OR REPLACE API INTEGRATION github_api
    API_PROVIDER = git_https_api
    API_ALLOWED_PREFIXES = ('https://github.com/calebaalexander/')
    ENABLED = TRUE;

GRANT USAGE ON INTEGRATION github_api TO ROLE SYSADMIN;

CREATE OR REPLACE GIT REPOSITORY pawcore_repo
    API_INTEGRATION = github_api
    ORIGIN = 'https://github.com/calebaalexander/SI_Webinar.git'
    COMMENT = 'PawCore demo data repository';

-- Fetch latest content
ALTER GIT REPOSITORY pawcore_repo FETCH;

-- Create internal stage
CREATE OR REPLACE STAGE PAWCORE_DATA_STAGE
    DIRECTORY = (ENABLE = TRUE)
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

-- ========================================================================
-- COPY DATA FROM GIT TO INTERNAL STAGE
-- ========================================================================

-- Copy all data files from Git repository
COPY FILES
INTO @PAWCORE_DATA_STAGE/Document_Stage/
FROM @pawcore_repo/branches/main/data/Document_Stage/;

COPY FILES
INTO @PAWCORE_DATA_STAGE/Telemetry/
FROM @pawcore_repo/branches/main/data/Telemetry/;

COPY FILES
INTO @PAWCORE_DATA_STAGE/Manufacturing/
FROM @pawcore_repo/branches/main/data/Manufacturing/;

COPY FILES
INTO @PAWCORE_DATA_STAGE/HR/
FROM @pawcore_repo/branches/main/data/HR/;

-- ========================================================================
-- CREATE TABLES (Idempotent)
-- ========================================================================

-- Create device telemetry table
CREATE OR REPLACE TABLE DEVICE_DATA.TELEMETRY (
    device_id STRING,
    timestamp TIMESTAMP,
    battery_level FLOAT,
    humidity_reading FLOAT,
    temperature FLOAT,
    charging_cycles INT,
    lot_number STRING,
    region STRING
);

-- Create manufacturing quality logs table
CREATE OR REPLACE TABLE MANUFACTURING.QUALITY_LOGS (
    lot_number STRING,
    timestamp TIMESTAMP,
    test_type STRING,
    measurement_value FLOAT,
    pass_fail STRING,
    operator_id STRING,  -- Fixed: renamed from OPERATOR (reserved keyword)
    station_id STRING
);

-- Create customer reviews table
CREATE OR REPLACE TABLE SUPPORT.CUSTOMER_REVIEWS (
    review_id STRING,
    product STRING,
    region STRING,
    date DATE,
    review_text STRING,
    rating INT
);

-- Create Slack messages table
CREATE OR REPLACE TABLE SUPPORT.SLACK_MESSAGES (
    timestamp TIMESTAMP,
    channel STRING,
    user_name STRING,
    message_text STRING
);

-- Create parsed documents table
CREATE OR REPLACE TABLE UNSTRUCTURED.PARSED_DOCUMENTS (
    file_name STRING,
    file_type STRING,
    content_type STRING,
    content STRING,
    metadata VARIANT,
    parsed_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- ========================================================================
-- LOAD STRUCTURED DATA (Re-runnable with FORCE = TRUE)
-- ========================================================================

-- Load device telemetry data
COPY INTO DEVICE_DATA.TELEMETRY
FROM @PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DATA_STAGE/Telemetry/device_telemetry.csv
FILE_FORMAT = PAWCORE_ANALYTICS.SEMANTIC.CSV_FORMAT
FORCE = TRUE;

-- Load manufacturing quality logs
COPY INTO MANUFACTURING.QUALITY_LOGS
FROM @PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DATA_STAGE/Manufacturing/quality_logs.csv
FILE_FORMAT = PAWCORE_ANALYTICS.SEMANTIC.CSV_FORMAT
FORCE = TRUE;

-- Load customer reviews
COPY INTO SUPPORT.CUSTOMER_REVIEWS
FROM @PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DATA_STAGE/Document_Stage/customer_reviews.csv
FILE_FORMAT = PAWCORE_ANALYTICS.SEMANTIC.CSV_FORMAT
FORCE = TRUE;

-- Load Slack messages
COPY INTO SUPPORT.SLACK_MESSAGES
FROM @PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DATA_STAGE/Document_Stage/pawcore_slack.csv
FILE_FORMAT = PAWCORE_ANALYTICS.SEMANTIC.CSV_FORMAT
FORCE = TRUE;

-- ========================================================================
-- LOAD UNSTRUCTURED DOCUMENTS (Re-runnable)
-- ========================================================================

-- Switch to UNSTRUCTURED schema
USE SCHEMA UNSTRUCTURED;

-- Clear existing documents for clean reload
TRUNCATE TABLE PARSED_DOCUMENTS;

-- Load financial report as single document
INSERT INTO PARSED_DOCUMENTS (file_name, file_type, content_type, content, metadata)
SELECT 
    'Q4_2024_PawCore_Financial_Report.md' as file_name,
    'MD' as file_type,
    'text' as content_type,
    $1 as content,
    OBJECT_CONSTRUCT(
        'source', 'github',
        'timestamp', CURRENT_TIMESTAMP()::string,
        'file_type', 'markdown'
    ) as metadata
FROM @PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DATA_STAGE/Document_Stage/Q4_2024_PawCore_Financial_Report.md
(FILE_FORMAT => PAWCORE_ANALYTICS.SEMANTIC.binary_format);

-- Load HR PDFs using PARSE_DOCUMENT
INSERT INTO PARSED_DOCUMENTS (file_name, file_type, content_type, content, metadata)
SELECT 
    REGEXP_SUBSTR(METADATA$FILENAME, '[^/]+$') as file_name,
    'PDF' as file_type,
    'text' as content_type,
    SNOWFLAKE.CORTEX.PARSE_DOCUMENT(
        '@PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DATA_STAGE',
        'HR/' || METADATA$FILENAME,
        {'mode':'LAYOUT'}
    ):content::string as content,
    OBJECT_CONSTRUCT(
        'source', 'github',
        'timestamp', CURRENT_TIMESTAMP()::string,
        'file_type', 'pdf'
    ) as metadata
FROM @PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DATA_STAGE/HR/ 
(FILE_FORMAT => PAWCORE_ANALYTICS.SEMANTIC.binary_format, PATTERN => '.*[.]pdf');

-- ========================================================================
-- CREATE SEMANTIC VIEWS FOR CORTEX ANALYST
-- ========================================================================

-- Switch back to SEMANTIC schema
USE SCHEMA SEMANTIC;

-- Create semantic view for manufacturing quality analysis
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
        QUALITY.LOT_NUMBER as lot_number with synonyms=('lot', 'batch') comment='Manufacturing lot number',
        QUALITY.TEST_TYPE as test_type with synonyms=('test', 'check') comment='Type of quality test performed',
        QUALITY.PASS_FAIL as pass_fail with synonyms=('result', 'outcome') comment='Pass/fail result',
        QUALITY.OPERATOR_ID as operator_id with synonyms=('tester', 'inspector') comment='Quality test operator',
        QUALITY.STATION_ID as station_id with synonyms=('test station', 'workstation') comment='Quality test station',
        QUALITY.TIMESTAMP as timestamp with synonyms=('date', 'time') comment='Test timestamp'
    )
    METRICS (
        QUALITY.AVG_MEASUREMENT as AVG(MEASUREMENT_VALUE) comment='Average test measurement value',
        QUALITY.PASS_RATE as (SUM(CASE WHEN PASS_FAIL = 'PASS' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0)) * 100 comment='Pass rate percentage'
    )
    COMMENT='Semantic view for manufacturing quality analysis';

-- Create semantic view for device telemetry analysis  
CREATE OR REPLACE SEMANTIC VIEW DEVICE_TELEMETRY_VIEW
    TABLES (
        TELEMETRY as DEVICE_DATA.TELEMETRY primary key (device_id) 
            with synonyms=('device data', 'sensor data') 
            comment='Device telemetry data including battery and environmental readings'
    )
    FACTS (
        TELEMETRY.BATTERY_LEVEL as battery_level comment='Current battery level percentage',
        TELEMETRY.HUMIDITY_READING as humidity_reading comment='Environmental humidity reading',
        TELEMETRY.TEMPERATURE as temperature comment='Environmental temperature reading',
        TELEMETRY.CHARGING_CYCLES as charging_cycles comment='Number of charging cycles'
    )
    DIMENSIONS (
        TELEMETRY.DEVICE_ID as device_id with synonyms=('device', 'unit') comment='Unique device identifier',
        TELEMETRY.LOT_NUMBER as lot_number with synonyms=('lot', 'batch') comment='Manufacturing lot number',
        TELEMETRY.REGION as region with synonyms=('market', 'area') comment='Device deployment region',
        TELEMETRY.TIMESTAMP as timestamp with synonyms=('time', 'date') comment='Reading timestamp'
    )
    METRICS (
        TELEMETRY.AVG_BATTERY as AVG(BATTERY_LEVEL) comment='Average battery level',
        TELEMETRY.AVG_HUMIDITY as AVG(HUMIDITY_READING) comment='Average humidity reading',
        TELEMETRY.AVG_TEMPERATURE as AVG(TEMPERATURE) comment='Average temperature',
        TELEMETRY.TOTAL_CYCLES as SUM(CHARGING_CYCLES) comment='Total charging cycles'
    )
    COMMENT='Semantic view for device performance analysis';

-- ========================================================================
-- CREATE CORTEX SEARCH SERVICE
-- ========================================================================

CREATE OR REPLACE CORTEX SEARCH SERVICE PAWCORE_DOCUMENT_SEARCH
    ON content
    ATTRIBUTES file_name, file_type, content_type
    WAREHOUSE = PAWCORE_DEMO_WH
    TARGET_LAG = '30 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
    AS (
        SELECT
            file_name,
            file_type,
            content_type,
            content
        FROM UNSTRUCTURED.PARSED_DOCUMENTS
    );

-- ========================================================================
-- CREATE INTELLIGENCE AGENT
-- ========================================================================

-- Create the PawCore investigator agent
CREATE OR REPLACE AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.pawcore_investigator
WITH PROFILE='{ "display_name": "PawCore Quality Investigator" }'
COMMENT='Agent for investigating quality issues and analyzing business impact'
FROM SPECIFICATION $$
{
  "models": {
    "orchestration": ""
  },
  "instructions": {
    "response": "You are investigating PawCore's Q4 2024 SmartCollar crisis. Key findings: SmartCollar revenue dropped 48% vs forecast due to battery and moisture issues in EMEA region. Manufacturing lot 341 had serious quality problems. Customer ratings dropped from 5.0 to 1.6 in Q4 2024. Analyze patterns and recommend immediate actions.",
    "orchestration": "Focus on correlating customer sentiment, financial performance, and manufacturing quality data to identify systematic issues and prevent future crises."
  },
  "tools": [
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "Search Documents",
        "description": "Search financial reports and customer feedback"
      }
    }
  ],
  "tool_resources": {
    "Search Documents": {
      "search_service": "PAWCORE_ANALYTICS.SEMANTIC.PAWCORE_DOCUMENT_SEARCH"
    }
  }
}
$$;

-- ========================================================================
-- VERIFICATION QUERIES
-- ========================================================================

-- Verify all data loaded correctly
SELECT 'TELEMETRY' as table_name, COUNT(*) as row_count FROM DEVICE_DATA.TELEMETRY
UNION ALL
SELECT 'QUALITY_LOGS', COUNT(*) FROM MANUFACTURING.QUALITY_LOGS
UNION ALL
SELECT 'CUSTOMER_REVIEWS', COUNT(*) FROM SUPPORT.CUSTOMER_REVIEWS
UNION ALL
SELECT 'SLACK_MESSAGES', COUNT(*) FROM SUPPORT.SLACK_MESSAGES
UNION ALL
SELECT 'PARSED_DOCUMENTS', COUNT(*) FROM UNSTRUCTURED.PARSED_DOCUMENTS;

-- Verify financial report loaded
SELECT 
    file_name, 
    LENGTH(content) as content_length,
    LEFT(content, 100) as content_preview
FROM UNSTRUCTURED.PARSED_DOCUMENTS
WHERE file_name = 'Q4_2024_PawCore_Financial_Report.md';

-- ========================================================================
-- SAMPLE ANALYSIS QUERIES (Matching Demo Gameplan)
-- ========================================================================

-- Phase 1: Extract financial metrics from Q4 report
SELECT
    SNOWFLAKE.CORTEX.EXTRACT_ANSWER(
        content,
        'Extract key financial metrics and anomalies from this Q4 2024 Financial Report. Include total revenue vs forecast, SmartCollar performance, and EMEA region performance.'
    ) as financial_analysis
FROM UNSTRUCTURED.PARSED_DOCUMENTS
WHERE file_name = 'Q4_2024_PawCore_Financial_Report.md';

-- Phase 1: Analyze customer sentiment for SmartCollar in EMEA
SELECT
    REGION,
    PRODUCT,
    COUNT(*) as review_count,
    AVG(RATING) as avg_rating,
    AVG(SNOWFLAKE.CORTEX.SENTIMENT(REVIEW_TEXT)) as avg_sentiment,
    SNOWFLAKE.CORTEX.EXTRACT_ANSWER(
        LISTAGG(REVIEW_TEXT, ' | '), 
        'What are the main technical issues mentioned in these SmartCollar reviews?'
    ) as common_issues
FROM SUPPORT.CUSTOMER_REVIEWS
WHERE PRODUCT = 'SmartCollar' AND REGION = 'EMEA'
GROUP BY REGION, PRODUCT;

-- Phase 1: Summarize Slack communications about SmartCollar issues
SELECT
    SNOWFLAKE.CORTEX.SUMMARIZE(
        LISTAGG(message_text, ' | ')
    ) as slack_summary
FROM SUPPORT.SLACK_MESSAGES
WHERE message_text ILIKE '%SmartCollar%' OR message_text ILIKE '%LOT341%' OR message_text ILIKE '%battery%';

-- ========================================================================
-- DEMO COMPLETE MESSAGE
-- ========================================================================

SELECT 
    '🎉 PawCore Demo Setup Complete! 🎉' as status,
    'All data loaded, semantic views created, Cortex Search enabled, and Intelligence Agent ready!' as message,
    'Your demo is ready to investigate the Q4 2024 SmartCollar crisis.' as next_steps;