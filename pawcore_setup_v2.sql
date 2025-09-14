-- ========================================================================
-- PawCore v2 Setup Script
-- Creates database, schemas, and loads all data from GitHub
-- ========================================================================

USE ROLE accountadmin;

-- Create warehouse
CREATE OR REPLACE WAREHOUSE PAWCORE_DEMO_WH 
    WITH WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE;

-- Grant warehouse usage
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

-- Grant schema usage
GRANT USAGE ON SCHEMA DEVICE_DATA TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA MANUFACTURING TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA SUPPORT TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA WARRANTY TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA UNSTRUCTURED TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA SEMANTIC TO ROLE PUBLIC;

USE SCHEMA SEMANTIC;

-- Create file formats
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

-- Create API Integration for GitHub
CREATE OR REPLACE API INTEGRATION github_api
    API_PROVIDER = git_https_api
    API_ALLOWED_PREFIXES = ('https://github.com/calebaalexander/')
    ENABLED = TRUE;

-- Grant usage on the API integration
GRANT USAGE ON INTEGRATION github_api TO ROLE SYSADMIN;

-- Create Git repository integration
CREATE OR REPLACE GIT REPOSITORY pawcore_repo
    API_INTEGRATION = github_api
    ORIGIN = 'https://github.com/calebaalexander/SI_Webinar.git'
    COMMENT = 'PawCore demo data repository';

-- Verify Git repository creation
SHOW GIT REPOSITORIES;
DESC GIT REPOSITORY pawcore_repo;

-- Create internal stage for data (no file format for mixed types)
CREATE OR REPLACE STAGE PAWCORE_DATA_STAGE
    DIRECTORY = (ENABLE = TRUE)
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

-- Create file format for structured data (CSV)
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

-- Create file format for binary/unstructured data
CREATE OR REPLACE FILE FORMAT binary_format
    TYPE = 'CSV'
    RECORD_DELIMITER = NONE
    FIELD_DELIMITER = NONE
    SKIP_HEADER = 0;

-- Refresh Git repository to get latest content
ALTER GIT REPOSITORY pawcore_repo FETCH;

-- List Git repository contents to verify
LIST @pawcore_repo/branches/main/02_Data/;

-- ========================================================================
-- COPY DATA FROM GIT TO INTERNAL STAGE
-- ========================================================================

-- Show Git repository details
SHOW GIT REPOSITORIES;

-- Copy document files
COPY FILES
INTO @PAWCORE_DATA_STAGE/documents/
FROM @pawcore_repo/branches/main/data/Document_Stage/;

-- Copy telemetry data
COPY FILES
INTO @PAWCORE_DATA_STAGE/telemetry/
FROM @pawcore_repo/branches/main/data/Telemetry/;

-- Copy manufacturing data
COPY FILES
INTO @PAWCORE_DATA_STAGE/manufacturing/
FROM @pawcore_repo/branches/main/data/Manufacturing/;

-- Copy HR documents
COPY FILES
INTO @PAWCORE_DATA_STAGE/hr/
FROM @pawcore_repo/branches/main/data/HR/;

-- Verify data copies
LIST @PAWCORE_DATA_STAGE/telemetry/;
LIST @PAWCORE_DATA_STAGE/manufacturing/;
LIST @PAWCORE_DATA_STAGE/hr/;

-- Verify files were copied
LIST @PAWCORE_DATA_STAGE;

-- Refresh stage to ensure all files are visible
ALTER STAGE PAWCORE_DATA_STAGE REFRESH;

-- Create and load tables
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

COPY INTO DEVICE_DATA.TELEMETRY
FROM @PAWCORE_DATA_STAGE/telemetry/device_telemetry.csv
FILE_FORMAT = CSV_FORMAT;

CREATE OR REPLACE TABLE MANUFACTURING.QUALITY_LOGS (
    lot_number STRING,
    timestamp TIMESTAMP,
    test_type STRING,
    measurement_value FLOAT,
    pass_fail STRING,
    operator_id STRING,
    station_id STRING
);

COPY INTO MANUFACTURING.QUALITY_LOGS
FROM @PAWCORE_DATA_STAGE/manufacturing/quality_logs.csv
FILE_FORMAT = CSV_FORMAT;

-- Create tables for structured data
CREATE OR REPLACE TABLE SUPPORT.CUSTOMER_REVIEWS (
    REVIEW_ID NUMBER,
    PRODUCT STRING,
    REGION STRING,
    DATE DATE,
    REVIEW_TEXT STRING,
    RATING NUMBER
);

CREATE OR REPLACE TABLE SUPPORT.SLACK_MESSAGES (
    THREAD_ID TIMESTAMP,
    SLACK_CHANNEL STRING,
    USER STRING,
    TEXT STRING
);

-- Create table for unstructured document parsing
CREATE OR REPLACE TABLE UNSTRUCTURED.PARSED_DOCUMENTS (
    file_name STRING,
    file_type STRING,
    content_type STRING,
    content STRING,
    parsed_date TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    metadata VARIANT
);

-- Create file format for markdown files
CREATE OR REPLACE FILE FORMAT MARKDOWN_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = NONE
    RECORD_DELIMITER = '\n'
    PARSE_HEADER = FALSE;

-- Load customer reviews
COPY INTO SUPPORT.CUSTOMER_REVIEWS
FROM @PAWCORE_DATA_STAGE/documents/customer_reviews.csv
FILE_FORMAT = CSV_FORMAT;

-- Load Slack messages
COPY INTO SUPPORT.SLACK_MESSAGES
FROM @PAWCORE_DATA_STAGE/documents/pawcore_slack.csv
FILE_FORMAT = CSV_FORMAT;

-- Parse and load PDF documents
INSERT INTO UNSTRUCTURED.PARSED_DOCUMENTS (file_name, file_type, content_type, content, metadata)
SELECT 
    REGEXP_SUBSTR(METADATA$FILENAME, '[^/]+$') as file_name,
    'PDF' as file_type,
    'text' as content_type,
    SNOWFLAKE.CORTEX.PARSE_DOCUMENT(
        '@PAWCORE_DATA_STAGE',
        'hr/' || METADATA$FILENAME,
        {'mode':'LAYOUT'}
    ):content::string as content,
    OBJECT_CONSTRUCT(
        'source', 'github',
        'timestamp', CURRENT_TIMESTAMP()::string,
        'file_type', 'pdf'
    ) as metadata
FROM @PAWCORE_DATA_STAGE/hr/
(FILE_FORMAT => binary_format, PATTERN => '.*[.]pdf');

-- Load financial report
INSERT INTO UNSTRUCTURED.PARSED_DOCUMENTS (file_name, file_type, content_type, content, metadata)
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
FROM @PAWCORE_DATA_STAGE/documents/Q4_2024_PawCore_Financial_Report.md
(FILE_FORMAT => MARKDOWN_FORMAT);

-- Load financial report
INSERT INTO UNSTRUCTURED.PARSED_DOCUMENTS (file_name, file_type, content_type, content, metadata)
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
FROM @PAWCORE_DATA_STAGE/documents/Q4_2024_PawCore_Financial_Report.md
(FILE_FORMAT => MARKDOWN_FORMAT);

-- Verify documents were loaded
SELECT COUNT(*) as doc_count FROM UNSTRUCTURED.PARSED_DOCUMENTS;

-- Create Cortex Search Service
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
            content,
            metadata
        FROM UNSTRUCTURED.PARSED_DOCUMENTS
    );

-- ========================================================================
-- CREATE SEMANTIC LAYER
-- ========================================================================

-- Create semantic views for device telemetry
CREATE OR REPLACE VIEW DEVICE_TELEMETRY_VIEW AS
SELECT
    device_id,
    timestamp,
    battery_level,
    humidity_reading,
    temperature,
    charging_cycles,
    lot_number,
    region,
    battery_level / NULLIF(charging_cycles, 0) as battery_health_index,
    humidity_reading * 
    CASE 
        WHEN temperature > 30 THEN 1.5
        WHEN temperature > 25 THEN 1.2
        ELSE 1.0 
    END as moisture_sensitivity_score
FROM DEVICE_DATA.TELEMETRY;

-- Create semantic view for quality logs
CREATE OR REPLACE VIEW QUALITY_LOGS_VIEW AS
SELECT
    lot_number,
    timestamp,
    test_type,
    measurement_value,
    pass_fail,
    operator_id,
    station_id,
    CASE WHEN pass_fail = 'PASS' THEN 100 ELSE 0 END as pass_rate
FROM MANUFACTURING.QUALITY_LOGS;

-- Create semantic view for device analysis
CREATE OR REPLACE SEMANTIC VIEW DEVICE_ANALYSIS_VIEW
    TABLES (
        TELEMETRY as DEVICE_TELEMETRY_VIEW primary key (device_id) with synonyms=('device data', 'sensor data') comment='Device telemetry data including battery and environmental readings',
        QUALITY as QUALITY_LOGS_VIEW primary key (lot_number) with synonyms=('quality data', 'test data') comment='Manufacturing quality control data'
    )
    RELATIONSHIPS (
        TELEMETRY_TO_QUALITY as TELEMETRY(lot_number) references QUALITY(lot_number)
    )
    FACTS (
        TELEMETRY.BATTERY_LEVEL as battery_level comment='Current battery level percentage',
        TELEMETRY.HUMIDITY_READING as humidity_reading comment='Environmental humidity reading',
        TELEMETRY.TEMPERATURE as temperature comment='Environmental temperature',
        TELEMETRY.CHARGING_CYCLES as charging_cycles comment='Number of charging cycles',
        QUALITY.MEASUREMENT_VALUE as measurement_value comment='Quality test measurement value',
        QUALITY.PASS_RATE as pass_rate comment='Quality test pass rate percentage'
    )
    DIMENSIONS (
        TELEMETRY.DEVICE_ID as device_id with synonyms=('device', 'unit') comment='Unique device identifier',
        TELEMETRY.LOT_NUMBER as lot_number with synonyms=('lot', 'batch') comment='Manufacturing lot number',
        TELEMETRY.REGION as region with synonyms=('market', 'area') comment='Device deployment region',
        TELEMETRY.TIMESTAMP as timestamp with synonyms=('time', 'date') comment='Reading timestamp',
        QUALITY.TEST_TYPE as test_type with synonyms=('test', 'check') comment='Type of quality test performed',
        QUALITY.OPERATOR_ID as operator_id with synonyms=('tester', 'inspector') comment='Quality test operator',
        QUALITY.STATION_ID as station_id with synonyms=('test station', 'workstation') comment='Quality test station'
    )
    METRICS (
        TELEMETRY.AVG_BATTERY_HEALTH as AVG(battery_health_index) comment='Average battery health score',
        TELEMETRY.AVG_MOISTURE_SENSITIVITY as AVG(moisture_sensitivity_score) comment='Average moisture sensitivity score',
        QUALITY.LOT_QUALITY_SCORE as AVG(pass_rate) comment='Overall lot quality score',
        QUALITY.FAILURE_RATE as (100 - AVG(pass_rate)) comment='Quality test failure rate percentage'
    )
    COMMENT='Semantic view for device quality and performance analysis';

-- Create network rule for agent
CREATE OR REPLACE NETWORK RULE PAWCORE_WEB_ACCESS
    MODE = EGRESS
    TYPE = HOST_PORT
    VALUE_LIST = ('0.0.0.0:80', '0.0.0.0:443');

-- Create external access integration
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION PAWCORE_EXTERNAL_ACCESS
    ALLOWED_NETWORK_RULES = (PAWCORE_WEB_ACCESS)
    ENABLED = true;

-- Create notification integration
CREATE OR REPLACE NOTIFICATION INTEGRATION PAWCORE_EMAIL_INT
    TYPE = EMAIL
    ENABLED = TRUE;

-- Grant permissions
GRANT USAGE ON DATABASE PAWCORE_ANALYTICS TO ROLE PUBLIC;
GRANT USAGE ON ALL SCHEMAS IN DATABASE PAWCORE_ANALYTICS TO ROLE PUBLIC;
GRANT SELECT ON ALL TABLES IN DATABASE PAWCORE_ANALYTICS TO ROLE PUBLIC;
GRANT SELECT ON ALL VIEWS IN DATABASE PAWCORE_ANALYTICS TO ROLE PUBLIC;

-- Create Intelligence Agent
CREATE OR REPLACE AGENT snowflake_intelligence.agents.pawcore_investigator
WITH PROFILE='{ "display_name": "PawCore Quality Investigator" }'
COMMENT='Agent for investigating quality issues and analyzing business impact'
FROM SPECIFICATION $$
{
  "models": {
    "orchestration": ""
  },
  "instructions": {
    "response": "You are a quality analysis specialist investigating PawCore's SmartCollar product line issues. Use data from manufacturing, device telemetry, and customer feedback to identify quality issues and their root causes.",
    "orchestration": "Analyze patterns across manufacturing lots, device performance, and customer complaints to identify systematic issues."
  },
  "tools": [
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "Query Device Data",
        "description": "Analyze device telemetry data for performance patterns"
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "Search Documents",
        "description": "Search through all available documents for relevant information"
      }
    }
  ],
  "tool_resources": {
    "Query Device Data": {
      "semantic_view": "PAWCORE_ANALYTICS.SEMANTIC.DEVICE_ANALYSIS_VIEW"
    },
    "Search Documents": {
      "name": "PAWCORE_ANALYTICS.UNSTRUCTURED.PAWCORE_DOCUMENT_SEARCH",
      "id_column": "file_name",
      "title_column": "file_name",
      "max_results": 5
    }
  }
}
$$;

-- ========================================================================
-- VERIFY SETUP
-- ========================================================================

-- Verify Git integration and file copy
SHOW GIT REPOSITORIES;
LIST @PAWCORE_DATA_STAGE;

-- Show all objects
SHOW DATABASES LIKE 'PAWCORE%';
SHOW SCHEMAS IN DATABASE PAWCORE_ANALYTICS;
SHOW TABLES IN SCHEMA PAWCORE_ANALYTICS.DEVICE_DATA;
SHOW TABLES IN SCHEMA PAWCORE_ANALYTICS.MANUFACTURING;
SHOW TABLES IN SCHEMA PAWCORE_ANALYTICS.UNSTRUCTURED;
SHOW VIEWS IN SCHEMA PAWCORE_ANALYTICS.SEMANTIC;
SHOW SEMANTIC VIEWS;
SHOW AGENTS IN SCHEMA snowflake_intelligence.agents;