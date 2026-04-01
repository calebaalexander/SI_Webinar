# Cortex Code in Snowsight: Build a Full Data Pipeline with AI

> **PawCore is a fictional company.** All data, names, metrics, and scenarios are simulated for demonstration purposes only.

Use **Cortex Code** — the AI coding assistant built into Snowflake's web interface — to go from raw data to a fully operational analytics pipeline without writing a single line of code manually. Every exercise runs entirely inside Snowsight. No terminal, no extensions, no external tooling.

---

## What You'll Build

```
Raw Data (7 tables)
  → Notebook (explore support patterns & telemetry correlations)
    → Dynamic Table (auto-refreshing pipeline)
      → Streamlit App (live dashboard)
      → Intelligence Agent (conversational analytics)
```

---

## Prerequisites

- A Snowflake account with **ACCOUNTADMIN** (or sufficient privileges)
- Cortex Code enabled — go to **Settings → Cortex Code** and toggle it on, or ask your account admin
- A modern web browser
- ~45 minutes

---

## Exercises

| # | Exercise | What You'll Do |
|---|----------|----------------|
| 0 | Setup | Load PawCore demo data via CoCo |
| 1 | Fix Broken Code | Fix SQL errors using natural language, the Fix button, and schema introspection |
| 2 | Snowflake Notebook | Build a support ops analysis notebook from a single prompt |
| 3 | Dynamic Table | Operationalize the analysis as an auto-refreshing pipeline |
| 4 | Streamlit App | Deploy a live support ops dashboard |
| 5 | Semantic View + Agent | Create a conversational AI agent for self-service analytics |

---

## Key Concepts

| Concept | What It Is |
|---------|------------|
| **Cortex Code Panel** | AI assistant side panel in Snowsight. Generate SQL, build objects, and debug code using natural language. |
| **Snowflake Notebooks** | Interactive notebooks that run directly in Snowflake — no external kernel needed. |
| **Dynamic Tables** | Declarative tables that auto-refresh when source data changes. Define the query once; Snowflake handles the pipeline. |
| **Streamlit in Snowflake** | Build and deploy interactive web apps inside Snowflake with no external infrastructure. |
| **Snowflake Intelligence** | Conversational AI interface built on Cortex Agents for ad-hoc data exploration. |

---

## Get Started

The full step-by-step guide with all prompts, expected outputs, and validation checklists is in:

**[`cortex-code-ui-hands-on-lab.md`](./cortex-code-ui-hands-on-lab.md)**

All exercise SQL files and the starter notebook are in the [`exercises/`](./exercises/) folder.

---

## Related Resources

- [Cortex Code Documentation](https://docs.snowflake.com/en/user-guide/ui-snowsight-cortex-code)
- [Dynamic Tables Documentation](https://docs.snowflake.com/en/user-guide/dynamic-tables-about)
- [Streamlit in Snowflake Documentation](https://docs.snowflake.com/en/developer-guide/streamlit/about-streamlit)
- [Snowflake Intelligence Documentation](https://docs.snowflake.com/user-guide/snowflake-cortex/snowflake-intelligence)
