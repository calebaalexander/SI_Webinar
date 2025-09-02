-- Fix Document Stage and Setup Correct Workflow
-- This script creates the missing stage and sets up the proper data loading approach

USE ROLE ACCOUNTADMIN;
USE DATABASE PAWCORE_INTELLIGENCE_DEMO;
USE SCHEMA DOCUMENTS;
USE WAREHOUSE PAWCORE_INTELLIGENCE_WH;

-- Step 1: Create the missing DOCUMENT_STAGE
CREATE OR REPLACE STAGE DOCUMENT_STAGE;

-- Step 2: Verify the stage exists
SHOW STAGES;

-- Step 3: List files in the stage (after you upload them)
SELECT * FROM DIRECTORY(@DOCUMENT_STAGE);

-- Step 4: Create tables for unstructured data
CREATE OR REPLACE TABLE SLACK_MESSAGES (
    MESSAGE_ID STRING,
    CHANNEL STRING,
    AUTHOR STRING,
    MESSAGE_TEXT STRING,
    TIMESTAMP TIMESTAMP,
    SENTIMENT STRING
);

CREATE OR REPLACE TABLE CUSTOMER_REVIEWS (
    REVIEW_ID STRING,
    DATE DATE,
    PRODUCT STRING,
    CUSTOMER_NAME STRING,
    RATING INTEGER,
    REVIEW_TEXT STRING,
    SENTIMENT STRING,
    REVIEW_CATEGORY STRING,
    VERIFIED_PURCHASE STRING,
    HELPFUL_VOTES INTEGER,
    REVIEW_LENGTH INTEGER,
    REGION STRING,
    CUSTOMER_SEGMENT STRING
);

-- Step 5: Load CSV data (only CSV files, not markdown)
-- Load Slack messages
COPY INTO SLACK_MESSAGES
FROM @DOCUMENT_STAGE/pawcore_slack.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

-- Load customer reviews
COPY INTO CUSTOMER_REVIEWS
FROM @DOCUMENT_STAGE/customer_reviews.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

-- Step 6: Handle the markdown file differently
-- The Quarterly_Sales_Speech_PawCore.md should be processed through Document AI
-- or manually converted to a table. For now, let's create a simple transcript table:

CREATE OR REPLACE TABLE CALL_TRANSCRIPT (
    SEGMENT_ID STRING,
    SPEAKER STRING,
    TEXT STRING,
    TIMESTAMP TIMESTAMP,
    SENTIMENT STRING
);

-- Step 7: Verify data loading
SELECT 'SLACK_MESSAGES' as table_name, COUNT(*) as row_count FROM SLACK_MESSAGES
UNION ALL
SELECT 'CUSTOMER_REVIEWS', COUNT(*) FROM CUSTOMER_REVIEWS
UNION ALL
SELECT 'CALL_TRANSCRIPT', COUNT(*) FROM CALL_TRANSCRIPT
ORDER BY table_name;

-- Note: For the Quarterly_Sales_Speech_PawCore.md file:
-- Option 1: Process through Document AI in the UI
-- Option 2: Manually create a table with the transcript content
-- Option 3: Convert the markdown to CSV format first
