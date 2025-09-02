-- PawCore Systems Business Intelligence Agent Setup
-- This script creates the main Snowflake Intelligence Agent for the webinar

USE ROLE SNOWFLAKE_INTELLIGENCE_ADMIN_RL;
USE DATABASE PAWCORE_INTELLIGENCE_DEMO;
USE SCHEMA AGENTS;

-- Create the main PawCore Systems Business Intelligence Agent
CREATE OR REPLACE AGENT PAWCORE_BI_AGENT
WITH PROFILE='{"display_name": "PawCore Systems Pet Wellness Intelligence Agent", "description": "Multi-domain business intelligence agent for comprehensive PawCore Systems analysis"}'
COMMENT='Multi-domain business intelligence agent for PawCore Systems pet wellness technology company providing sales, marketing, operations, finance, and HR insights'
FROM SPECIFICATION $$
{
  "models": {
    "orchestration": "snowflake-arctic-2.0"
  },
  "instructions": "You are the PawCore Systems Business Intelligence Agent, an expert AI assistant for PawCore Systems Pet Wellness technology company. Your role is to provide comprehensive business intelligence across all domains including sales, marketing, operations, finance, and HR. You excel at analyzing structured data through semantic views and unstructured data through document search. Always provide data-driven insights with actionable recommendations. When analyzing data, automatically generate visualizations including charts and graphs. Present findings in a clear, professional manner suitable for business stakeholders. When referencing team communications or documents, present insights naturally without including reference markers or citation numbers. Focus on delivering practical business value and strategic insights that support decision-making.",
  "tools": [
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "Query Sales Performance",
        "description": "Analyze PawCore Systems sales data including revenue, forecasts, regional performance, and product trends. Use this for sales analysis, forecasting, and performance optimization.",
        "parameters": {
          "cortex_analyst_service": "Analyst_PawCore Systems_Sales_Performance"
        }
      }
    },
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "Query Financial Data",
        "description": "Analyze PawCore Systems financial data including revenue, costs, profitability, and budget performance. Use this for financial analysis, cost optimization, and profitability insights.",
        "parameters": {
          "cortex_analyst_service": "Analyst_PawCore Systems_Financial_Data"
        }
      }
    },
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "Query Marketing Metrics",
        "description": "Analyze PawCore Systems marketing data including campaign performance, engagement metrics, and ROI analysis. Use this for marketing optimization and campaign effectiveness.",
        "parameters": {
          "cortex_analyst_service": "Analyst_PawCore Systems_Marketing_Metrics"
        }
      }
    },
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "Query Regional Analysis",
        "description": "Analyze PawCore Systems regional performance data across North America, Europe, and Asia Pacific. Use this for market analysis and geographic insights.",
        "parameters": {
          "cortex_analyst_service": "Analyst_PawCore Systems_Regional_Analysis"
        }
      }
    },
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "Query Product Analysis",
        "description": "Analyze PawCore Systems product performance data for PetTracker, HealthMonitor, and SmartCollar. Use this for product insights and optimization.",
        "parameters": {
          "cortex_analyst_service": "Analyst_PawCore Systems_Product_Analysis"
        }
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "Search Finance Documents",
        "description": "Search PawCore Systems finance documents including reports, policies, and financial analysis. Use this for financial insights and policy information.",
        "parameters": {
          "cortex_search_service": "Search_PawCore Systems_Finance_Docs"
        }
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "Search Sales Documents",
        "description": "Search PawCore Systems sales documents including playbooks, success stories, and performance reports. Use this for sales methodology and customer insights.",
        "parameters": {
          "cortex_search_service": "Search_PawCore Systems_Sales_Docs"
        }
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "Search Marketing Documents",
        "description": "Search PawCore Systems marketing documents including strategies, campaigns, and customer analysis. Use this for marketing insights and campaign optimization.",
        "parameters": {
          "cortex_search_service": "Search_PawCore Systems_Marketing_Docs"
        }
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "Search Operations Documents",
        "description": "Search PawCore Systems operations documents including procedures, policies, and process documentation. Use this for operational insights and process optimization.",
        "parameters": {
          "cortex_search_service": "Search_PawCore Systems_Operations_Docs"
        }
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "Search Product Documents",
        "description": "Search PawCore Systems product documents including manuals, specifications, and technical documentation. Use this for product insights and technical information.",
        "parameters": {
          "cortex_search_service": "Search_PawCore Systems_Product_Docs"
        }
      }
    },
    {
      "tool_spec": {
        "type": "procedure",
        "name": "Send Email Report",
        "description": "Send automated email reports with business insights and visualizations to stakeholders. Use this for automated reporting and stakeholder communication.",
        "parameters": {
          "procedure": "PAWCORE_INTELLIGENCE_DEMO.AGENTS.SEND_MAIL"
        }
      }
    },
    {
      "tool_spec": {
        "type": "procedure",
        "name": "Web Scrape Content",
        "description": "Scrape web content for market research, competitive intelligence, and external data analysis. Use this for gathering external market insights and competitive analysis.",
        "parameters": {
          "procedure": "PAWCORE_INTELLIGENCE_DEMO.AGENTS.WEB_SCRAPE"
        }
      }
    }
  ]
}
$$;

-- Grant permissions for the agent
GRANT USAGE ON AGENT PAWCORE_BI_AGENT TO ROLE PAWCORE_WEBINAR_ROLE;

-- Verification query
SELECT 
    'Main Agent Created' as status,
    AGENT_NAME,
    CREATED,
    STATUS
FROM PAWCORE_INTELLIGENCE_DEMO.INFORMATION_SCHEMA.AGENTS 
WHERE AGENT_NAME = 'PAWCORE_BI_AGENT'; 