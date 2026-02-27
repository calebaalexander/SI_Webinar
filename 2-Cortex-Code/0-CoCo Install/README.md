# Cortex Code Installation & Setup Guide

Get Cortex Code (CoCo) running on your machine in minutes. This guide covers both the **CLI** (terminal) and **Desktop UI** (VS Code extension).

---

## Prerequisites

Before you begin, ensure you have:

| Requirement | Details |
|-------------|---------|
| **Snowflake Account** | Trial or paid account ([sign up free](https://signup.snowflake.com/)) |
| **Account Role** | ACCOUNTADMIN or role with CREATE DATABASE privileges |
| **Operating System** | macOS, Windows, or Linux |
| **Terminal Access** | Terminal (macOS/Linux) or PowerShell/CMD (Windows) |
| **VS Code** (for Desktop UI) | [Download VS Code](https://code.visualstudio.com/) |

---

## Part 1: Install Cortex Code CLI

### Step 1: Download the CLI

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

### Step 2: Verify Installation

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

## Part 3: Enable Desktop UI (VS Code Extension)

### Step 1: Install the Extension

1. Open **VS Code**
2. Go to **Extensions** (Cmd+Shift+X on Mac, Ctrl+Shift+X on Windows)
3. Search for **"Cortex Code"** or **"Snowflake Cortex"**
4. Click **Install**

### Step 2: Configure the Extension

1. Open **VS Code Settings** (Cmd+, on Mac, Ctrl+, on Windows)
2. Search for **"Cortex"**
3. Set your default connection name (same as CLI)

### Step 3: Activate Cortex Code Panel

1. Click the **Cortex Code icon** in the VS Code sidebar (left panel)
2. Or use the keyboard shortcut: **Cmd+Shift+P** → "Cortex Code: Open Chat"

### Step 4: Verify Connection

In the Cortex Code chat panel, type:

```
What Snowflake account am I connected to?
```

CoCo should respond with your account details.

---

## Part 4: Quick Verification Checklist

Run through these commands to confirm everything is working:

```bash
# Check CLI version
cortex --version

# List connections
cortex connection list

# Test active connection
cortex connection test

# Start an interactive session
cortex chat
```

In VS Code:
- [ ] Cortex Code extension installed
- [ ] Cortex Code icon visible in sidebar
- [ ] Chat panel opens and responds

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

### VS Code Extension Not Responding

1. Reload VS Code window (Cmd+Shift+P → "Reload Window")
2. Check that CLI is installed and working first
3. Verify connection name in VS Code settings matches CLI

---

## Next Steps

Now that Cortex Code is installed, continue to:

- **[CoCo CLI Lab](../CoCo%20CLI/)** — Build semantic views and agents from the terminal
- **[CoCo UI Lab](../CoCo%20UI/)** — Visual development with VS Code integration

---

## Resources

- [Cortex Code Documentation](https://docs.snowflake.com/en/user-guide/cortex-code)
- [Snowflake Free Trial](https://signup.snowflake.com/)
- [Snowflake Community](https://community.snowflake.com/)
