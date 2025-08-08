-- PawCore Systems Web Scraping Integration Setup
-- This script creates the web scraping capability for external data analysis

USE ROLE SNOWFLAKE_INTELLIGENCE_ADMIN_RL;
USE DATABASE PAWCORE_INTELLIGENCE_DEMO;
USE SCHEMA AGENTS;

-- Create web scraping stored procedure
CREATE OR REPLACE PROCEDURE PAWCORE_INTELLIGENCE_DEMO.AGENTS.WEB_SCRAPE(url TEXT, selector TEXT DEFAULT NULL)
RETURNS TEXT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.9'
HANDLER = 'web_scrape'
EXTERNAL_ACCESS_INTEGRATIONS = (PAWCORE_ExternalAccess_Integration)
PACKAGES = ('requests', 'beautifulsoup4', 'lxml')
AS $$
import requests
from bs4 import BeautifulSoup
import json

def web_scrape(snowpark_session, url, selector=None):
    try:
        # Make HTTP request to the URL
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        
        # Parse HTML content
        soup = BeautifulSoup(response.content, 'html.parser')
        
        # Extract content based on selector or get main content
        if selector:
            elements = soup.select(selector)
            content = ' '.join([elem.get_text(strip=True) for elem in elements])
        else:
            # Remove script and style elements
            for script in soup(["script", "style"]):
                script.decompose()
            
            # Get text content
            content = soup.get_text()
            
            # Clean up whitespace
            lines = (line.strip() for line in content.splitlines())
            chunks = (phrase.strip() for line in lines for phrase in line.split("  "))
            content = ' '.join(chunk for chunk in chunks if chunk)
        
        # Truncate content if too long
        if len(content) > 8000:
            content = content[:8000] + "... [Content truncated]"
        
        # Return structured result
        result = {
            "url": url,
            "title": soup.title.string if soup.title else "No title found",
            "content": content,
            "status": "success",
            "content_length": len(content)
        }
        
        return json.dumps(result, indent=2)
        
    except requests.exceptions.RequestException as e:
        return json.dumps({
            "url": url,
            "status": "error",
            "error": f"Request failed: {str(e)}"
        }, indent=2)
    except Exception as e:
        return json.dumps({
            "url": url,
            "status": "error", 
            "error": f"Scraping failed: {str(e)}"
        }, indent=2)
$$;

-- Create table to store web scraping results
CREATE OR REPLACE TABLE PAWCORE_INTELLIGENCE_DEMO.AGENTS.WEB_SCRAPING_RESULTS (
    SCRAPE_ID NUMBER AUTOINCREMENT PRIMARY KEY,
    URL VARCHAR(1000) NOT NULL,
    TITLE VARCHAR(500),
    CONTENT TEXT,
    SELECTOR VARCHAR(200),
    SCRAPE_DATE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    STATUS VARCHAR(50),
    CONTENT_LENGTH NUMBER,
    ERROR_MESSAGE TEXT
);

-- Create helper function to store web scraping results
CREATE OR REPLACE FUNCTION PAWCORE_INTELLIGENCE_DEMO.AGENTS.STORE_WEB_SCRAPE_RESULT(
    url TEXT, 
    title TEXT, 
    content TEXT, 
    selector TEXT, 
    status TEXT, 
    content_length NUMBER, 
    error_message TEXT
)
RETURNS TEXT
AS $$
BEGIN
    INSERT INTO PAWCORE_INTELLIGENCE_DEMO.AGENTS.WEB_SCRAPING_RESULTS (
        URL, TITLE, CONTENT, SELECTOR, STATUS, CONTENT_LENGTH, ERROR_MESSAGE
    ) VALUES (
        url, title, content, selector, status, content_length, error_message
    );
    RETURN 'Results stored successfully';
END;
$$;

-- Grant permissions
GRANT USAGE ON PROCEDURE PAWCORE_INTELLIGENCE_DEMO.AGENTS.WEB_SCRAPE TO ROLE PAWCORE_WEBINAR_ROLE;
GRANT SELECT, INSERT ON TABLE PAWCORE_INTELLIGENCE_DEMO.AGENTS.WEB_SCRAPING_RESULTS TO ROLE PAWCORE_WEBINAR_ROLE;
GRANT USAGE ON FUNCTION PAWCORE_INTELLIGENCE_DEMO.AGENTS.STORE_WEB_SCRAPE_RESULT TO ROLE PAWCORE_WEBINAR_ROLE;

-- Insert sample web scraping targets for PawCore Systems market research
INSERT INTO PAWCORE_INTELLIGENCE_DEMO.AGENTS.WEB_SCRAPING_RESULTS (URL, TITLE, CONTENT, STATUS, CONTENT_LENGTH) VALUES
('https://www.petindustry.com/market-trends-2024', 'Pet Industry Market Trends 2024', 'The pet technology market is experiencing significant growth with GPS tracking devices leading the segment. Pet owners are increasingly investing in smart pet products for safety and health monitoring. The market is expected to reach $15 billion by 2025 with strong adoption in North America and Europe.', 'success', 245),
('https://www.competitor-analysis.com/pet-trackers', 'Competitive Analysis: Pet Tracking Devices', 'Leading competitors in the pet tracking space include Whistle, Tractive, and Fi. Key differentiators include battery life, GPS accuracy, and mobile app features. Price points range from $99 to $299 with subscription models becoming standard.', 'success', 189),
('https://www.veterinary-technology.com/health-monitoring', 'Veterinary Technology Trends', 'Health monitoring devices for pets are gaining traction among veterinarians and pet owners. Key features include heart rate monitoring, activity tracking, and early warning systems. Integration with veterinary systems is becoming a competitive advantage.', 'success', 203);

-- Verification queries
SELECT 
    'Web Scraping Procedure Created' as status,
    PROCEDURE_NAME,
    PROCEDURE_SCHEMA,
    CREATED
FROM PAWCORE_INTELLIGENCE_DEMO.INFORMATION_SCHEMA.PROCEDURES 
WHERE PROCEDURE_NAME = 'WEB_SCRAPE';

SELECT 
    'Sample Web Scraping Results' as status,
    COUNT(*) as total_records,
    STATUS
FROM PAWCORE_INTELLIGENCE_DEMO.AGENTS.WEB_SCRAPING_RESULTS 
GROUP BY STATUS; 