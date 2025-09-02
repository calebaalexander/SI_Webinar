-- ========================================================================
-- Snowflake Intelligence Webinar - Data Loading Script
-- PawCore Systems Pet Wellness Demo Environment
-- This script loads the PawCore Systems sales and team communication data
-- ========================================================================

USE ROLE PAWCORE_WEBINAR_ROLE;
USE DATABASE PAWCORE_INTELLIGENCE_DEMO;
USE SCHEMA BUSINESS_DATA;

-- ========================================================================
-- CREATE TABLES FOR PAWCORE DATA
-- ========================================================================

-- Create PawCore Systems Sales table
CREATE OR REPLACE TABLE PAWCORE_SALES (
    DATE DATE NOT NULL,
    REGION VARCHAR(50) NOT NULL,
    PRODUCT VARCHAR(100) NOT NULL,
    FORECAST_SALES DECIMAL(10,2) NOT NULL,
    ACTUAL_SALES DECIMAL(10,2) NOT NULL,
    VARIANCE DECIMAL(10,2) NOT NULL,
    PCT_OF_FORECAST DECIMAL(5,2) NOT NULL,
    INVENTORY_UNITS_AVAILABLE INTEGER NOT NULL,
    MARKETING_ENGAGEMENT_SCORE INTEGER NOT NULL,
    SALE_ID INTEGER AUTOINCREMENT PRIMARY KEY
);

-- Create Team Communications table
CREATE OR REPLACE TABLE TEAM_COMMUNICATIONS (
    URL VARCHAR(500) NOT NULL,
    SLACK_CHANNEL VARCHAR(100) NOT NULL,
    THREAD_ID VARCHAR(50) NOT NULL,
    TEXT TEXT NOT NULL,
    MESSAGE_ID INTEGER AUTOINCREMENT PRIMARY KEY
);

-- Create Product Dimension table
CREATE OR REPLACE TABLE PRODUCT_DIM (
    PRODUCT_KEY INTEGER PRIMARY KEY,
    PRODUCT_NAME VARCHAR(200) NOT NULL,
    PRODUCT_CATEGORY VARCHAR(100) NOT NULL,
    PRODUCT_VERTICAL VARCHAR(50) NOT NULL
);

-- Create Region Dimension table
CREATE OR REPLACE TABLE REGION_DIM (
    REGION_KEY INTEGER PRIMARY KEY,
    REGION_NAME VARCHAR(100) NOT NULL,
    REGION_TYPE VARCHAR(50) NOT NULL
);

-- Create Customer Dimension table
CREATE OR REPLACE TABLE CUSTOMER_DIM (
    CUSTOMER_KEY INTEGER PRIMARY KEY,
    CUSTOMER_NAME VARCHAR(200) NOT NULL,
    CUSTOMER_TYPE VARCHAR(100) NOT NULL,
    CUSTOMER_SEGMENT VARCHAR(50) NOT NULL
);

-- Create HR Resumes table for hiring bonus demo
CREATE OR REPLACE TABLE HR_RESUMES (
    CANDIDATE_NAME VARCHAR(200) NOT NULL,
    RESUME_TEXT TEXT NOT NULL,
    APPLICATION_DATE DATE NOT NULL,
    POSITION_APPLIED VARCHAR(100) NOT NULL
);

-- ========================================================================
-- LOAD DIMENSION DATA
-- ========================================================================

-- Load Product Dimension data
INSERT INTO PRODUCT_DIM (PRODUCT_KEY, PRODUCT_NAME, PRODUCT_CATEGORY, PRODUCT_VERTICAL) VALUES
(1, 'PawCore Systems PetTracker', 'Pet Tracking', 'Pet Wellness'),
(2, 'PawCore Systems HealthMonitor', 'Health Monitoring', 'Pet Wellness'),
(3, 'PawCore Systems SmartCollar', 'Smart Collar', 'Pet Wellness');

-- Load Region Dimension data
INSERT INTO REGION_DIM (REGION_KEY, REGION_NAME, REGION_TYPE) VALUES
(1, 'North America', 'Primary Market'),
(2, 'Europe', 'Secondary Market'),
(3, 'Asia Pacific', 'Emerging Market');

-- Load Customer Dimension data (sample data)
INSERT INTO CUSTOMER_DIM (CUSTOMER_KEY, CUSTOMER_NAME, CUSTOMER_TYPE, CUSTOMER_SEGMENT) VALUES
(1, 'PetSmart Inc.', 'Enterprise', 'Premium'),
(2, 'VetCorp International', 'Enterprise', 'Premium'),
(3, 'PetCo Retail', 'Enterprise', 'Standard'),
(4, 'Individual Pet Owner', 'Consumer', 'Standard');

-- ========================================================================
-- LOAD PAWCORE SALES DATA
-- ========================================================================

-- Load PawCore Systems sales data from CSV
COPY INTO PAWCORE_SALES (DATE, REGION, PRODUCT, FORECAST_SALES, ACTUAL_SALES, VARIANCE, PCT_OF_FORECAST, INVENTORY_UNITS_AVAILABLE, MARKETING_ENGAGEMENT_SCORE)
FROM @INTERNAL_DATA_STAGE/pawcore_sales.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

-- ========================================================================
-- LOAD TEAM COMMUNICATIONS DATA
-- ========================================================================

-- Load team communications data from CSV
COPY INTO TEAM_COMMUNICATIONS (URL, SLACK_CHANNEL, THREAD_ID, TEXT)
FROM @INTERNAL_DATA_STAGE/pawcore_slack.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

-- ========================================================================
-- DATA VERIFICATION
-- ========================================================================

-- Verify data loads
SELECT 'PAWCORE_SALES' as table_name, COUNT(*) as row_count FROM PAWCORE_SALES
UNION ALL
SELECT 'TEAM_COMMUNICATIONS' as table_name, COUNT(*) as row_count FROM TEAM_COMMUNICATIONS
UNION ALL
SELECT 'PRODUCT_DIM' as table_name, COUNT(*) as row_count FROM PRODUCT_DIM
UNION ALL
SELECT 'REGION_DIM' as table_name, COUNT(*) as row_count FROM REGION_DIM
UNION ALL
SELECT 'CUSTOMER_DIM' as table_name, COUNT(*) as row_count FROM CUSTOMER_DIM
UNION ALL
SELECT 'HR_RESUMES' as table_name, COUNT(*) as row_count FROM HR_RESUMES;

-- Sample data verification
SELECT 'Sales Data Sample' as verification_type, 
       MIN(DATE) as earliest_date, 
       MAX(DATE) as latest_date,
       COUNT(DISTINCT REGION) as regions,
       COUNT(DISTINCT PRODUCT) as products
FROM PAWCORE_SALES;

SELECT 'Team Communications Sample' as verification_type,
       COUNT(DISTINCT SLACK_CHANNEL) as channels,
       COUNT(DISTINCT THREAD_ID) as threads,
       COUNT(*) as total_messages
FROM TEAM_COMMUNICATIONS;

-- Load HR Resumes data
COPY INTO HR_RESUMES (CANDIDATE_NAME, RESUME_TEXT, APPLICATION_DATE, POSITION_APPLIED)
FROM @INTERNAL_DATA_STAGE/hr_resumes.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

-- Show all tables
SHOW TABLES IN SCHEMA BUSINESS_DATA; 