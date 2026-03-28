-- ========================================================================
-- Exercise 1: Fix Code with CoCo
-- ========================================================================
-- Paste this broken query into your SQL worksheet.
-- It contains 4 errors. You'll fix them using CoCo's natural language and Fix button.
-- ========================================================================

SELECT region, severity, COUNT(*) as tiket_count
FROM PAWCORE_ANALYTICS.SUPORT.SUPPORT_TICKETS
GROUP BY region, severity
ORDER BY tiket_count DES;

-- ERROR 1: DES should be DESC
--   → Fix with: natural language (select DES, Add to Chat, type "Fix this")
--
-- ERROR 2: SUPORT should be SUPPORT
--   → Fix with: the inline Fix button (run the query, click Fix on the error)
--
-- ERROR 3: severity should be PRIORITY (actual column name)
--   → Fix with: Fix button (run the query, click Fix on the error. CoCo introspects the table schema)
--
-- ERROR 4: tiket_count should be ticket_count (cosmetic typo)
--   → Fix with: natural language (select the query, Add to Chat, type "Fix the typo. tiket_count should be ticket_count")
