-- ========================================================================
-- Exercise 1: Three Ways to Fix Code
-- ========================================================================
-- Paste this broken query into your SQL worksheet.
-- It contains 4 errors. You'll fix them using three different methods.
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
--   → Fix with: screenshot (screenshot the error, paste into CoCo, type "Fix this error")
--
-- ERROR 4: tiket_count should be ticket_count (cosmetic typo)
--   → Fix with: screenshot (screenshot the results, paste into CoCo, type "Fix the typo in this query")
