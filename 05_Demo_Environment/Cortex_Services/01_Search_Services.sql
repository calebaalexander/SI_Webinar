-- PawCore Systems Cortex Search Services Setup
-- This script creates Cortex Search services for unstructured document analysis

USE ROLE SNOWFLAKE_INTELLIGENCE_ADMIN_RL;
USE DATABASE PAWCORE_INTELLIGENCE_DEMO;
USE SCHEMA DOCUMENTS;

-- Create a table to store parsed document content
CREATE OR REPLACE TABLE PARSED_CONTENT (
    DOCUMENT_ID NUMBER AUTOINCREMENT PRIMARY KEY,
    RELATIVE_PATH VARCHAR(500) NOT NULL,
    FILE_URL VARCHAR(1000),
    TITLE VARCHAR(200),
    CONTENT TEXT,
    DOCUMENT_TYPE VARCHAR(50),
    DEPARTMENT VARCHAR(50),
    UPLOAD_DATE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Insert sample parsed document content
INSERT INTO PARSED_CONTENT (RELATIVE_PATH, FILE_URL, TITLE, CONTENT, DOCUMENT_TYPE, DEPARTMENT) VALUES
-- Finance Documents
('/finance/Q4_2024_PawCore Systems_Financial_Report.pdf', 'https://pawcore-docs.s3.amazonaws.com/finance/Q4_2024_PawCore Systems_Financial_Report.pdf', 'Q4 2024 Financial Report', 'Q4 2024 was a strong quarter for PawCore Systems Pet Wellness, with total revenue reaching $28,110 against a forecast of $28,099. The company achieved significant milestones including reaching 100,000 active pet tracking devices and implementing cost optimization strategies that reduced operational expenses by 8%.', 'PDF', 'Finance'),
('/finance/PawCore Systems_Expense_Policy_2025.pdf', 'https://pawcore-docs.s3.amazonaws.com/finance/PawCore Systems_Expense_Policy_2025.pdf', 'Expense Policy 2025', 'This policy outlines the guidelines for employee expenses including travel, meals, and business-related purchases. All expenses must be pre-approved for amounts over $500 and submitted within 30 days of purchase.', 'PDF', 'Finance'),
('/finance/Vendor_Management_Policy.pdf', 'https://pawcore-docs.s3.amazonaws.com/finance/Vendor_Management_Policy.pdf', 'Vendor Management Policy', 'Our vendor management policy ensures quality control and cost optimization through strategic supplier relationships. All vendors must meet our quality standards and provide competitive pricing.', 'PDF', 'Finance'),

-- Sales Documents
('/sales/PawCore Systems_Sales_Playbook_2025.pdf', 'https://pawcore-docs.s3.amazonaws.com/sales/PawCore Systems_Sales_Playbook_2025.pdf', 'Sales Playbook 2025', 'Our sales approach focuses on understanding pet owners needs and demonstrating how PawCore Systems products enhance pet safety, health monitoring, and owner peace of mind. We use a consultative selling approach with emphasis on value proposition and ROI.', 'PDF', 'Sales'),
('/sales/Customer_Success_Stories.pdf', 'https://pawcore-docs.s3.amazonaws.com/sales/Customer_Success_Stories.pdf', 'Customer Success Stories', 'Sarah dog was found within 2 hours using PetTracker. Mike cat health issue was detected early by HealthMonitor. Lisa puppy was trained in 2 weeks with SmartCollar.', 'PDF', 'Sales'),
('/sales/Sales_Performance_Q4_2024.pdf', 'https://pawcore-docs.s3.amazonaws.com/sales/Sales_Performance_Q4_2024.pdf', 'Sales Performance Q4 2024', 'Q4 2024 sales performance shows strong growth across all regions. PetTracker exceeded forecast by 15% in North America. European market expansion is progressing well with 12.8% growth.', 'PDF', 'Sales'),

-- Marketing Documents
('/marketing/2025_PawCore Systems_Marketing_Strategy.pdf', 'https://pawcore-docs.s3.amazonaws.com/marketing/2025_PawCore Systems_Marketing_Strategy.pdf', 'Marketing Strategy 2025', 'Our 2025 marketing strategy focuses on expanding market share through targeted campaigns, enhanced digital presence, and strategic partnerships. We aim to increase brand awareness by 40% and achieve 25% revenue growth.', 'PDF', 'Marketing'),
('/marketing/Campaign_Performance_Report.pdf', 'https://pawcore-docs.s3.amazonaws.com/marketing/Campaign_Performance_Report.pdf', 'Campaign Performance Report', 'PetTracker launch campaign exceeded expectations by 20%. Google Ads showing highest ROI at 300%. Email marketing has lowest customer acquisition cost. Never Lose Your Pet Again messaging resonates strongest.', 'PDF', 'Marketing'),
('/marketing/Pet_Owner_Persona_Analysis.pdf', 'https://pawcore-docs.s3.amazonaws.com/marketing/Pet_Owner_Persona_Analysis.pdf', 'Pet Owner Persona Analysis', 'Primary target: Pet parents aged 25-45 with disposable income. Secondary target: Multi-pet households and pet professionals. Pain points include worry about pet safety and desire for health monitoring.', 'PDF', 'Marketing'),

-- Operations Documents
('/operations/Supply_Chain_Management.pdf', 'https://pawcore-docs.s3.amazonaws.com/operations/Supply_Chain_Management.pdf', 'Supply Chain Management', 'Our supply chain is designed to ensure reliable product delivery while maintaining quality standards and cost efficiency. Recent improvements include 8% cost reduction through new supplier partnerships.', 'PDF', 'Operations'),
('/operations/Quality_Control_Procedures.pdf', 'https://pawcore-docs.s3.amazonaws.com/operations/Quality_Control_Procedures.pdf', 'Quality Control Procedures', 'Quality testing includes functional testing, durability testing, water resistance, battery life, and GPS accuracy. Target defect rate is less than 0.5% with current performance at 0.4%.', 'PDF', 'Operations'),
('/operations/Customer_Support_Playbook.pdf', 'https://pawcore-docs.s3.amazonaws.com/operations/Customer_Support_Playbook.pdf', 'Customer Support Playbook', 'Our customer support approach focuses on quick resolution, product education, and customer satisfaction. Support team handles technical issues, product questions, and warranty claims.', 'PDF', 'Operations'),

-- Product Documents
('/product/PetTracker_User_Manual.pdf', 'https://pawcore-docs.s3.amazonaws.com/product/PetTracker_User_Manual.pdf', 'PetTracker User Manual', 'The PetTracker is a GPS-enabled pet tracking device that provides real-time location monitoring and activity tracking. Features include real-time GPS tracking, geofencing capabilities, activity monitoring, and long battery life up to 30 days.', 'PDF', 'Product'),
('/product/HealthMonitor_Technical_Specs.pdf', 'https://pawcore-docs.s3.amazonaws.com/product/HealthMonitor_Technical_Specs.pdf', 'HealthMonitor Technical Specifications', 'The HealthMonitor provides advanced pet health monitoring with vital signs tracking, health alerts, and vet integration. Technical specifications include heart rate monitoring, temperature tracking, and activity analysis.', 'PDF', 'Product'),
('/product/SmartCollar_Installation_Guide.pdf', 'https://pawcore-docs.s3.amazonaws.com/product/SmartCollar_Installation_Guide.pdf', 'SmartCollar Installation Guide', 'The SmartCollar provides gentle training and behavior modification. Installation includes charging the device, downloading the PawCore Systems app, registering your account, pairing the device, and attaching to your pets collar.', 'PDF', 'Product');

-- Create Cortex Search Service for Finance Documents
CREATE OR REPLACE CORTEX SEARCH SERVICE Search_PawCore Systems_Finance_Docs
ON content
ATTRIBUTES relative_path, file_url, title
WAREHOUSE = PAWCORE_INTELLIGENCE_WH
EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
AS (
    SELECT relative_path, file_url, title, content
    FROM PARSED_CONTENT
    WHERE relative_path ILIKE '%/finance/%'
);

-- Create Cortex Search Service for Sales Documents
CREATE OR REPLACE CORTEX SEARCH SERVICE Search_PawCore Systems_Sales_Docs
ON content
ATTRIBUTES relative_path, file_url, title
WAREHOUSE = PAWCORE_INTELLIGENCE_WH
EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
AS (
    SELECT relative_path, file_url, title, content
    FROM PARSED_CONTENT
    WHERE relative_path ILIKE '%/sales/%'
);

-- Create Cortex Search Service for Marketing Documents
CREATE OR REPLACE CORTEX SEARCH SERVICE Search_PawCore Systems_Marketing_Docs
ON content
ATTRIBUTES relative_path, file_url, title
WAREHOUSE = PAWCORE_INTELLIGENCE_WH
EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
AS (
    SELECT relative_path, file_url, title, content
    FROM PARSED_CONTENT
    WHERE relative_path ILIKE '%/marketing/%'
);

-- Create Cortex Search Service for Operations Documents
CREATE OR REPLACE CORTEX SEARCH SERVICE Search_PawCore Systems_Operations_Docs
ON content
ATTRIBUTES relative_path, file_url, title
WAREHOUSE = PAWCORE_INTELLIGENCE_WH
EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
AS (
    SELECT relative_path, file_url, title, content
    FROM PARSED_CONTENT
    WHERE relative_path ILIKE '%/operations/%'
);

-- Create Cortex Search Service for Product Documents
CREATE OR REPLACE CORTEX SEARCH SERVICE Search_PawCore Systems_Product_Docs
ON content
ATTRIBUTES relative_path, file_url, title
WAREHOUSE = PAWCORE_INTELLIGENCE_WH
EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
AS (
    SELECT relative_path, file_url, title, content
    FROM PARSED_CONTENT
    WHERE relative_path ILIKE '%/product/%'
);

-- Grant permissions for Cortex Search services
GRANT USAGE ON CORTEX SEARCH SERVICE Search_PawCore Systems_Finance_Docs TO ROLE PAWCORE_WEBINAR_ROLE;
GRANT USAGE ON CORTEX SEARCH SERVICE Search_PawCore Systems_Sales_Docs TO ROLE PAWCORE_WEBINAR_ROLE;
GRANT USAGE ON CORTEX SEARCH SERVICE Search_PawCore Systems_Marketing_Docs TO ROLE PAWCORE_WEBINAR_ROLE;
GRANT USAGE ON CORTEX SEARCH SERVICE Search_PawCore Systems_Operations_Docs TO ROLE PAWCORE_WEBINAR_ROLE;
GRANT USAGE ON CORTEX SEARCH SERVICE Search_PawCore Systems_Product_Docs TO ROLE PAWCORE_WEBINAR_ROLE;

-- Verification queries
SELECT 
    'Finance Search Service' as service_name,
    SEARCH_SERVICE_NAME,
    STATUS
FROM PAWCORE_INTELLIGENCE_DEMO.INFORMATION_SCHEMA.CORTEX_SEARCH_SERVICES 
WHERE SEARCH_SERVICE_NAME = 'Search_PawCore Systems_Finance_Docs';

SELECT 
    'Sales Search Service' as service_name,
    SEARCH_SERVICE_NAME,
    STATUS
FROM PAWCORE_INTELLIGENCE_DEMO.INFORMATION_SCHEMA.CORTEX_SEARCH_SERVICES 
WHERE SEARCH_SERVICE_NAME = 'Search_PawCore Systems_Sales_Docs';

SELECT 
    'Marketing Search Service' as service_name,
    SEARCH_SERVICE_NAME,
    STATUS
FROM PAWCORE_INTELLIGENCE_DEMO.INFORMATION_SCHEMA.CORTEX_SEARCH_SERVICES 
WHERE SEARCH_SERVICE_NAME = 'Search_PawCore Systems_Marketing_Docs';

SELECT 
    'Operations Search Service' as service_name,
    SEARCH_SERVICE_NAME,
    STATUS
FROM PAWCORE_INTELLIGENCE_DEMO.INFORMATION_SCHEMA.CORTEX_SEARCH_SERVICES 
WHERE SEARCH_SERVICE_NAME = 'Search_PawCore Systems_Operations_Docs';

SELECT 
    'Product Search Service' as service_name,
    SEARCH_SERVICE_NAME,
    STATUS
FROM PAWCORE_INTELLIGENCE_DEMO.INFORMATION_SCHEMA.CORTEX_SEARCH_SERVICES 
WHERE SEARCH_SERVICE_NAME = 'Search_PawCore Systems_Product_Docs'; 