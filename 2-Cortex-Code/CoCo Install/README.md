# Cortex Code Installation & Setup Guide

Get Cortex Code (CoCo) running in minutes. This guide covers both the **CLI** (terminal) and the **Snowsight UI** (browser).

---

## Prerequisites

Before you begin, ensure you have:

| Requirement | Details |
|-------------|---------|
| **Snowflake Account** | Trial or paid account ([sign up free](https://signup.snowflake.com/)) |
| **Account Role** | ACCOUNTADMIN or role with CREATE DATABASE privileges |
| **Operating System** | macOS, Windows, or Linux |
| **Terminal Access** | Terminal (macOS/Linux) or PowerShell/CMD (Windows) |

---

## Part 1: Install Cortex Code CLI

### Step 1: Identify Your System

Not sure which download to use? Here's how to check:

| Platform | How to Check | What to Look For |
|----------|-------------|------------------|
| **macOS** | Apple menu → About This Mac | **Chip: Apple M1/M2/M3/M4** = Apple Silicon (ARM64). **Processor: Intel** = Intel (AMD64) |
| **Windows** | Settings → System → About | **System type: 64-bit operating system, x64-based processor** = standard Windows download |
| **Linux** | Run `uname -m` in terminal | **x86_64** = AMD64. **aarch64** = ARM64 |

### Step 2: Download the CLI

#### macOS (Apple Silicon)
```bash
curl -L https://downloads.snowflake.com/cortex/cortex-darwin-arm64.tar.gz -o cortex.tar.gz
tar -xzf cortex.tar.gz
sudo mv cortex /usr/local/bin/
```

#### macOS (Intel)
```bash
curl -L https://downloads.snowflake.com/cortex/cortex-darwin-amd64.tar.gz -o cortex.tar.gz
tar -xzf cortex.tar.gz
sudo mv cortex /usr/local/bin/
```

#### Windows (PowerShell as Administrator)
```powershell
Invoke-WebRequest -Uri "https://downloads.snowflake.com/cortex/cortex-windows-amd64.zip" -OutFile cortex.zip
Expand-Archive cortex.zip -DestinationPath C:\cortex
$env:Path += ";C:\cortex"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [EnvironmentVariableTarget]::User)
```

#### Linux
```bash
curl -L https://downloads.snowflake.com/cortex/cortex-linux-amd64.tar.gz -o cortex.tar.gz
tar -xzf cortex.tar.gz
sudo mv cortex /usr/local/bin/
```

### Step 3: Verify Installation

```bash
cortex --version
```

You should see output like: `cortex version 1.0.x`

---

## Part 2: Authenticate with Snowflake

### Step 1: Create a Connection

Run the interactive connection setup:

```bash
cortex connection add
```

You'll be prompted for:

| Prompt | What to Enter |
|--------|---------------|
| **Connection name** | A friendly name (e.g., `my_connection`) |
| **Account identifier** | Your Snowflake account (e.g., `abc12345.us-east-1`) |
| **Username** | Your Snowflake username |
| **Authentication method** | Choose: `externalbrowser` (SSO), `password`, or `keypair` |

**Recommended:** Use `externalbrowser` for easiest setup — it opens your browser for SSO login.

### Step 2: Test the Connection

```bash
cortex connection test
```

Expected output:
```
Connection successful!
Account: ABC12345
User: YOUR_USERNAME
Role: ACCOUNTADMIN
```

### Step 3: Set Default Connection (Optional)

If you have multiple connections:

```bash
cortex connection use my_connection
```

---

## Part 3: Enable Cortex Code in Snowsight

Cortex Code is built directly into the Snowsight browser interface — no installation or extension required.

### Step 1: Open Snowsight

1. Navigate to your Snowflake account URL in a browser
2. Log in with your credentials
3. Ensure you are using the **ACCOUNTADMIN** role (or a role with sufficient privileges)

### Step 2: Open the Cortex Code Panel

1. Click **Projects** in the left sidebar
2. Select **Workspaces** from the dropdown menu
3. Click **+ Workspace** to create a new workspace (or open an existing one)
4. Inside your workspace, click the **+** button in the tab bar
5. Select **SQL file**
6. The **Cortex Code AI assistant panel** appears on the right side

> **Tip:** The Cortex Code panel is context-aware — it picks up your current database, schema, and role from the Snowsight session automatically.

### Step 3: Verify Connection

In the Cortex Code chat panel, type:

```
What databases exist in my account?
```

CoCo should respond with your database list, confirming it's connected and aware of your environment.

---

## Part 4: Quick Verification Checklist

### CLI

```bash
cortex --version
cortex connection list
cortex connection test
cortex chat
```

In the `cortex chat` session, type:
```
Show me my warehouses
```

*(Exit with Ctrl+C or type 'exit')*

### Snowsight UI

- [ ] Logged into Snowsight
- [ ] Created a workspace with a SQL file
- [ ] Cortex Code panel visible on the right side
- [ ] CoCo responds to a test question

---

## Troubleshooting

### "command not found: cortex"

**macOS/Linux:** Ensure `/usr/local/bin` is in your PATH:
```bash
echo $PATH
```

If not, add it:
```bash
export PATH=$PATH:/usr/local/bin
```

**Windows:** Restart PowerShell after installation.

### "Connection failed"

1. Verify your account identifier format (should be `<account>.<region>` or `<orgname>-<accountname>`)
2. Check network/firewall settings
3. Try `externalbrowser` auth if password fails

### CoCo Panel Not Appearing in Snowsight

If you don't see the Cortex Code icon in the bottom-right corner of Snowsight, check the following:

#### 1. Missing Database Roles

Your user needs two database roles granted. An ACCOUNTADMIN can run:

```sql
-- Required for all users
GRANT DATABASE ROLE SNOWFLAKE.COPILOT_USER TO ROLE <your_role>;

-- At least one of these is also required
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE <your_role>;
-- OR for full agentic capabilities:
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_AGENT_USER TO ROLE <your_role>;
```

#### 2. Cross-Region Inference Not Enabled

Cortex Code requires access to large language models that may not be hosted in your account's region. An ACCOUNTADMIN must enable cross-region inference:

```sql
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'AWS_US';
```

Replace `AWS_US` with the appropriate value for your deployment:

| Value | Description |
|-------|-------------|
| `AWS_US` | Route to US-based AWS regions |
| `AWS_EU` | Route to EU-based AWS regions |
| `AWS_APJ` | Route to Asia-Pacific AWS regions |
| `ANY_REGION` | Route to any available region (most flexible) |

#### 3. Legacy Copilot Was Opted Out

If your account previously disabled Snowflake Copilot (the earlier version of this feature), Cortex Code will also be disabled. Contact your Snowflake account team to re-enable it.

#### 4. Not in a Workspace

Make sure you are inside a **Workspace** (not a standalone worksheet). Navigate to **Projects → Workspaces**, open or create a workspace, and add a **SQL file**. The CoCo icon appears in the bottom-right corner of the workspace.

---

## Next Steps

Now that Cortex Code is installed, continue to:

- **[CoCo CLI Lab](../CoCo%20CLI/)** — Build semantic views, Cortex Agents, and custom skills from the terminal
- **[CoCo UI Lab](../CoCo%20UI/)** — Screenshot debugging, notebooks, Dynamic Tables, and Streamlit apps in Snowsight

---

## Resources

- [Cortex Code Documentation](https://docs.snowflake.com/en/user-guide/cortex-code)
- [Snowflake Free Trial](https://signup.snowflake.com/)
- [Snowflake Community](https://community.snowflake.com/)
