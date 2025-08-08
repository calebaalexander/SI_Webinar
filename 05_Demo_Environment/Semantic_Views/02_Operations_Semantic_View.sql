-- PawCore Systems Operations Semantic View
-- This semantic view enables natural language querying of operations and team collaboration data

USE ROLE SNOWFLAKE_INTELLIGENCE_ADMIN_RL;
USE DATABASE PAWCORE_INTELLIGENCE_DEMO;
USE SCHEMA BUSINESS_DATA;

-- Create dimension tables for operations
CREATE OR REPLACE TABLE PROJECT_DIM (
    PROJECT_KEY NUMBER AUTOINCREMENT PRIMARY KEY,
    PROJECT_NAME VARCHAR(100) NOT NULL,
    PROJECT_TYPE VARCHAR(50),
    STATUS VARCHAR(30),
    START_DATE DATE,
    END_DATE DATE,
    PRIORITY VARCHAR(20)
);

CREATE OR REPLACE TABLE DEPARTMENT_DIM (
    DEPT_KEY NUMBER AUTOINCREMENT PRIMARY KEY,
    DEPARTMENT_NAME VARCHAR(50) NOT NULL,
    FUNCTION VARCHAR(50),
    MANAGER VARCHAR(100),
    LOCATION VARCHAR(50)
);

CREATE OR REPLACE TABLE TEAM_MEMBER_DIM (
    MEMBER_KEY NUMBER AUTOINCREMENT PRIMARY KEY,
    MEMBER_NAME VARCHAR(100) NOT NULL,
    ROLE VARCHAR(50),
    DEPARTMENT_KEY NUMBER REFERENCES DEPARTMENT_DIM(DEPT_KEY),
    JOIN_DATE DATE
);

-- Insert sample operations data
INSERT INTO PROJECT_DIM (PROJECT_NAME, PROJECT_TYPE, STATUS, START_DATE, END_DATE, PRIORITY) VALUES
('PetTracker v2.1 Launch', 'Product Development', 'Completed', '2024-10-01', '2024-12-15', 'High'),
('European Market Expansion', 'Market Expansion', 'In Progress', '2024-11-01', '2025-06-30', 'High'),
('Supply Chain Optimization', 'Operations', 'Completed', '2024-09-01', '2024-11-30', 'Medium'),
('Customer Support Enhancement', 'Service Improvement', 'In Progress', '2024-12-01', '2025-03-31', 'Medium');

INSERT INTO DEPARTMENT_DIM (DEPARTMENT_NAME, FUNCTION, MANAGER, LOCATION) VALUES
('Engineering', 'Product Development', 'Sarah Johnson', 'San Francisco'),
('Marketing', 'Brand and Campaigns', 'Mike Chen', 'New York'),
('Sales', 'Revenue Generation', 'Lisa Rodriguez', 'Chicago'),
('Operations', 'Supply Chain and Quality', 'David Kim', 'Austin'),
('Customer Support', 'Customer Service', 'Emma Wilson', 'Remote');

INSERT INTO TEAM_MEMBER_DIM (MEMBER_NAME, ROLE, DEPARTMENT_KEY, JOIN_DATE) VALUES
('Alex Thompson', 'Senior Engineer', 1, '2022-03-15'),
('Maria Garcia', 'Marketing Manager', 2, '2023-01-10'),
('James Lee', 'Sales Director', 3, '2021-08-22'),
('Rachel Brown', 'Operations Manager', 4, '2023-06-05'),
('Tom Anderson', 'Support Lead', 5, '2022-11-12');

-- Create the Operations Semantic View
CREATE OR REPLACE SEMANTIC VIEW PAWCORE_OPERATIONS_SEMANTIC_VIEW
tables (
    COMMUNICATIONS as TEAM_COMMUNICATIONS primary key (MESSAGE_ID) 
        with synonyms=('team messages','slack communications','collaboration','team discussions') 
        comment='Team communication data and collaboration insights',
    PROJECTS as PROJECT_DIM primary key (PROJECT_KEY) 
        with synonyms=('projects','initiatives','campaigns','programs') 
        comment='Project information and initiative tracking',
    DEPARTMENTS as DEPARTMENT_DIM primary key (DEPT_KEY) 
        with synonyms=('departments','teams','business units','functions') 
        comment='Department information and organizational structure',
    TEAM_MEMBERS as TEAM_MEMBER_DIM primary key (MEMBER_KEY) 
        with synonyms=('team members','employees','staff','people') 
        comment='Team member information and roles'
)
relationships (
    COMMUNICATIONS_TO_PROJECTS as COMMUNICATIONS(PROJECT_REF) references PROJECTS(PROJECT_KEY),
    COMMUNICATIONS_TO_DEPARTMENTS as COMMUNICATIONS(DEPT_REF) references DEPARTMENTS(DEPT_KEY),
    COMMUNICATIONS_TO_MEMBERS as COMMUNICATIONS(MEMBER_REF) references TEAM_MEMBERS(MEMBER_KEY),
    TEAM_MEMBERS_TO_DEPARTMENTS as TEAM_MEMBERS(DEPARTMENT_KEY) references DEPARTMENTS(DEPT_KEY)
)
facts (
    COMMUNICATIONS.MESSAGE_LENGTH as message_length comment='Length of communication message',
    COMMUNICATIONS.REACTION_COUNT as reactions comment='Number of reactions to message',
    COMMUNICATIONS.REPLY_COUNT as replies comment='Number of replies to message',
    PROJECTS.DURATION_DAYS as project_duration comment='Duration of project in days'
)
dimensions (
    COMMUNICATIONS.DATE as date with synonyms=('date','message date','communication date') comment='Date of the communication',
    COMMUNICATIONS.SLACK_CHANNEL as channel with synonyms=('channel','slack channel','communication channel') comment='Slack channel where communication occurred',
    COMMUNICATIONS.TEXT as message_text with synonyms=('message','text','content','communication') comment='Content of the communication message',
    PROJECTS.PROJECT_NAME as project_name with synonyms=('project','initiative','campaign name') comment='Name of the project',
    PROJECTS.PROJECT_TYPE as project_type with synonyms=('project type','initiative type','campaign type') comment='Type of project or initiative',
    PROJECTS.STATUS as project_status with synonyms=('status','project status','initiative status') comment='Current status of the project',
    PROJECTS.PRIORITY as project_priority with synonyms=('priority','project priority','importance') comment='Priority level of the project',
    DEPARTMENTS.DEPARTMENT_NAME as department_name with synonyms=('department','team','business unit') comment='Name of the department',
    DEPARTMENTS.FUNCTION as department_function with synonyms=('function','department function','business function') comment='Function of the department',
    TEAM_MEMBERS.MEMBER_NAME as member_name with synonyms=('member','employee','team member','staff member') comment='Name of the team member',
    TEAM_MEMBERS.ROLE as member_role with synonyms=('role','job role','position','title') comment='Role or position of the team member'
)
metrics (
    COMMUNICATIONS.TOTAL_MESSAGES as COUNT(communications.message_id) comment='Total number of team communications',
    COMMUNICATIONS.AVG_MESSAGE_LENGTH as AVG(communications.message_length) comment='Average length of communication messages',
    COMMUNICATIONS.TOTAL_REACTIONS as SUM(communications.reactions) comment='Total reactions across all communications',
    COMMUNICATIONS.ENGAGEMENT_RATE as AVG(communications.reactions + communications.replies) comment='Average engagement rate per message',
    PROJECTS.ACTIVE_PROJECTS as COUNT(CASE WHEN projects.status = 'In Progress' THEN 1 END) comment='Number of active projects',
    PROJECTS.COMPLETED_PROJECTS as COUNT(CASE WHEN projects.status = 'Completed' THEN 1 END) comment='Number of completed projects',
    PROJECTS.AVG_PROJECT_DURATION as AVG(projects.duration_days) comment='Average project duration in days',
    DEPARTMENTS.TOTAL_DEPARTMENTS as COUNT(departments.dept_key) comment='Total number of departments',
    TEAM_MEMBERS.TOTAL_MEMBERS as COUNT(team_members.member_key) comment='Total number of team members'
)
comment='Semantic view for PawCore Systems operations analysis including team collaboration, project tracking, and organizational insights';

-- Grant permissions for the semantic view
GRANT SELECT ON SEMANTIC VIEW PAWCORE_OPERATIONS_SEMANTIC_VIEW TO ROLE PAWCORE_WEBINAR_ROLE;

-- Verification query
SELECT 
    'Operations Semantic View Created' as status,
    SEMANTIC_VIEW_NAME,
    CREATED
FROM PAWCORE_INTELLIGENCE_DEMO.INFORMATION_SCHEMA.SEMANTIC_VIEWS 
WHERE SEMANTIC_VIEW_NAME = 'PAWCORE_OPERATIONS_SEMANTIC_VIEW'; 