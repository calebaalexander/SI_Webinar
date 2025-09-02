-- Enable Directory Tables for PawCore Hands-On Lab
-- This is needed for Document AI and unstructured file processing

USE ROLE ACCOUNTADMIN;

-- Enable Directory Tables at the account level
ALTER ACCOUNT SET ENABLE_DIRECTORY_TABLES = TRUE;

-- Verify the setting
SHOW PARAMETERS LIKE 'ENABLE_DIRECTORY_TABLES';

-- Alternative: Enable for specific databases if you prefer
-- ALTER DATABASE PAWCORE_INTELLIGENCE_DEMO SET ENABLE_DIRECTORY_TABLES = TRUE;

-- Test Directory Tables with your stages
-- This will show all files in your stages
SELECT * FROM DIRECTORY(@INTERNAL_DATA_STAGE);
SELECT * FROM DIRECTORY(@DOCUMENT_STAGE);
SELECT * FROM DIRECTORY(@IMAGE_STAGE);
SELECT * FROM DIRECTORY(@AUDIO_STAGE);

-- Example: List all PDF files in document stage
SELECT RELATIVE_PATH, SIZE, LAST_MODIFIED 
FROM DIRECTORY(@DOCUMENT_STAGE) 
WHERE RELATIVE_PATH LIKE '%.pdf';

-- Example: List all image files
SELECT RELATIVE_PATH, SIZE, LAST_MODIFIED 
FROM DIRECTORY(@IMAGE_STAGE) 
WHERE RELATIVE_PATH LIKE '%.jpeg' OR RELATIVE_PATH LIKE '%.png';

-- Note: After enabling, you may need to wait a few minutes for changes to take effect
