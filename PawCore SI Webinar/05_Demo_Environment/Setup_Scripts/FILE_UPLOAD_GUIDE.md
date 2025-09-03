# PawCore Demo File Upload Guide

## 📁 Required Files for Demo

Before running the `pawcore_data_setup.sql` script, you need to upload the following files to the appropriate stages using the Snowflake UI.

### 🔧 Step 1: Upload CSV Files to INTERNAL_DATA_STAGE

Navigate to your Snowflake UI and upload these files to `@INTERNAL_DATA_STAGE`:

- **pawcore_sales.csv** - Core sales data
- **returns.csv** - 🚨 Critical mystery data (Lot 341 anomaly)
- **hr_resumes.csv** - Candidate data for hiring solution
- **support_tickets.csv** - Support ticket evidence
- **warranty_costs.csv** - Warranty cost data
- **pet_owners.csv** - Customer base data

### 📄 Step 2: Upload Document Files to DOCUMENT_STAGE

Upload these files to `@DOCUMENT_STAGE`:

- **customer_reviews.csv** - Customer feedback data
- **pawcore_slack.csv** - Internal Slack messages (with sentiment analysis)

### 🎵 Step 3: Upload Audio Files to AUDIO_STAGE

Upload this file to `@AUDIO_STAGE`:

- **PawCore Quarterly Call.mp3** - Quarterly earnings call audio

## 🚀 File Locations in Repository

All files can be found in your local repository:

```
PawCore SI Webinar/02_Data/
├── Internal Data Stage/
│   ├── pawcore_sales.csv
│   ├── returns.csv
│   ├── hr_resumes.csv
│   ├── support_tickets.csv
│   ├── warranty_costs.csv
│   └── pet_owners.csv
├── Document Stage/
│   ├── customer_reviews.csv
│   └── pawcore_slack.csv
└── Audio Stage/
    └── PawCore Quarterly Call.mp3
```

## ⚡ Upload Process

### Option 1: Snowflake UI
1. Log into Snowflake UI
2. Navigate to **Databases** → **PAWCORE_INTELLIGENCE_DEMO** → **BUSINESS_DATA**
3. Click on **Stages**
4. Select the appropriate stage (@INTERNAL_DATA_STAGE, @DOCUMENT_STAGE, or @AUDIO_STAGE)
5. Click **Upload Files**
6. Select and upload the files

### Option 2: SnowSQL Command Line
```sql
-- Upload to internal data stage
PUT file:///path/to/pawcore_sales.csv @INTERNAL_DATA_STAGE;
PUT file:///path/to/returns.csv @INTERNAL_DATA_STAGE;
PUT file:///path/to/hr_resumes.csv @INTERNAL_DATA_STAGE;
PUT file:///path/to/support_tickets.csv @INTERNAL_DATA_STAGE;
PUT file:///path/to/warranty_costs.csv @INTERNAL_DATA_STAGE;
PUT file:///path/to/pet_owners.csv @INTERNAL_DATA_STAGE;

-- Upload to document stage
PUT file:///path/to/customer_reviews.csv @DOCUMENT_STAGE;
PUT file:///path/to/pawcore_slack.csv @DOCUMENT_STAGE;

-- Upload to audio stage
PUT file:///path/to/PawCore_Quarterly_Call.mp3 @AUDIO_STAGE;
```

## ✅ Verification

After uploading, run these commands to verify:

```sql
-- Check files in each stage
LS @INTERNAL_DATA_STAGE;
LS @DOCUMENT_STAGE;
LS @AUDIO_STAGE;
```

You should see all the uploaded files listed. Once verified, you can proceed with running the rest of the `pawcore_data_setup.sql` script.

## 🎯 Next Steps

1. **Upload all files** using the guide above
2. **Run the SQL script** `pawcore_data_setup.sql`
3. **Verify data loading** with the verification queries at the end
4. **Start investigating** the Lot 341 mystery! 🕵️

The mystery preview query should show the anomaly immediately:
- **Lot 341 in EMEA** showing 4x-8x return spikes
- **Week starting 2024-10-01** onwards
- **Status: 🚨 ANOMALY DETECTED**
