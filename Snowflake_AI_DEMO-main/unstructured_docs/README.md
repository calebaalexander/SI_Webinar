# Unstructured Documents for Snowflake AI Demo

This directory contains comprehensive business documents across multiple formats to demonstrate Snowflake Cortex Search capabilities for document embedding, indexing, and intelligent retrieval.

## Document Collection Overview

### Total Documents: 55 files
- **10 Markdown files** (source content)
- **14 Word documents** (.docx format) 
- **4 PowerPoint presentations** (.pptx format)
- **25 PDF files** (converted documents + original contracts)
- **2 Contract amendments** (.docx format)

## Business Unit Organization

### 📊 Finance Department (28 files)
**Documents:**
- `Q4_2024_Financial_Report.md/docx/pdf` - Comprehensive quarterly financial analysis
- `Expense_Policy_2025.md/docx/pdf` - Corporate expense guidelines and procedures
- `Vendor_Management_Policy.md/docx/pdf` - Vendor selection and management protocols
- `Q4_2024_Financial_Results.pptx/pdf` - Executive presentation with financial highlights
- `Sample_Return_Policies_Summary.md` - Comprehensive vendor return policies guide

**Vendor Contracts (15 files):**
- **TechCorp Solutions** - IT Infrastructure ($456,780 annually)
- **Global Logistics Partners** - Supply Chain ($334,920 annually)
- **Marketing Dynamics Inc** - Advertising Services ($287,640 annually)
- **Professional Services LLC** - Consulting ($243,560 annually)
- **Office Solutions Pro** - Office Supplies ($198,430 annually)
- Each vendor has: Contract.pdf (original + converted), Contract.docx
- Contract amendments for TechCorp and Marketing Dynamics (docx + pdf)

**Content Highlights:**
- Revenue: $12.8M (+15% YoY)
- Operating margins and profitability analysis
- Vendor spend analysis with top 5 vendors
- Budget vs. actual performance metrics
- Risk management and compliance reporting

### 🎯 Sales Department (8 files)
**Documents:**
- `Sales_Playbook_2025.md/docx/pdf` - Complete sales methodology and processes
- `Customer_Success_Stories.md/docx/pdf` - Case studies and customer wins
- `Sales_Performance_Q4_2024.pptx/pdf` - Performance review and strategy presentation

**Content Highlights:**
- Sales methodology (MEDDIC framework)
- Customer segmentation and targeting
- Competitive positioning and battlecards
- Performance metrics and KPIs
- Real customer success stories with named sales reps

### 📈 Marketing Department (8 files)
**Documents:**
- `2025_Marketing_Strategy.md/docx/pdf` - Annual marketing strategy and campaign plans
- `Campaign_Performance_Report.md/docx/pdf` - Q4 campaign results and ROI analysis
- `Marketing_Strategy_2025.pptx/pdf` - Strategic presentation with budget allocation

**Content Highlights:**
- $3M annual marketing budget allocation
- Lead generation targets: 2,400 MQLs
- Multi-channel campaign strategy
- Account-based marketing (ABM) programs
- Event marketing and trade show performance

### 👥 HR Department (8 files)
**Documents:**
- `Employee_Handbook_2025.md/docx/pdf` - Comprehensive employee policies and benefits
- `Performance_Review_Guidelines.md/docx/pdf` - Performance management processes
- `HR_Department_Overview_2025.pptx/pdf` - Benefits and employee program overview

**Content Highlights:**
- Employee benefits and wellness programs
- Performance review processes and criteria
- Professional development and training
- Remote work and flexibility policies
- Compensation and recognition programs

## Document Features for Cortex Search

### Rich Content Types
- **Policy Documents**: Guidelines, procedures, and compliance information
- **Financial Reports**: Detailed financial analysis with metrics and KPIs
- **Strategy Documents**: Long-term planning and strategic initiatives  
- **Performance Reports**: Metrics, results, and performance analysis
- **Training Materials**: Processes, methodologies, and best practices
- **Presentations**: Executive summaries and key highlights

### Cross-Reference Capabilities
- **Named Entities**: Real employee names (e.g., Grant Frey, Elizabeth George)
- **Vendor Information**: Specific vendor names and contract values
- **Customer Data**: Customer names and success stories
- **Financial Metrics**: Specific amounts, percentages, and KPIs
- **Dates and Timelines**: Q4 2024, 2025 planning, specific dates

### Search Use Cases

#### Executive Queries
- "What were our Q4 financial results?"
- "Show me our top performing sales reps"
- "What's our marketing budget allocation for 2025?"
- "What benefits do we offer employees?"

#### Operational Queries
- "What's our expense policy for travel?"
- "How do we manage vendor relationships?"
- "What's our sales methodology?"
- "What are the performance review criteria?"
- "What's the return policy for TechCorp Solutions?"
- "Show me the contract terms for Global Logistics Partners"

#### Cross-Functional Queries
- "Which sales reps are mentioned in HR and Sales documents?"
- "What vendors appear in both Finance and Marketing materials?"
- "Show me customer success stories and related financial impact"
- "How do our marketing campaigns connect to sales results?"

## Technical Integration

### Snowflake Cortex Search Setup

### Document Loading Process
1. **Stage Creation**: Create internal stage for document storage
2. **Document Upload**: Use `PUT` command to upload files to stage
3. **Text Extraction**: Use `CORTEX.PARSE_DOCUMENT()` to extract text
4. **Content Indexing**: Index extracted text with Cortex Search
5. **Metadata Tagging**: Add business unit, document type, and date tags

### Search Examples

## Demo Scenarios

### Scenario 1: Executive Dashboard Query
**Query**: "Show me Q4 2024 performance across all departments"
**Expected Results**: Financial report, sales performance, marketing campaigns, HR metrics

### Scenario 2: Sales Rep Analysis
**Query**: "What information do we have about Grant Frey?"
**Expected Results**: Sales performance data, customer success stories, HR records

### Scenario 3: Vendor Analysis
**Query**: "Tell me about our relationship with TechCorp Solutions"
**Expected Results**: Vendor management policy, financial spend analysis, contract details

### Scenario 4: Policy Lookup
**Query**: "What's our policy for business travel expenses?"
**Expected Results**: Expense policy document with specific travel guidelines

## Data Relationships

### Sales ↔ HR Integration
- Sales rep names appear in both sales performance docs and HR systems
- Performance metrics connect to compensation and review processes
- Training programs link to sales methodology and skill development

### Finance ↔ Marketing Integration
- Marketing spend appears in financial reports
- Vendor relationships span both procurement and marketing services
- ROI metrics connect marketing campaigns to financial outcomes

### Cross-Departmental Themes
- **Customer Focus**: Success stories span sales, marketing, and finance
- **Performance Management**: Metrics and KPIs across all departments
- **Vendor Management**: Procurement policies and actual vendor usage
- **Compliance**: Regulatory requirements across all business functions

---

**Document Generation**: Automated using Python scripts with realistic business content
**Last Updated**: January 2025
**Demo Ready**: ✅ All documents optimized for Cortex Search indexing 