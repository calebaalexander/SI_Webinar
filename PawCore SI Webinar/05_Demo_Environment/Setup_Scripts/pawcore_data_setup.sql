-- ========================================================================
-- PawCore Data Setup Script (Core Data Only)
-- This script creates the database, schema, tables, and loads all data
-- Intelligence features (agents) need to be set up separately after this
-- Repository: https://github.com/calebaalexander/SI_Webinar.git
-- ========================================================================

-- Switch to accountadmin role to create warehouse
USE ROLE accountadmin;

-- Create PawCore Intelligence Demo role
CREATE OR REPLACE ROLE PAWCORE_INTELLIGENCE_ROLE;

SET current_user_name = CURRENT_USER();

-- Grant the role to current user
GRANT ROLE PAWCORE_INTELLIGENCE_ROLE TO USER IDENTIFIER($current_user_name);
GRANT CREATE DATABASE ON ACCOUNT TO ROLE PAWCORE_INTELLIGENCE_ROLE;

-- Create a dedicated warehouse for the demo with auto-suspend/resume
CREATE OR REPLACE WAREHOUSE PAWCORE_INTELLIGENCE_WH 
    WITH WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE;

-- Grant usage on warehouse to demo role
GRANT USAGE ON WAREHOUSE PAWCORE_INTELLIGENCE_WH TO ROLE PAWCORE_INTELLIGENCE_ROLE;

-- Alter current user's default role and warehouse
ALTER USER IDENTIFIER($current_user_name) SET DEFAULT_ROLE = PAWCORE_INTELLIGENCE_ROLE;
ALTER USER IDENTIFIER($current_user_name) SET DEFAULT_WAREHOUSE = PAWCORE_INTELLIGENCE_WH;

-- Switch to PawCore Intelligence role to create demo objects
USE ROLE PAWCORE_INTELLIGENCE_ROLE;

-- Create database and schema
CREATE OR REPLACE DATABASE PAWCORE_INTELLIGENCE_DEMO;
USE DATABASE PAWCORE_INTELLIGENCE_DEMO;

CREATE SCHEMA IF NOT EXISTS BUSINESS_DATA;
CREATE SCHEMA IF NOT EXISTS DOCUMENTS;
USE SCHEMA BUSINESS_DATA;

-- Create file format for CSV files
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

-- Note: Git integration removed to avoid path syntax issues with spaces
-- Files will be uploaded manually to stages

-- Create internal stages for data files
CREATE OR REPLACE STAGE INTERNAL_DATA_STAGE
    FILE_FORMAT = CSV_FORMAT
    COMMENT = 'Internal stage for PawCore demo data files'
    DIRECTORY = (ENABLE = TRUE)
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

CREATE OR REPLACE STAGE DOCUMENT_STAGE
    COMMENT = 'Document stage for unstructured PawCore data'
    DIRECTORY = (ENABLE = TRUE)
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

CREATE OR REPLACE STAGE AUDIO_STAGE
    COMMENT = 'Audio stage for PawCore quarterly calls'
    DIRECTORY = (ENABLE = TRUE)
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

-- Git repository setup removed - using manual file uploads instead

-- ========================================================================
-- MANUAL FILE UPLOAD INSTRUCTIONS
-- ========================================================================

-- IMPORTANT: Before running the data loading section below, you need to upload files manually
-- to the stages. Use Snowflake UI or SnowSQL to upload the following files:

-- 1. Upload to @INTERNAL_DATA_STAGE:
--    - pawcore_sales.csv
--    - returns.csv  
--    - hr_resumes.csv
--    - support_tickets.csv
--    - warranty_costs.csv
--    - pet_owners.csv

-- 2. Upload to @DOCUMENT_STAGE:
--    - customer_reviews.csv
--    - pawcore_slack.csv

-- 3. Upload to @AUDIO_STAGE:
--    - PawCore Quarterly Call.mp3

-- Verify files were uploaded
LS @INTERNAL_DATA_STAGE;
LS @DOCUMENT_STAGE; 
LS @AUDIO_STAGE;

-- Refresh stages after manual upload
ALTER STAGE INTERNAL_DATA_STAGE REFRESH;
ALTER STAGE DOCUMENT_STAGE REFRESH;
ALTER STAGE AUDIO_STAGE REFRESH;

-- ========================================================================
-- CREATE PAWCORE BUSINESS TABLES
-- ========================================================================

-- Core sales and business tables
CREATE TABLE IF NOT EXISTS PAWCORE_SALES (
  SALE_ID STRING DEFAULT UUID_STRING(),
  DATE DATE,
  REGION STRING,
  PRODUCT STRING,
  PRODUCT_CATEGORY STRING DEFAULT 'Pet Wellness Device',
  FORECAST_SALES NUMBER(10,2),
  ACTUAL_SALES NUMBER(10,2),
  VARIANCE NUMBER(10,2),
  PCT_OF_FORECAST NUMBER(5,2),
  INVENTORY_UNITS_AVAILABLE INTEGER,
  MARKETING_ENGAGEMENT_SCORE INTEGER,
  SALES_REP STRING DEFAULT 'TBD',
  CUSTOMER_SEGMENT STRING DEFAULT 'Standard'
);

-- 🚨 Critical mystery table
CREATE TABLE IF NOT EXISTS RETURNS (
  RETURN_ID STRING,
  DATE DATE,
  REGION STRING,
  PRODUCT STRING,
  LOT_ID STRING,
  REASON STRING,
  QTY NUMBER,
  UNIT_COST_USD NUMBER(10,2),
  TOTAL_COST_USD NUMBER(10,2)
);

-- HR table for hiring bonus
CREATE TABLE IF NOT EXISTS HR_RESUMES (
  CANDIDATE_NAME STRING,
  RESUME_TEXT TEXT,
  APPLICATION_DATE DATE,
  POSITION_APPLIED STRING
);

-- Supporting business tables
CREATE TABLE IF NOT EXISTS PET_OWNERS (
  CUSTOMER_ID STRING,
  CUSTOMER_NAME STRING,
  PET_TYPE STRING,
  PET_NAME STRING,
  REGION STRING,
  SEGMENT STRING,
  JOIN_DATE DATE
);

CREATE TABLE IF NOT EXISTS DEVICE_SALES_BY_REGION (
  SALES_ID STRING DEFAULT UUID_STRING(),
  DATE DATE,
  REGION STRING,
  DEVICE_TYPE STRING,
  PRODUCT_NAME STRING,
  UNITS_SOLD INTEGER,
  REVENUE NUMBER(10,2),
  GROWTH_RATE NUMBER(5,2),
  QUARTER STRING,
  SALES_CHANNEL STRING DEFAULT 'Online'
);

-- Unstructured data tables
CREATE TABLE IF NOT EXISTS SLACK_MESSAGES (
  MESSAGE_ID STRING,
  CHANNEL STRING,
  AUTHOR STRING,
  MESSAGE_TEXT STRING,
  TIMESTAMP TIMESTAMP,
  SENTIMENT STRING
);

CREATE TABLE IF NOT EXISTS CUSTOMER_REVIEWS (
  REVIEW_ID STRING,
  DATE DATE,
  PRODUCT STRING,
  PRODUCT_CATEGORY STRING DEFAULT 'Pet Device',
  CUSTOMER_NAME STRING,
  CUSTOMER_ID STRING,
  RATING INTEGER,
  REVIEW_TEXT STRING,
  SENTIMENT STRING,
  REVIEW_CATEGORY STRING,
  VERIFIED_PURCHASE STRING,
  HELPFUL_VOTES INTEGER,
  REVIEW_LENGTH INTEGER,
  REGION STRING,
  CUSTOMER_SEGMENT STRING,
  PURCHASE_DATE DATE,
  DEVICE_AGE_DAYS INTEGER
);

-- Mystery support tables
CREATE TABLE IF NOT EXISTS SUPPORT_TICKETS (
  TICKET_ID STRING,
  DATE DATE,
  REGION STRING,
  PRODUCT STRING,
  FIRMWARE_VERSION STRING,
  CATEGORY STRING,
  STATUS STRING
);

CREATE TABLE IF NOT EXISTS WARRANTY_COSTS (
  PERIOD STRING,
  REGION STRING,
  PRODUCT STRING,
  COST_USD NUMBER(10,2)
);

-- ========================================================================
-- LOAD PAWCORE DATA FROM INTERNAL STAGES
-- ========================================================================

-- Load core sales data
COPY INTO PAWCORE_SALES (
  DATE, REGION, PRODUCT, FORECAST_SALES, ACTUAL_SALES, VARIANCE,
  PCT_OF_FORECAST, INVENTORY_UNITS_AVAILABLE, MARKETING_ENGAGEMENT_SCORE
)
FROM @INTERNAL_DATA_STAGE/pawcore_sales.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

-- Enhance sales data with additional business context
UPDATE PAWCORE_SALES SET 
  PRODUCT_CATEGORY = CASE 
    WHEN PRODUCT LIKE '%SmartCollar%' THEN 'Smart Monitoring'
    WHEN PRODUCT LIKE '%HealthMonitor%' THEN 'Health Tracking'
    WHEN PRODUCT LIKE '%PetTracker%' THEN 'Location Tracking'
    ELSE 'Pet Wellness Device'
  END,
  SALES_REP = CASE 
    WHEN REGION = 'EMEA' THEN 'Sarah Chen'
    WHEN REGION = 'North America' THEN 'Marcus Rodriguez'
    WHEN REGION = 'Asia Pacific' THEN 'Yuki Tanaka'
    ELSE 'Regional Team'
  END,
  CUSTOMER_SEGMENT = CASE 
    WHEN ACTUAL_SALES > 50000 THEN 'Enterprise'
    WHEN ACTUAL_SALES > 20000 THEN 'Professional'
    ELSE 'Standard'
  END
WHERE PRODUCT_CATEGORY = 'Pet Wellness Device';

-- 🚨 CRITICAL: Load mystery returns data
COPY INTO RETURNS (
  RETURN_ID, DATE, REGION, PRODUCT, LOT_ID, REASON, QTY, UNIT_COST_USD, TOTAL_COST_USD
)
FROM @INTERNAL_DATA_STAGE/returns.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

-- Load HR resumes for hiring solution
COPY INTO HR_RESUMES (
  CANDIDATE_NAME, RESUME_TEXT, APPLICATION_DATE, POSITION_APPLIED
)
FROM @INTERNAL_DATA_STAGE/hr_resumes.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

-- Load support evidence tables
COPY INTO SUPPORT_TICKETS (TICKET_ID, DATE, REGION, PRODUCT, FIRMWARE_VERSION, CATEGORY, STATUS)
FROM @INTERNAL_DATA_STAGE/support_tickets.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

COPY INTO WARRANTY_COSTS (PERIOD, REGION, PRODUCT, COST_USD)
FROM @INTERNAL_DATA_STAGE/warranty_costs.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

-- Load Slack messages with staging
CREATE OR REPLACE TABLE SLACK_MESSAGES_STG (URL STRING, CHANNEL STRING, TS STRING, TEXT STRING);
COPY INTO SLACK_MESSAGES_STG 
FROM @DOCUMENT_STAGE/pawcore_slack.csv 
FILE_FORMAT = CSV_FORMAT 
FORCE = TRUE 
ON_ERROR = 'CONTINUE';

-- Transform and enrich with sentiment
INSERT INTO SLACK_MESSAGES (MESSAGE_ID, CHANNEL, AUTHOR, MESSAGE_TEXT, TIMESTAMP, SENTIMENT)
SELECT 
    TS,
    CHANNEL,
    NULL,
    TEXT,
    TO_TIMESTAMP_NTZ(TRY_TO_NUMBER(SUBSTR(TS,1,10))),
    SNOWFLAKE.CORTEX.SENTIMENT(TEXT)  -- 🤖 AI sentiment analysis
FROM SLACK_MESSAGES_STG;

-- Load customer reviews
COPY INTO CUSTOMER_REVIEWS
FROM @DOCUMENT_STAGE/customer_reviews.csv
FILE_FORMAT = CSV_FORMAT
FORCE = TRUE
ON_ERROR = 'CONTINUE';

-- Enhance customer reviews with additional context
UPDATE CUSTOMER_REVIEWS SET 
  PRODUCT_CATEGORY = CASE 
    WHEN PRODUCT LIKE '%SmartCollar%' THEN 'Smart Monitoring'
    WHEN PRODUCT LIKE '%HealthMonitor%' THEN 'Health Tracking'
    WHEN PRODUCT LIKE '%PetTracker%' THEN 'Location Tracking'
    ELSE 'Pet Device'
  END,
  CUSTOMER_ID = 'CUST_' || ABS(HASH(CUSTOMER_NAME)),
  PURCHASE_DATE = DATEADD(day, -UNIFORM(30, 365, RANDOM()), DATE),
  DEVICE_AGE_DAYS = DATEDIFF(day, PURCHASE_DATE, DATE)
WHERE PRODUCT_CATEGORY = 'Pet Device';

-- Load supporting customer data
CREATE OR REPLACE TABLE PET_OWNERS_STG (CUSTOMER_NAME STRING, PHONE STRING, EMAIL STRING);
COPY INTO PET_OWNERS_STG 
FROM @INTERNAL_DATA_STAGE/pet_owners.csv 
FILE_FORMAT = CSV_FORMAT 
ON_ERROR = 'CONTINUE';

INSERT INTO PET_OWNERS (CUSTOMER_ID, CUSTOMER_NAME, PET_TYPE, PET_NAME, REGION, SEGMENT, JOIN_DATE)
SELECT UUID_STRING(), CUSTOMER_NAME, NULL, NULL, NULL, NULL, CURRENT_DATE() 
FROM PET_OWNERS_STG;

-- ========================================================================
-- CREATE PAWCORE SEMANTIC VIEWS
-- ========================================================================

-- Sales Semantic View for PawCore
CREATE OR REPLACE SEMANTIC VIEW PAWCORE_SALES_SEMANTIC_VIEW
    TABLES (
        SALES as PAWCORE_SALES primary key (SALE_ID) with synonyms=('sales data','revenue data') comment='PawCore sales performance data',
        RETURNS as RETURNS primary key (RETURN_ID) with synonyms=('returns','return data') comment='Product returns and defects data',
        REVIEWS as CUSTOMER_REVIEWS primary key (REVIEW_ID) with synonyms=('customer reviews','feedback') comment='Customer feedback and sentiment'
    )
    RELATIONSHIPS (
        SALES_TO_RETURNS as SALES(PRODUCT) references RETURNS(PRODUCT),
        SALES_TO_REVIEWS as SALES(PRODUCT) references REVIEWS(PRODUCT)
    )
    FACTS (
        SALES.ACTUAL_SALES as actual_sales comment='Actual sales revenue in USD',
        SALES.FORECAST_SALES as forecast_sales comment='Forecasted sales revenue in USD',
        SALES.VARIANCE as variance comment='Variance between actual and forecast',
        RETURNS.QTY as return_quantity comment='Number of units returned',
        RETURNS.TOTAL_COST_USD as return_cost comment='Total cost of returns in USD',
        REVIEWS.RATING as customer_rating comment='Customer rating 1-5'
    )
    DIMENSIONS (
        SALES.DATE as sale_date with synonyms=('date','sales date') comment='Date of sale',
        SALES.REGION as region with synonyms=('region','territory') comment='Sales region',
        SALES.PRODUCT as product with synonyms=('product','device') comment='Product name',
        SALES.PRODUCT_CATEGORY as product_category comment='Product category',
        SALES.SALES_REP as sales_rep comment='Sales representative',
        RETURNS.LOT_ID as lot_id comment='Manufacturing lot identifier',
        RETURNS.REASON as return_reason comment='Reason for product return',
        REVIEWS.SENTIMENT as review_sentiment comment='Customer review sentiment'
    )
    METRICS (
        SALES.TOTAL_REVENUE as SUM(sales.actual_sales) comment='Total sales revenue',
        SALES.TOTAL_VARIANCE as SUM(sales.variance) comment='Total variance from forecast',
        RETURNS.TOTAL_RETURNS as SUM(returns.return_quantity) comment='Total units returned',
        RETURNS.TOTAL_RETURN_COST as SUM(returns.return_cost) comment='Total cost of returns',
        REVIEWS.AVERAGE_RATING as AVG(reviews.customer_rating) comment='Average customer rating'
    )
    COMMENT='Semantic view for PawCore sales and returns analysis';

-- Operations Semantic View for PawCore
CREATE OR REPLACE SEMANTIC VIEW PAWCORE_OPERATIONS_SEMANTIC_VIEW
    TABLES (
        TICKETS as SUPPORT_TICKETS primary key (TICKET_ID) with synonyms=('support tickets','issues') comment='Customer support tickets',
        COSTS as WARRANTY_COSTS primary key (PERIOD) with synonyms=('warranty costs','expenses') comment='Warranty cost data',
        SLACK as SLACK_MESSAGES primary key (MESSAGE_ID) with synonyms=('slack messages','communications') comment='Internal team communications'
    )
    FACTS (
        COSTS.COST_USD as warranty_cost comment='Warranty costs in USD',
        TICKETS.TICKET_RECORD as 1 comment='Count of support tickets',
        SLACK.MESSAGE_RECORD as 1 comment='Count of Slack messages'
    )
    DIMENSIONS (
        TICKETS.DATE as ticket_date comment='Date of support ticket',
        TICKETS.REGION as region comment='Region of support ticket',
        TICKETS.PRODUCT as product comment='Product related to ticket',
        TICKETS.CATEGORY as ticket_category comment='Category of support issue',
        TICKETS.STATUS as ticket_status comment='Status of support ticket',
        COSTS.PERIOD as period comment='Time period for warranty costs',
        SLACK.CHANNEL as slack_channel comment='Slack channel name',
        SLACK.SENTIMENT as message_sentiment comment='Message sentiment analysis'
    )
    METRICS (
        TICKETS.TOTAL_TICKETS as COUNT(tickets.ticket_record) comment='Total number of support tickets',
        COSTS.TOTAL_WARRANTY_COST as SUM(costs.warranty_cost) comment='Total warranty costs',
        SLACK.TOTAL_MESSAGES as COUNT(slack.message_record) comment='Total Slack messages'
    )
    COMMENT='Semantic view for PawCore operations and support analysis';

-- ========================================================================
-- CREATE CORTEX SEARCH SERVICES
-- ========================================================================

-- Parse documents for search
CREATE OR REPLACE TABLE PARSED_CONTENT AS 
SELECT 
    relative_path, 
    BUILD_STAGE_FILE_URL('@PAWCORE_INTELLIGENCE_DEMO.BUSINESS_DATA.DOCUMENT_STAGE', relative_path) as file_url,
    TO_FILE(BUILD_STAGE_FILE_URL('@PAWCORE_INTELLIGENCE_DEMO.BUSINESS_DATA.DOCUMENT_STAGE', relative_path)) file_object,
    SNOWFLAKE.CORTEX.PARSE_DOCUMENT(
        @PAWCORE_INTELLIGENCE_DEMO.BUSINESS_DATA.DOCUMENT_STAGE,
        relative_path,
        {'mode':'LAYOUT'}
    ):content::string as content
FROM directory(@PAWCORE_INTELLIGENCE_DEMO.BUSINESS_DATA.DOCUMENT_STAGE) 
WHERE relative_path ILIKE '%.md' OR relative_path ILIKE '%.csv';

-- Create search service for customer reviews
CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH_CUSTOMER_REVIEWS
    ON review_text
    ATTRIBUTES review_id, product, region, rating, sentiment
    WAREHOUSE = PAWCORE_INTELLIGENCE_WH
    TARGET_LAG = '30 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
    AS (
        SELECT
            review_id,
            product,
            region,
            rating,
            sentiment,
            review_text
        FROM customer_reviews
    );

-- Create search service for Slack messages
CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH_SLACK_MESSAGES
    ON message_text
    ATTRIBUTES channel, sentiment, timestamp
    WAREHOUSE = PAWCORE_INTELLIGENCE_WH
    TARGET_LAG = '30 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
    AS (
        SELECT
            channel,
            sentiment,
            timestamp,
            message_text
        FROM slack_messages
    );

-- Create search service for documents
CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH_PAWCORE_DOCUMENTS
    ON content
    ATTRIBUTES relative_path, file_url
    WAREHOUSE = PAWCORE_INTELLIGENCE_WH
    TARGET_LAG = '30 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
    AS (
        SELECT
            relative_path,
            file_url,
            content
        FROM parsed_content
    );

-- ========================================================================
-- VERIFICATION AND MYSTERY PREVIEW
-- ========================================================================

-- Verify data loads
SELECT 'DATA VERIFICATION' as category, '' as table_name, NULL as row_count
UNION ALL
SELECT '', 'PAWCORE_SALES', COUNT(*) FROM PAWCORE_SALES
UNION ALL
SELECT '', 'RETURNS', COUNT(*) FROM RETURNS
UNION ALL
SELECT '', 'HR_RESUMES', COUNT(*) FROM HR_RESUMES
UNION ALL
SELECT '', 'CUSTOMER_REVIEWS', COUNT(*) FROM CUSTOMER_REVIEWS
UNION ALL
SELECT '', 'SLACK_MESSAGES', COUNT(*) FROM SLACK_MESSAGES
UNION ALL
SELECT '', 'SUPPORT_TICKETS', COUNT(*) FROM SUPPORT_TICKETS
UNION ALL
SELECT '', 'WARRANTY_COSTS', COUNT(*) FROM WARRANTY_COSTS
UNION ALL
SELECT '', '', NULL
UNION ALL
SELECT 'SERVICES VERIFICATION', '', NULL
UNION ALL
SELECT '', 'SEMANTIC_VIEWS', (SELECT COUNT(*) FROM INFORMATION_SCHEMA.SEMANTIC_VIEWS WHERE SEMANTIC_VIEW_SCHEMA = 'BUSINESS_DATA')
UNION ALL
SELECT '', 'SEARCH_SERVICES', (SELECT COUNT(*) FROM INFORMATION_SCHEMA.CORTEX_SEARCH_SERVICES WHERE SERVICE_SCHEMA = 'BUSINESS_DATA');

-- 🕵️ MYSTERY PREVIEW: Show the Lot 341 anomaly immediately
WITH weekly_returns AS (
    SELECT 
        DATE_TRUNC('WEEK', DATE) AS week_start,
        LOT_ID,
        REGION,
        SUM(QTY) AS returned_units,
        SUM(TOTAL_COST_USD) AS total_cost
    FROM RETURNS 
    WHERE PRODUCT = 'SmartCollar'
    GROUP BY 1, 2, 3
),
baseline AS (
    SELECT AVG(returned_units) AS avg_baseline
    FROM weekly_returns 
    WHERE week_start < '2024-10-01'
)
SELECT 
    w.week_start,
    w.LOT_ID,
    w.REGION,
    w.returned_units,
    ROUND(w.total_cost, 0) AS cost_usd,
    ROUND(b.avg_baseline, 1) AS baseline,
    ROUND(w.returned_units / NULLIF(b.avg_baseline, 0), 1) AS spike_multiplier,
    CASE 
        WHEN w.returned_units >= 3 * b.avg_baseline THEN '🚨 ANOMALY DETECTED'
        WHEN w.returned_units >= 2 * b.avg_baseline THEN '⚠️ Elevated'
        ELSE 'Normal'
    END AS status
FROM weekly_returns w
CROSS JOIN baseline b
WHERE w.week_start >= '2024-10-01'
ORDER BY w.week_start, w.returned_units DESC;

-- Final success message
SELECT '🎉 PAWCORE DATA SETUP COMPLETE! 🎉' as status,
       'Database: PAWCORE_INTELLIGENCE_DEMO' as database_info,
       'Ready for semantic views and agent creation!' as next_steps;
