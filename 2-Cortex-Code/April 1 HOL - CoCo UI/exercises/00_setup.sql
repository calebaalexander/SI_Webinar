-- ========================================================================
-- PawCore Setup Script - Self-Contained
-- Cortex Code in Snowsight: Hands-On Lab
-- ========================================================================
-- No external dependencies. All data is generated inline.
-- Safe to re-run: uses IF NOT EXISTS + TRUNCATE before each data load.
-- Run time: ~2 minutes
-- Requires: ACCOUNTADMIN role, Cortex features enabled
-- ========================================================================

USE ROLE ACCOUNTADMIN;

-- ========================================================================
-- INFRASTRUCTURE
-- ========================================================================

CREATE WAREHOUSE IF NOT EXISTS PAWCORE_DEMO_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE;

USE WAREHOUSE PAWCORE_DEMO_WH;

CREATE DATABASE IF NOT EXISTS PAWCORE_ANALYTICS;
USE DATABASE PAWCORE_ANALYTICS;

CREATE SCHEMA IF NOT EXISTS DEVICE_DATA;
CREATE SCHEMA IF NOT EXISTS MANUFACTURING;
CREATE SCHEMA IF NOT EXISTS SUPPORT;
CREATE SCHEMA IF NOT EXISTS UNSTRUCTURED;
CREATE SCHEMA IF NOT EXISTS SEMANTIC;

-- ========================================================================
-- TABLES
-- ========================================================================

CREATE TABLE IF NOT EXISTS DEVICE_DATA.TELEMETRY (
    device_id        VARCHAR(50),
    timestamp        TIMESTAMP,
    battery_level    FLOAT,
    humidity_reading FLOAT,
    temperature      FLOAT,
    charging_cycles  INTEGER,
    lot_number       VARCHAR(50),
    region           VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS MANUFACTURING.QUALITY_LOGS (
    lot_number        VARCHAR(50),
    timestamp         TIMESTAMP,
    test_type         VARCHAR(100),
    measurement_value FLOAT,
    pass_fail         VARCHAR(10),
    operator_id       VARCHAR(50),
    station_id        VARCHAR(50),
    test_name         VARCHAR(100),
    notes             TEXT
);

CREATE TABLE IF NOT EXISTS SUPPORT.CUSTOMER_REVIEWS (
    review_id   VARCHAR(50),
    device_id   VARCHAR(50),
    lot_number  VARCHAR(50),
    rating      INTEGER,
    review_text TEXT,
    date        DATE,
    region      VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS SUPPORT.SLACK_MESSAGES (
    message_id    VARCHAR(50),
    slack_channel VARCHAR(50),
    user_name     VARCHAR(100),
    text          TEXT,
    thread_id     VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS SUPPORT.SUPPORT_TICKETS (
    ticket_id     VARCHAR(50),
    device_id     VARCHAR(50),
    lot_number    VARCHAR(50),
    region        VARCHAR(50),
    category      VARCHAR(50),
    priority      VARCHAR(20),
    status        VARCHAR(20),
    created_date  DATE,
    resolved_date DATE,
    description   TEXT
);

CREATE TABLE IF NOT EXISTS SUPPORT.V2_BETA_FEEDBACK (
    feedback_id     VARCHAR(50),
    region          VARCHAR(50),
    feature_tested  VARCHAR(100),
    rating          INTEGER,
    feedback_text   TEXT,
    tester_type     VARCHAR(20),
    submission_date DATE,
    device_version  VARCHAR(50),
    lot_number      VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS UNSTRUCTURED.PARSED_CONTENT (
    relative_path VARCHAR,
    file_name     VARCHAR,
    content       TEXT
);

-- ========================================================================
-- TRUNCATE (safe re-run)
-- ========================================================================

TRUNCATE TABLE IF EXISTS DEVICE_DATA.TELEMETRY;
TRUNCATE TABLE IF EXISTS MANUFACTURING.QUALITY_LOGS;
TRUNCATE TABLE IF EXISTS SUPPORT.CUSTOMER_REVIEWS;
TRUNCATE TABLE IF EXISTS SUPPORT.SLACK_MESSAGES;
TRUNCATE TABLE IF EXISTS SUPPORT.SUPPORT_TICKETS;
TRUNCATE TABLE IF EXISTS SUPPORT.V2_BETA_FEEDBACK;
TRUNCATE TABLE IF EXISTS UNSTRUCTURED.PARSED_CONTENT;

-- ========================================================================
-- TELEMETRY (~21,000 rows)
-- Story: EMEA devices from LOT341 have chronic low battery due to a
--        moisture sensor calibration defect. Americas and APAC are healthy.
-- ========================================================================

INSERT INTO DEVICE_DATA.TELEMETRY
    (device_id, timestamp, battery_level, humidity_reading, temperature, charging_cycles, lot_number, region)
SELECT
    'SC-2024-' || LPAD((MOD(n, 500) + 1)::VARCHAR, 3, '0') || '-' ||
        CASE MOD(n, 3) WHEN 0 THEN '001' WHEN 1 THEN '002' ELSE '003' END  AS device_id,
    DATEADD('hour', -(n * 1.8)::INT, CURRENT_TIMESTAMP())                  AS timestamp,
    CASE region
        WHEN 'EMEA'     THEN ROUND(UNIFORM(8,  45, RANDOM()) / 100.0, 2)
        WHEN 'Americas' THEN ROUND(UNIFORM(35, 98, RANDOM()) / 100.0, 2)
        ELSE                 ROUND(UNIFORM(50, 100, RANDOM()) / 100.0, 2)
    END                                                                     AS battery_level,
    CASE region
        WHEN 'EMEA' THEN ROUND(UNIFORM(60, 90, RANDOM()) / 100.0, 2)
        ELSE             ROUND(UNIFORM(20, 60, RANDOM()) / 100.0, 2)
    END                                                                     AS humidity_reading,
    ROUND(UNIFORM(18, 40, RANDOM()) / 1.0, 1)                              AS temperature,
    UNIFORM(1, 500, RANDOM())                                               AS charging_cycles,
    CASE region
        WHEN 'EMEA'     THEN 'LOT341'
        WHEN 'Americas' THEN 'LOT340'
        ELSE                 'LOT339'
    END                                                                     AS lot_number,
    region
FROM (
    SELECT
        n,
        CASE MOD(n, 3) WHEN 0 THEN 'EMEA' WHEN 1 THEN 'Americas' ELSE 'APAC' END AS region
    FROM (
        SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS n
        FROM TABLE(GENERATOR(ROWCOUNT => 21000))
    )
);

-- ========================================================================
-- QUALITY LOGS (~800 rows)
-- Story: LOT341 has elevated moisture sensor failure rate.
--        Sensor triggers at 65% instead of the 85% spec.
-- ========================================================================

INSERT INTO MANUFACTURING.QUALITY_LOGS
    (lot_number, timestamp, test_type, measurement_value, pass_fail, operator_id, station_id, test_name, notes)
SELECT
    CASE MOD(n, 3) WHEN 0 THEN 'LOT341' WHEN 1 THEN 'LOT340' ELSE 'LOT339' END    AS lot_number,
    DATEADD('day', -UNIFORM(1, 180, RANDOM()), CURRENT_TIMESTAMP())                AS timestamp,
    CASE MOD(n, 4)
        WHEN 0 THEN 'MOISTURE_SENSOR'
        WHEN 1 THEN 'BATTERY_CYCLE'
        WHEN 2 THEN 'TEMPERATURE'
        ELSE        'WATER_RESISTANCE'
    END                                                                             AS test_type,
    CASE
        WHEN MOD(n, 3) = 0 AND MOD(n, 4) = 0 THEN ROUND(UNIFORM(60, 70, RANDOM()) / 1.0, 2)
        ELSE                                       ROUND(UNIFORM(80, 99, RANDOM()) / 1.0, 2)
    END                                                                             AS measurement_value,
    CASE
        WHEN MOD(n, 3) = 0 AND MOD(n, 4) = 0 THEN 'FAIL'
        WHEN UNIFORM(1, 10, RANDOM()) = 1      THEN 'FAIL'
        ELSE                                        'PASS'
    END                                                                             AS pass_fail,
    'OP-'  || LPAD(UNIFORM(1, 20, RANDOM())::VARCHAR, 3, '0')                      AS operator_id,
    'STN-' || LPAD(UNIFORM(1,  8, RANDOM())::VARCHAR, 2, '0')                      AS station_id,
    CASE MOD(n, 4)
        WHEN 0 THEN 'Humidity Threshold Test'
        WHEN 1 THEN 'Battery Health Cycle'
        WHEN 2 THEN 'Thermal Stress Test'
        ELSE        'IP67 Immersion Test'
    END                                                                             AS test_name,
    CASE
        WHEN MOD(n, 3) = 0 AND MOD(n, 4) = 0
            THEN 'LOT341: Moisture sensor triggering at 65% instead of 85% spec. Batch flagged for firmware patch.'
        ELSE NULL
    END                                                                             AS notes
FROM (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS n
    FROM TABLE(GENERATOR(ROWCOUNT => 800))
);

-- ========================================================================
-- SUPPORT TICKETS (~240 rows)
-- Story: EMEA carries 50% of tickets at critical/high priority.
--        Americas recovering. APAC mostly clean.
-- ========================================================================

INSERT INTO SUPPORT.SUPPORT_TICKETS
    (ticket_id, device_id, lot_number, region, category, priority, status, created_date, resolved_date, description)
SELECT
    'TKT-' || LPAD(n::VARCHAR, 5, '0')                                             AS ticket_id,
    'SC-2024-' || LPAD(UNIFORM(1, 100, RANDOM())::VARCHAR, 3, '0') || '-001'       AS device_id,
    CASE region WHEN 'EMEA' THEN 'LOT341' WHEN 'Americas' THEN 'LOT340' ELSE 'LOT339' END AS lot_number,
    region,
    CASE
        WHEN region = 'EMEA' THEN
            CASE MOD(n, 5) WHEN 0 THEN 'Battery' WHEN 1 THEN 'Battery' WHEN 2 THEN 'Sensor' WHEN 3 THEN 'Connectivity' ELSE 'Battery' END
        ELSE
            CASE MOD(n, 5) WHEN 0 THEN 'Battery' WHEN 1 THEN 'Firmware' WHEN 2 THEN 'Sensor' WHEN 3 THEN 'App' ELSE 'Hardware' END
    END                                                                             AS category,
    CASE
        WHEN region = 'EMEA'     AND MOD(n, 3) = 0 THEN 'CRITICAL'
        WHEN region = 'EMEA'                        THEN 'HIGH'
        WHEN region = 'Americas' AND MOD(n, 5) = 0 THEN 'CRITICAL'
        WHEN region = 'Americas'                    THEN 'MEDIUM'
        ELSE                                             'LOW'
    END                                                                             AS priority,
    CASE MOD(n, 4) WHEN 0 THEN 'OPEN' WHEN 1 THEN 'IN_PROGRESS' ELSE 'RESOLVED' END AS status,
    DATEADD('day', -UNIFORM(1, 120, RANDOM()), CURRENT_DATE())                     AS created_date,
    CASE WHEN MOD(n, 4) = 3
        THEN DATEADD('day', -UNIFORM(0, 30, RANDOM()), CURRENT_DATE())
        ELSE NULL
    END                                                                             AS resolved_date,
    CASE
        WHEN region = 'EMEA' AND MOD(n, 3) = 0 THEN 'Device battery depleting within 4 hours of full charge. Customer unable to use product.'
        WHEN region = 'EMEA'                    THEN 'Battery draining faster than expected. Humidity sensor readings inconsistent.'
        WHEN region = 'Americas'                THEN 'Firmware update causing connectivity drops. Intermittent sync failures.'
        ELSE                                         'Minor calibration issue reported. Device functioning within acceptable range.'
    END                                                                             AS description
FROM (
    SELECT
        n,
        CASE WHEN n <= 120 THEN 'EMEA' WHEN n <= 200 THEN 'Americas' ELSE 'APAC' END AS region
    FROM (
        SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS n
        FROM TABLE(GENERATOR(ROWCOUNT => 240))
    )
);

-- ========================================================================
-- CUSTOMER REVIEWS (~1,500 rows)
-- Story: EMEA reviews skew 1-2 stars (battery complaints).
--        Americas mixed. APAC strongly positive.
-- ========================================================================

INSERT INTO SUPPORT.CUSTOMER_REVIEWS
    (review_id, device_id, lot_number, rating, review_text, date, region)
SELECT
    'REV-' || LPAD(n::VARCHAR, 5, '0')                                             AS review_id,
    'SC-2024-' || LPAD(UNIFORM(1, 200, RANDOM())::VARCHAR, 3, '0') || '-' ||
        CASE region WHEN 'EMEA' THEN '001' WHEN 'Americas' THEN '002' ELSE '003' END AS device_id,
    CASE region WHEN 'EMEA' THEN 'LOT341' WHEN 'Americas' THEN 'LOT340' ELSE 'LOT339' END AS lot_number,
    CASE region
        WHEN 'EMEA'     THEN CASE WHEN UNIFORM(1, 10, RANDOM()) <= 7 THEN UNIFORM(1, 2, RANDOM()) ELSE UNIFORM(3, 5, RANDOM()) END
        WHEN 'Americas' THEN CASE WHEN UNIFORM(1, 10, RANDOM()) <= 4 THEN UNIFORM(1, 3, RANDOM()) ELSE UNIFORM(3, 5, RANDOM()) END
        ELSE                 CASE WHEN UNIFORM(1, 10, RANDOM()) <= 2 THEN UNIFORM(1, 3, RANDOM()) ELSE UNIFORM(4, 5, RANDOM()) END
    END                                                                             AS rating,
    CASE region
        WHEN 'EMEA' THEN
            CASE MOD(n, 6)
                WHEN 0 THEN 'Battery dies within hours. Completely unusable. Returning immediately.'
                WHEN 1 THEN 'Disappointed. Battery life is terrible - not what was advertised.'
                WHEN 2 THEN 'My dog barely gets 3 hours of tracking before it dies. Awful product.'
                WHEN 3 THEN 'Collar stopped working after two days. Apparently a known battery issue.'
                WHEN 4 THEN 'Would give zero stars if I could. Battery drains overnight even when off.'
                ELSE        'Had high hopes but the battery issues make this unusable. Returning.'
            END
        WHEN 'Americas' THEN
            CASE MOD(n, 5)
                WHEN 0 THEN 'Had some connectivity issues early on but the firmware update helped.'
                WHEN 1 THEN 'Decent product overall. Battery could be better but works for daily use.'
                WHEN 2 THEN 'App crashes occasionally but the collar itself works fine.'
                WHEN 3 THEN 'Good tracking features. Support team was helpful when I had questions.'
                ELSE        'Solid product after the update. GPS accuracy is impressive.'
            END
        ELSE
            CASE MOD(n, 4)
                WHEN 0 THEN 'Excellent product! Battery lasts all day and tracking is very accurate.'
                WHEN 1 THEN 'My dog loves it. Easy setup and the app is intuitive. Highly recommend.'
                WHEN 2 THEN 'Great build quality. The health monitoring features are fantastic.'
                ELSE        'Best pet collar on the market. Worth every penny.'
            END
    END                                                                             AS review_text,
    DATEADD('day', -UNIFORM(1, 150, RANDOM()), CURRENT_DATE())                     AS date,
    region
FROM (
    SELECT
        n,
        CASE WHEN n <= 600 THEN 'EMEA' WHEN n <= 1100 THEN 'Americas' ELSE 'APAC' END AS region
    FROM (
        SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS n
        FROM TABLE(GENERATOR(ROWCOUNT => 1500))
    )
);

-- ========================================================================
-- V2 BETA FEEDBACK (~120 rows)
-- Story: V2 signals are strong. EMEA cautiously positive after V1 issues.
-- ========================================================================

INSERT INTO SUPPORT.V2_BETA_FEEDBACK
    (feedback_id, region, feature_tested, rating, feedback_text, tester_type, submission_date, device_version, lot_number)
SELECT
    'FB-' || LPAD(n::VARCHAR, 4, '0')                                              AS feedback_id,
    CASE MOD(n, 3) WHEN 0 THEN 'EMEA' WHEN 1 THEN 'Americas' ELSE 'APAC' END      AS region,
    CASE MOD(n, 5)
        WHEN 0 THEN 'Battery Life'      WHEN 1 THEN 'GPS Accuracy'
        WHEN 2 THEN 'Health Monitoring' WHEN 3 THEN 'App Integration'
        ELSE        'Build Quality'
    END                                                                             AS feature_tested,
    CASE MOD(n, 3)
        WHEN 0 THEN CASE WHEN UNIFORM(1, 10, RANDOM()) <= 4 THEN UNIFORM(2, 3, RANDOM()) ELSE UNIFORM(4, 5, RANDOM()) END
        ELSE UNIFORM(3, 5, RANDOM())
    END                                                                             AS rating,
    CASE MOD(n, 5)
        WHEN 0 THEN 'Battery life significantly improved over V1. Lasting 18+ hours in testing.'
        WHEN 1 THEN 'GPS lock time improved. Accuracy within 2 meters in open areas.'
        WHEN 2 THEN 'Heart rate monitoring is a great addition. Data matches vet readings closely.'
        WHEN 3 THEN 'New app design is much cleaner. Notifications working reliably now.'
        ELSE        'Build feels more premium. Waterproofing noticeably better than V1.'
    END                                                                             AS feedback_text,
    CASE WHEN MOD(n, 4) = 0 THEN 'INTERNAL' ELSE 'EXTERNAL' END                   AS tester_type,
    DATEADD('day', -UNIFORM(1, 60, RANDOM()), CURRENT_DATE())                      AS submission_date,
    'V2.0-BETA'                                                                     AS device_version,
    'LOT342'                                                                        AS lot_number
FROM (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS n
    FROM TABLE(GENERATOR(ROWCOUNT => 120))
);

-- ========================================================================
-- SLACK MESSAGES (37 rows)
-- Story: Internal team comms tracking the LOT341 crisis and V2 readiness
-- ========================================================================

INSERT INTO SUPPORT.SLACK_MESSAGES (message_id, slack_channel, user_name, text, thread_id) VALUES
('MSG-001','#support-ops',   'sarah.chen',   'Anyone else seeing a spike in EMEA battery complaints this week? 47 tickets in the last 48 hours.','THREAD-001'),
('MSG-002','#support-ops',   'james.wright', 'Yeah saw that. Looks like it''s concentrated in LOT341 units. Routing to engineering.','THREAD-001'),
('MSG-003','#support-ops',   'sarah.chen',   'LOT341 shipped to EMEA exclusively right? That would explain the geographic clustering.','THREAD-001'),
('MSG-004','#support-ops',   'priya.sharma', 'Confirmed. LOT341 is all EMEA. Engineering flagged a moisture sensor calibration issue. Triggering at 65% instead of 85%.','THREAD-001'),
('MSG-005','#support-ops',   'james.wright', 'So it''s not actually a battery problem - the sensor misread is causing unnecessary shutdowns?','THREAD-001'),
('MSG-006','#support-ops',   'priya.sharma', 'Exactly. Firmware fix is in review. ETA 48 hours. We need a response template for affected customers.','THREAD-001'),
('MSG-007','#support-ops',   'sarah.chen',   'On it. How many customers are affected? I want to get ahead of this before it hits social.','THREAD-001'),
('MSG-008','#support-ops',   'james.wright', 'Current estimate is 800-1000 units in the field. All LOT341. Americas and APAC are clean.','THREAD-001'),
('MSG-009','#cx-leadership', 'tom.baker',    'Morning team. EMEA support volume is up 340% vs last week. V2 launch is 6 weeks out. We need a plan.','THREAD-002'),
('MSG-010','#cx-leadership', 'lisa.morgan',  'Priya''s team is on the root cause. Firmware patch in 48h. Bigger question is how this affects V2 readiness optics in EMEA.','THREAD-002'),
('MSG-011','#cx-leadership', 'tom.baker',    'Agreed. EMEA customers just had a bad V1 experience. If V2 launch stumbles there it could be a real problem.','THREAD-002'),
('MSG-012','#cx-leadership', 'raj.patel',    'Americas and APAC are solid. If we resolve EMEA before launch we''re in good shape overall.','THREAD-002'),
('MSG-013','#engineering',   'dev.team',     'LOT341 firmware patch deployed to staging. Moisture sensor threshold corrected to 85%. Testing overnight.','THREAD-003'),
('MSG-014','#engineering',   'qa.team',      'Staging tests passing. Battery life back to expected range. Pushing to production tomorrow morning.','THREAD-003'),
('MSG-015','#support-ops',   'sarah.chen',   'Firmware fix confirmed working on test units. Support ticket rate in EMEA already starting to drop.','THREAD-004'),
('MSG-016','#support-ops',   'priya.sharma', 'Great news. Americas tickets also declining - the connectivity fix from last sprint is holding.','THREAD-004'),
('MSG-017','#cx-leadership', 'tom.baker',    'V2 beta feedback: APAC 4.7 avg, Americas 4.3, EMEA 3.9 but trending up post-patch.','THREAD-005'),
('MSG-018','#cx-leadership', 'lisa.morgan',  '3.9 in EMEA is actually encouraging given what they just went through. Shows the patch restored confidence.','THREAD-005'),
('MSG-019','#support-ops',   'james.wright', 'Preparing V2 launch support playbook. Biggest risk: EMEA volume if V1 customers haven''t updated firmware.','THREAD-006'),
('MSG-020','#support-ops',   'sarah.chen',   'Running outreach to all LOT341 owners this week. Targeting 90% firmware update rate before V2 ships.','THREAD-006'),
('MSG-021','#cx-leadership', 'raj.patel',    'Question: are we staffed for a 3x volume increase in EMEA if V2 launch goes well?','THREAD-007'),
('MSG-022','#cx-leadership', 'tom.baker',    'That''s what I need to know. Building the readiness analysis this week. Should have regional breakdown by Friday.','THREAD-007'),
('MSG-023','#cx-leadership', 'lisa.morgan',  'APAC staffing is fine. Americas has buffer. EMEA is the question mark.','THREAD-007'),
('MSG-024','#support-ops',   'priya.sharma', 'Current EMEA open ticket count: 89. Down from 134 last week. Trending right but still elevated.','THREAD-008'),
('MSG-025','#support-ops',   'james.wright', 'Projected to hit normal range (<30 open) by end of next week if rate holds.','THREAD-008'),
('MSG-026','#support-ops',   'sarah.chen',   'That gives us 4 weeks before V2 launch. Should be enough if we staff up now.','THREAD-008'),
('MSG-027','#engineering',   'dev.team',     'V2 firmware RC1 is clean. Battery life 22 hours in lab testing. No moisture sensor issues - new supplier for LOT342+.','THREAD-009'),
('MSG-028','#cx-leadership', 'tom.baker',    '22 hours is a big deal. That was the #1 complaint on V1. Make sure that''s in the launch messaging.','THREAD-009'),
('MSG-029','#support-ops',   'priya.sharma', 'Drafting V2 support FAQ. Top beta question: does the V1 battery issue affect V2? Answer: no.','THREAD-010'),
('MSG-030','#cx-leadership', 'lisa.morgan',  'Americas beta NPS: +62. APAC: +71. EMEA: +48. EMEA lower but given V1 experience that''s solid.','THREAD-011'),
('MSG-031','#support-ops',   'sarah.chen',   'EMEA firmware update rate now at 84%. Running final push to hit 90% by Friday.','THREAD-012'),
('MSG-032','#support-ops',   'james.wright', 'Once we clear 90% the open ticket count should drop to near zero for V1 issues.','THREAD-012'),
('MSG-033','#cx-leadership', 'raj.patel',    'Staffing recommendation: add 3 FTE to EMEA support ahead of V2 launch. Americas and APAC hold current levels.','THREAD-013'),
('MSG-034','#cx-leadership', 'tom.baker',    'Approved. Posting reqs today. Need them onboarded in 3 weeks.','THREAD-013'),
('MSG-035','#support-ops',   'priya.sharma', 'V2 support readiness checklist almost done. Last item: verify PAWCORE_DOCUMENT_SEARCH is indexing the new QC standards doc.','THREAD-014'),
('MSG-036','#engineering',   'dev.team',     'Confirmed - QC standards summary is indexed. Cortex Search returning accurate results on test queries.','THREAD-014'),
('MSG-037','#cx-leadership', 'tom.baker',    'Team - looking good for V2 launch. Keep the momentum. EMEA is the watch item but trending right.','THREAD-015');

-- ========================================================================
-- PARSED CONTENT (QC Standards document)
-- ========================================================================

INSERT INTO UNSTRUCTURED.PARSED_CONTENT (relative_path, file_name, content)
VALUES (
    'Document_Stage/QC_standards_summary.md',
    'QC_standards_summary.md',
    'PawCore Quality Control Standards - Updated September 2024

OVERVIEW:
PawCore SmartCollar devices undergo rigorous QC testing before shipment. All units must pass temperature, humidity, battery, and water resistance testing before release.

TESTING PROTOCOLS:
- Temperature Testing: Required for all units. Acceptable range -10C to 50C.
- Humidity Testing: Mandatory as of Q4 2024 (previously optional). Sensor must trigger at 85% humidity threshold.
- Battery Cycle Testing: Minimum 500 charge cycles before certification. Health must remain above 80% capacity.
- Water Resistance: IP67 rating verification. Units submerged to 1 meter for 30 minutes.

KEY THRESHOLDS:
- Battery health: greater than 80% capacity after 500 charge cycles
- Moisture sensor trigger: exactly 85% humidity
- Overall pass rate target: 95% across all test types per lot
- Temperature stability: less than 2 degree variance across thermal range

KNOWN ISSUES - RESOLVED (Q4 2024):
- LOT341 moisture sensors triggered at approximately 65% humidity instead of the 85% specification
- Issue isolated to EMEA-bound units
- Root cause: sensor calibration drift during shipment in high-humidity conditions
- Resolution: firmware patch deployed correcting threshold; new supplier engaged for LOT342 onward
- All LOT341 customers notified; firmware update campaign completed at 90% adoption rate

IMPROVEMENTS IMPLEMENTED (effective LOT342):
- Humidity testing is now mandatory for all units
- QC sampling rate for moisture sensors increased from 10% to 100% of batch
- Regional climate simulation testing added to catch calibration drift before shipment
- New moisture sensor supplier with tighter manufacturing tolerances

V2 SMARTCOLLAR IMPROVEMENTS:
- Battery life extended to 22+ hours (up from 12 hours on V1)
- New moisture sensor supplier eliminates LOT341-class calibration issues
- IP68 water resistance rating (upgraded from IP67)
- Improved GPS chip with faster lock time and better accuracy'
);

-- ========================================================================
-- GRANTS
-- ========================================================================

GRANT USAGE ON WAREHOUSE PAWCORE_DEMO_WH             TO ROLE PUBLIC;
GRANT USAGE ON DATABASE PAWCORE_ANALYTICS             TO ROLE PUBLIC;
GRANT USAGE ON ALL SCHEMAS IN DATABASE PAWCORE_ANALYTICS TO ROLE PUBLIC;
GRANT SELECT ON ALL TABLES IN DATABASE PAWCORE_ANALYTICS TO ROLE PUBLIC;

-- ========================================================================
-- VERIFY
-- ========================================================================

USE DATABASE PAWCORE_ANALYTICS;

SELECT 'TELEMETRY'        AS table_name, COUNT(*) AS row_count FROM DEVICE_DATA.TELEMETRY      UNION ALL
SELECT 'QUALITY_LOGS',                   COUNT(*)             FROM MANUFACTURING.QUALITY_LOGS  UNION ALL
SELECT 'CUSTOMER_REVIEWS',               COUNT(*)             FROM SUPPORT.CUSTOMER_REVIEWS    UNION ALL
SELECT 'SLACK_MESSAGES',                 COUNT(*)             FROM SUPPORT.SLACK_MESSAGES      UNION ALL
SELECT 'SUPPORT_TICKETS',                COUNT(*)             FROM SUPPORT.SUPPORT_TICKETS     UNION ALL
SELECT 'V2_BETA_FEEDBACK',               COUNT(*)             FROM SUPPORT.V2_BETA_FEEDBACK    UNION ALL
SELECT 'PARSED_CONTENT',                 COUNT(*)             FROM UNSTRUCTURED.PARSED_CONTENT;
