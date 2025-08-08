-- Snowflake Intelligence Email Integration Setup
-- This script sets up email sending capabilities for the PawCore Systems webinar demo

USE ROLE ACCOUNTADMIN;

-- Grant necessary permissions for notification integration
GRANT CREATE INTEGRATION ON ACCOUNT TO ROLE SNOWFLAKE_INTELLIGENCE_ADMIN_RL;

USE ROLE SNOWFLAKE_INTELLIGENCE_ADMIN_RL;

-- Create notification integration for email sending
CREATE OR REPLACE NOTIFICATION INTEGRATION PAWCORE_EMAIL_INT
  TYPE = EMAIL
  ENABLED = TRUE
  COMMENT = 'Email integration for PawCore Systems webinar demo notifications';

-- Create stored procedure for sending emails
CREATE OR REPLACE PROCEDURE PAWCORE_INTELLIGENCE_DEMO.AGENTS.SEND_MAIL(
    recipient TEXT, 
    subject TEXT, 
    content TEXT
)
RETURNS TEXT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'send_mail'
AS
$$
def send_mail(session, recipient, subject, content):
    """
    Send an email using Snowflake's email integration.
    
    Args:
        session: Snowflake session
        recipient: Email address to send to
        subject: Email subject line
        content: Email content (HTML format recommended)
    
    Returns:
        Confirmation message
    """
    try:
        session.call(
            'SYSTEM$SEND_EMAIL',
            'PAWCORE_EMAIL_INT',
            recipient,
            subject,
            content,
            'text/html'
        )
        return f'Email successfully sent to {recipient} with subject: "{subject}"'
    except Exception as e:
        return f'Error sending email: {str(e)}'
$$;

-- Grant execute permissions on the stored procedure
GRANT EXECUTE ON PROCEDURE PAWCORE_INTELLIGENCE_DEMO.AGENTS.SEND_MAIL(TEXT, TEXT, TEXT) TO ROLE PAWCORE_WEBINAR_ROLE;

-- Test the email functionality
-- CALL PAWCORE_INTELLIGENCE_DEMO.AGENTS.SEND_MAIL(
--     'test@example.com', 
--     'PawCore Systems Webinar Demo - Email Test', 
--     '<h2>Test Email from Snowflake Intelligence</h2><p>This is a test email sent from the PawCore Systems webinar demo environment.</p>'
-- );

-- Create a helper function for formatting email content
CREATE OR REPLACE FUNCTION PAWCORE_INTELLIGENCE_DEMO.AGENTS.FORMAT_EMAIL_CONTENT(
    title TEXT,
    body_content TEXT,
    footer_text TEXT DEFAULT 'Sent from Snowflake Intelligence'
)
RETURNS TEXT
AS
$$
SELECT CONCAT(
    '<!DOCTYPE html>',
    '<html><head><meta charset="UTF-8">',
    '<style>',
    'body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }',
    '.header { background-color: #1f4e79; color: white; padding: 20px; text-align: center; }',
    '.content { padding: 20px; background-color: #f9f9f9; }',
    '.footer { background-color: #e8e8e8; padding: 15px; text-align: center; font-size: 12px; color: #666; }',
    '</style></head>',
    '<body>',
    '<div class="header"><h1>', title, '</h1></div>',
    '<div class="content">', body_content, '</div>',
    '<div class="footer">', footer_text, '</div>',
    '</body></html>'
)
$$;

-- Grant execute permissions on the helper function
GRANT EXECUTE ON FUNCTION PAWCORE_INTELLIGENCE_DEMO.AGENTS.FORMAT_EMAIL_CONTENT(TEXT, TEXT, TEXT) TO ROLE PAWCORE_WEBINAR_ROLE;

-- Verification queries
SELECT 
    'Notification Integration' as component,
    INTEGRATION_NAME,
    INTEGRATION_TYPE,
    ENABLED
FROM SNOWFLAKE.ACCOUNT_USAGE.INTEGRATIONS 
WHERE INTEGRATION_NAME = 'PAWCORE_EMAIL_INT';

SELECT 
    'Stored Procedure' as component,
    PROCEDURE_NAME,
    PROCEDURE_LANGUAGE,
    RUNTIME_VERSION
FROM PAWCORE_INTELLIGENCE_DEMO.INFORMATION_SCHEMA.PROCEDURES 
WHERE PROCEDURE_NAME = 'SEND_MAIL';

SELECT 
    'Helper Function' as component,
    FUNCTION_NAME,
    FUNCTION_LANGUAGE
FROM PAWCORE_INTELLIGENCE_DEMO.INFORMATION_SCHEMA.FUNCTIONS 
WHERE FUNCTION_NAME = 'FORMAT_EMAIL_CONTENT'; 