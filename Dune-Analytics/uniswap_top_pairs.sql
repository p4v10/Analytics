/*
In this query we will look at the top 5 pairs by volume on Uniswap starting from Jan 1, 2023

Last edited: 07.08.2023

*/

-- get the list of top 5 traded pairs excluding stablescoins
WITH most_traded_pairs AS (
    SELECT DISTINCT
        token_pair, -- like USDC-WETH
        SUM(token_sold_amount) AS amount_of_tokens_sold, -- amount of tokens sold USDC
        SUM(token_bought_amount) AS amount_of_tokens_bought, -- amount of token bought, e.g 1.37 of WETH
        SUM(amount_usd) AS usd_value_tokens -- amount in USD dollars
    FROM dex.trades -- trades on decentralized exchanges table
    WHERE blockchain = 'ethereum'
    AND project = 'uniswap' -- we are only going to look at uniswap protocol on ethereum network
    AND block_date >= DATE('2023-01-01') -- convert date to string and filter for beginning of 2023
    GROUP BY token_pair
    ORDER BY usd_value_tokens DESC
    LIMIT 6
)
SELECT
    DATE_TRUNC('week', dx.block_date) AS week_date, -- get the week date
    tp.token_pair,
    SUM(dx.amount_usd) AS total_weekly_volume -- weekly volume in USD
FROM dex.trades AS dx
INNER JOIN most_traded_pairs AS tp -- join our top 5 pairs
    ON dx.token_pair = tp.token_pair
WHERE SPLIT_PART(CAST(dx.block_date AS varchar), ' ', 1) >= '2023-01-01'
GROUP BY 1, 2
ORDER BY 1 ASC, 2 DESC
;
