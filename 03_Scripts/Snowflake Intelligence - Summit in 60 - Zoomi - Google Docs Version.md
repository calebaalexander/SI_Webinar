Document 2: Snowflake Intelligence Walkthrough (Demo) for Zoomi Pet Wellness

Presenter: Caleb Alexander, Product Manager, Snowflake 
Audience: Zoomi Pet Wellness Team 
Format: Shared Screen Demo (approx. 10 minutes)

---

Part 2: Snowflake Intelligence Walkthrough (Demo)

(0:00 - 0:45) Introduction: Welcome & Demo Goal

Speaker Notes:
• "Welcome back, everyone! I'm Caleb Alexander. In Part 1, we covered the concepts of Snowflake Intelligence. Now, it's time to get hands-on and see it in action – specifically for Zoomi Pet Wellness."
• "Today, I'll walk you through setting up your first agents. We'll build a 'Zoomi Business Insights Agent' from scratch, showing you precisely how to connect AI to your sales performance and team communication data, live in Snowflake."
• "I'm starting with a brand-new Snowflake trial account, just like you might. Let's jump in!"

(0:45 - 2:00) Initial Setup: Preparing the Environment

Speaker Notes:
• "When you first access Snowflake Intelligence, you might see 'No agents available.' (Show UI, 'No agents available'). Our first step is to prepare the environment."
• "All Snowflake Intelligence agents must reside in the SNOWFLAKE_INTELLIGENCE database and the AGENTS schema. If these don't exist, you'll get an error. (Briefly mention the 'database does not exist' error)."
• "To fix this, I'll quickly run some DDL commands in a new worksheet. (Open new worksheet, paste DDL commands, run as ACCOUNTADMIN)."

SQL Commands:
-- Ensure you are in ACCOUNTADMIN role for this initial setup
USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_INTELLIGENCE;
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_INTELLIGENCE.AGENTS;
GRANT USAGE ON DATABASE SNOWFLAKE_INTELLIGENCE TO PUBLIC;
GRANT USAGE ON SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS TO PUBLIC;
-- Optional: If needed for your region, enable cross-region inference
-- ALTER ACCOUNT SET EXTERNAL_ACCESS_ENABLED_REGIONS = ('AWS_US_EAST_1'); -- Example for AWS US

• "This sets up the required structure, making agents visible across your account. If your account is in a region not yet supporting AI models directly, you'd also enable cross-region inference here."

(2:00 - 4:00) Data Ingestion: Bringing Zoomi Data into Snowflake

Speaker Notes:
• "Now, let's get some Zoomi data into Snowflake. I've prepared two CSV files with your actual business data:"
  - "zoomi_sales.csv: Comprehensive sales data including forecast vs actual sales, regional performance, product lines (PetTracker, HealthMonitor, SmartCollar), inventory levels, and marketing engagement scores from 2018 through 2025."
  - "zoomi_slack.csv: Team communication data from Slack channels including sales updates, marketing campaign results, operations issues, product development updates, and general company announcements."
• "First, I'll create a new database and schema to organize this data within Snowflake. (Navigate to Databases, create ZOOMI_DEMO_DB database, then BUSINESS_DATA schema)."
• "Now, let's load our tables directly from these CSV files. (Navigate to Tables, Load Data from File)."
• "I'll load zoomi_sales.csv as SALES_PERFORMANCE. (Walk through CSV load, confirm types, emphasize column mapping for accuracy - note the DATE, REGION, PRODUCT, FORECAST_SALES, ACTUAL_SALES, VARIANCE, PCT_OF_FORECAST, INVENTORY_UNITS_AVAILABLE, MARKETING_ENGAGEMENT_SCORE columns)."
• "Next, I'll load zoomi_slack.csv as TEAM_COMMUNICATIONS. (Walk through CSV load, highlight 'has header' option, ensure URL, SLACK_CHANNEL, THREAD_ID, and TEXT columns are properly mapped)."
• "So now, we have our raw Zoomi sales performance and team communication data ready and available in Snowflake, spanning from your company's origin in 2018 through current times."

(4:00 - 7:00) Creating Cortex Services: Making Zoomi Data AI-Ready

Speaker Notes:
• "Remember from Part 1, our Agent doesn't directly query tables; it interacts with specialized Cortex services. We need to expose this Zoomi data through these services to make it AI-ready."

• "1. Cortex Search Service (for Team Communications):"
  - "For our unstructured Slack communications, we'll create a Cortex Search Service. (Navigate to AI/ML Studio -> Cortex Search -> Create Service)."
  - "We'll put it in our BUSINESS_DATA schema, name it Zoomi_Team_Search. I'll select the TEAM_COMMUNICATIONS table, choose the TEXT column as the primary text field, and include SLACK_CHANNEL and THREAD_ID as additional attributes for context and traceability." (Click 'Create service').
  - "This service will allow our agent to quickly search through thousands of team messages to identify trends, issues, and insights across sales, marketing, operations, and product teams."

• "2. Cortex Analyst Service (Semantic View for Sales Performance):"
  - "For our structured sales data, we use Cortex Analyst via a Semantic View. This is where we define the business context. (Navigate to AI/ML Studio -> Semantic View -> Create Semantic View)."
  - "Name it Zoomi_Sales_Performance_SV. I'll provide a detailed description here, which is crucial for the LLM to understand when to use this tool: 'This Semantic View provides comprehensive insights into Zoomi sales performance across all regions (North America, Europe, Asia Pacific) and product lines (PetTracker, HealthMonitor, SmartCollar), including forecast vs actual sales, variance analysis, inventory levels, and marketing engagement metrics from 2018 through 2025, enabling analysis of business trends, regional performance, and product success.'"
  - "I'll select the SALES_PERFORMANCE table and all relevant columns. (Show auto-suggested synonyms for columns like 'forecast_sales' or 'actual_sales', emphasizing how this simplifies AI interaction)."
  - "I'll also add a 'verified query' like 'Show me the sales performance by region for Zoomi PetTracker in Q1 2024, including forecast vs actual variance' to guide the agent towards common analytical patterns." (Save Semantic View).
  - "This Semantic View will enable our agent to generate precise SQL queries against your sales data using natural language."

(7:00 - 9:00) Building & Refining the Zoomi Business Insights Agent

Speaker Notes:
• "Now, let's bring it all together by creating our 'Zoomi Business Insights Agent.' (Navigate to Agents, Create Agent)."
• "Name it 'Zoomi Business Insights Agent'. (Fill in API Path, Display Name)."
• "Add the Zoomi_Sales_Performance_SV as a Cortex Analyst tool. (Select tool, choose Semantic View). Notice how it can auto-generate a description based on the Semantic View – this is key for the agent to know when to use this tool."
• "Next, add the Zoomi_Team_Search as a Cortex Search tool. (Select tool, choose Search Service). Provide a description: 'Provides an index of all Zoomi team communications from Slack channels including sales, marketing, operations, product, and general channels, useful for understanding team insights, project updates, and business trends.'" (Save Agent).

• "Debugging & Refining Permissions: (Briefly show the 'Access' tab). If you try to give another role access to this agent, and that role doesn't have permissions to the underlying Zoomi_Sales_Performance_SV or Zoomi_Team_Search service, you'll see a warning. This means you'd need to grant those permissions explicitly in a worksheet. This ensures data security and compliance."

• "Enhancing Agent Behavior (Orchestration/Planning Instructions): (Briefly show where these are). We can fine-tune the agent. For example, if we want it to always generate a chart when possible, we'd add an Orchestration Instruction: 'Whenever an answer can be visualized in a chart, use the chart tool regardless if the user requested it or not.' This guides the agent's output behavior."

• "Let's test it! (Type: 'Show me the sales performance for Zoomi HealthMonitor across all regions in 2024, and summarize any related team discussions about this product.')."
• "You'll see the agent thinking, leveraging both our Semantic View for the sales data and our Search Service for the team communications, then synthesizing the insights. (Show the response, ideally with a chart showing regional performance and key team insights)."

(9:00 - 10:00) Conclusion & Next Steps for Zoomi

Speaker Notes:
• "So, in just a few minutes, we've gone from raw Zoomi sales and communication data to a fully functional AI agent, capable of querying your structured sales performance and searching your unstructured team communications using natural language."
• "This demonstrates how Snowflake Intelligence empowers Zoomi to bring AI directly to your business data, enabling faster insights into sales trends, regional performance, product success, and team collaboration patterns."
• "This is just the beginning. We can explore more complex scenarios, integrate with other systems like your CRM or ERP, and build custom tools tailored to Zoomi's unique needs and business processes."
• "Thank you for your time. I'm excited to discuss how this can specifically benefit your teams and help Zoomi continue to lead in pet wellness technology. Please feel free to ask any questions!" 