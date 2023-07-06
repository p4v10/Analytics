-- The goal of this analysis is to understand the weekly performance of inscriptions and fees in the Bitcoin transactions dataset.
-- By calculating weekly metrics such as total inscriptions, total fees, average weekly inscriptions, average weekly percentage change in inscriptions, and average weekly fees, we aim to gain insights into the trends and fluctuations in these metrics over time.

-- Last edited: 07.05.2023
WITH base_metrics AS (
    SELECT
        DATE_TRUNC('week', block_time) AS week_date,
    	COUNT(*) AS weekly_inscriptions, -- weekly inscriptions
    	SUM(COUNT(*)) OVER (ORDER BY DATE_TRUNC('week', block_time) RANGE UNBOUNDED PRECEDING) AS total_inscriptions, -- cumulative inscriptions
    	SUM(fee) AS weekly_fees, -- weekly fees
    	SUM(SUM(fee)) OVER (ORDER BY DATE_TRUNC('week', block_time) RANGE UNBOUNDED PRECEDING) AS total_fees -- cumulative fees
    FROM bitcoin.transactions
    WHERE 1 = 1
    	AND block_height > 767429 -- from block
    	AND CAST(hex AS VARCHAR) LIKE '%0063036f726401%' -- filter for inscriptions
    GROUP BY 1
),
dataviz_ready AS (
    SELECT
        bm.week_date,
        bm.weekly_inscriptions,
        bm.weekly_inscriptions - LAG(bm.weekly_inscriptions) OVER (ORDER BY bm.week_date ASC) AS weekly_inscriptions_change, -- calculate weekly raw change
        CAST(bm.weekly_inscriptions - LAG(bm.weekly_inscriptions) OVER (ORDER BY bm.week_date ASC) AS double) / LAG(bm.weekly_inscriptions) OVER (ORDER BY bm.week_date ASC) * 100 AS weekly_inscriptions_change_percentage, -- weekly percentage change
        bm.total_inscriptions,
        bm.weekly_fees,
        bm.total_fees
    FROM base_metrics AS bm
    WHERE bm.week_date >= DATE('2023-01-02') -- filter our 2022 dates
    ORDER BY bm.week_date DESC
)
-- reporting metrics
SELECT
    MAX(week_date) AS current_week_start,
    MAX(total_inscriptions) AS total_inscriptions, -- total inscriptions
    MAX(total_fees) AS total_fees, -- total fees
    AVG(weekly_inscriptions) AS avg_weekly_inscriptions, -- average weekly inscriptions metric
    AVG(weekly_inscriptions_change_percentage) AS avg_weekly_inscriptions_change_percentage, -- WoW percentage change
    AVG(weekly_fees) AS avg_weekly_fees -- fees per week on average
FROM dataviz_ready
;
