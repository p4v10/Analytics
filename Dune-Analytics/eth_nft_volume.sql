WITH total_volume_yearly AS ( -- we would need this to calculate % share of total market volume
    SELECT
        -- get yearly volume for across all collections
        DISTINCT SPLIT_PART(CAST(block_time AS VARCHAR),'-',1) AS year,
        SUM(amount_usd) OVER(PARTITION BY SPLIT_PART(CAST(block_time AS VARCHAR),'-',1)) AS yearly_volume
    FROM nft.trades
    WHERE SPLIT_PART(CAST(block_time AS VARCHAR),'-',1) >= '2018' -- lets look no longer then 2018
), total_volume_monthly_2023 AS ( -- we would need this to calculate % share of total market volume
    SELECT
        -- get monthly volume for across all collections
        DISTINCT SPLIT_PART(CAST(block_time AS VARCHAR),'-',2) AS month,
        SUM(amount_usd) OVER(PARTITION BY SPLIT_PART(CAST(block_time AS VARCHAR),'-',2)) AS monthly_volume
    FROM nft.trades
    WHERE SPLIT_PART(CAST(block_time AS VARCHAR),'-',1) = '2023' -- lets look for 2023
), top_collections_2022 AS (
    SELECT
        DISTINCT
        SPLIT_PART(CAST(block_time AS VARCHAR),'-',1) AS year,
        nft_contract_address, -- NFT contract address
        SUM(amount_usd) AS total_amount_usd -- total USD amount traded per year
    FROM nft.trades
    WHERE SPLIT_PART(CAST(block_time AS VARCHAR),'-',1) = '2022'
    GROUP BY 1,2
    ORDER BY 3 DESC
    LIMIT 100
), join_nft_labels AS (
    SELECT
        DISTINCT
        CASE WHEN tp.nft_contract_address = 0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d
                THEN 'Boredape: BoredApeYachtClub' -- account fo BAYC collections
            WHEN tp.nft_contract_address = 0xed5af388653567af2f388e6224dc7c4b3241c544
                THEN 'Azuki: Azuki' -- account for Azuki collections
            ELSE lab.name
        END AS name, 
        tp.nft_contract_address,
        tp.total_amount_usd,
        (tp.total_amount_usd/tvy.yearly_volume) AS percntage_from_total -- get the percentage share from total volume
    FROM top_collections_2022 AS tp
    INNER JOIN labels.all AS lab
        ON tp.nft_contract_address = lab.address
    LEFT JOIN total_volume_yearly AS tvy
        ON tp.year = tvy.year
    ORDER BY 4 DESC
    LIMIT 10
)
SELECT
    SPLIT_PART(CAST(t.block_time AS VARCHAR),'-',2) AS month,
    jnl.name,
    jnl.nft_contract_address,
    tvm.monthly_volume AS total_market_volume,
    SUM(t.amount_usd) AS monthly_usd_amount, -- monthly volume per collection
    ROUND(SUM(t.amount_usd)/tvm.monthly_volume, 3) AS percentage_of_market_volume,
    jnl.total_amount_usd AS total_volume_2022,
    jnl.percntage_from_total AS perc_share_2022 -- % of total volume in 2022
FROM nft.trades AS t
INNER JOIN join_nft_labels AS jnl
    ON t.nft_contract_address = jnl.nft_contract_address
LEFT JOIN total_volume_monthly_2023 AS tvm
    ON SPLIT_PART(CAST(t.block_time AS VARCHAR),'-',2) = tvm.month
WHERE SPLIT_PART(CAST(t.block_time AS VARCHAR),'-',1) = '2023' -- lets look for the current year (2023)
GROUP BY 1,2,3,4,7,8
ORDER BY 2,1 ASC
;