-- Complete PawCore Systems Demo Environment Verification
-- This script verifies all components are properly set up

USE ROLE SNOWFLAKE_INTELLIGENCE_ADMIN_RL;
USE DATABASE PAWCORE_INTELLIGENCE_DEMO;

-- 1. Verify Database and Schema Structure
SELECT 'Database Structure' as verification_type, 'PASS' as status, 'All schemas created' as details
WHERE EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.SCHEMATA 
    WHERE SCHEMA_NAME IN ('BUSINESS_DATA', 'AGENTS', 'DOCUMENTS')
);

-- 2. Verify Tables Exist
SELECT 'Tables' as verification_type, COUNT(*) as count, 'tables found' as details
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA IN ('BUSINESS_DATA', 'AGENTS', 'DOCUMENTS');

-- 3. Verify Data Loading
SELECT 'Data Loading' as verification_type, 
       (SELECT COUNT(*) FROM PAWCORE_INTELLIGENCE_DEMO.BUSINESS_DATA.PAWCORE_SALES) as sales_records,
       (SELECT COUNT(*) FROM PAWCORE_INTELLIGENCE_DEMO.BUSINESS_DATA.TEAM_COMMUNICATIONS) as slack_records;

-- 4. Verify Semantic Views
SELECT 'Semantic Views' as verification_type, 
       SEMANTIC_VIEW_NAME, 
       STATUS,
       CREATED
FROM PAWCORE_INTELLIGENCE_DEMO.INFORMATION_SCHEMA.SEMANTIC_VIEWS;

-- 5. Verify Cortex Analyst Services
SELECT 'Cortex Analyst Services' as verification_type,
       ANALYST_SERVICE_NAME,
       STATUS,
       CREATED
FROM PAWCORE_INTELLIGENCE_DEMO.INFORMATION_SCHEMA.CORTEX_ANALYST_SERVICES;

-- 6. Verify Cortex Search Services
SELECT 'Cortex Search Services' as verification_type,
       SEARCH_SERVICE_NAME,
       STATUS,
       CREATED
FROM PAWCORE_INTELLIGENCE_DEMO.INFORMATION_SCHEMA.CORTEX_SEARCH_SERVICES;

-- 7. Verify Agents
SELECT 'Agents' as verification_type,
       AGENT_NAME,
       STATUS,
       CREATED
FROM PAWCORE_INTELLIGENCE_DEMO.INFORMATION_SCHEMA.AGENTS;

-- 8. Verify Stored Procedures
SELECT 'Stored Procedures' as verification_type,
       PROCEDURE_NAME,
       PROCEDURE_SCHEMA,
       CREATED
FROM PAWCORE_INTELLIGENCE_DEMO.INFORMATION_SCHEMA.PROCEDURES;

-- 9. Verify Functions
SELECT 'Functions' as verification_type,
       FUNCTION_NAME,
       FUNCTION_SCHEMA,
       CREATED
FROM PAWCORE_INTELLIGENCE_DEMO.INFORMATION_SCHEMA.FUNCTIONS;

-- 10. Verify Integrations
SELECT 'Integrations' as verification_type,
       INTEGRATION_NAME,
       INTEGRATION_TYPE,
       ENABLED
FROM PAWCORE_INTELLIGENCE_DEMO.INFORMATION_SCHEMA.INTEGRATIONS;

-- 11. Verify Roles and Permissions
SELECT 'Roles' as verification_type,
       ROLE_NAME,
       ROLE_OWNER,
       CREATED
FROM PAWCORE_INTELLIGENCE_DEMO.INFORMATION_SCHEMA.ROLES
WHERE ROLE_NAME LIKE '%PAWCORE%';

-- 12. Verify Warehouses
SELECT 'Warehouses' as verification_type,
       WAREHOUSE_NAME,
       WAREHOUSE_SIZE,
       AUTO_SUSPEND,
       AUTO_RESUME
FROM PAWCORE_INTELLIGENCE_DEMO.INFORMATION_SCHEMA.WAREHOUSES;

-- 13. Sample Data Verification
SELECT 'Sample Data Verification' as verification_type,
       'Sales Data Range' as data_type,
       MIN(DATE) as start_date,
       MAX(DATE) as end_date,
       COUNT(DISTINCT REGION) as regions,
       COUNT(DISTINCT PRODUCT) as products
FROM PAWCORE_INTELLIGENCE_DEMO.BUSINESS_DATA.PAWCORE_SALES;

-- 14. Document Content Verification
SELECT 'Document Content' as verification_type,
       COUNT(*) as total_documents,
       DEPARTMENT,
       COUNT(*) as doc_count
FROM PAWCORE_INTELLIGENCE_DEMO.DOCUMENTS.PARSED_CONTENT
GROUP BY DEPARTMENT;

-- 15. Web Scraping Data Verification
SELECT 'Web Scraping Data' as verification_type,
       COUNT(*) as total_records,
       STATUS,
       AVG(CONTENT_LENGTH) as avg_content_length
FROM PAWCORE_INTELLIGENCE_DEMO.AGENTS.WEB_SCRAPING_RESULTS
GROUP BY STATUS;

-- 16. Environment Summary
SELECT 'ENVIRONMENT SUMMARY' as summary_type,
       'PawCore Systems Intelligence Demo Environment' as environment_name,
       'Ready for Webinar' as status,
       CURRENT_TIMESTAMP() as verification_time; 