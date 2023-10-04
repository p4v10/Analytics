/*
In this query, we will look at the wallet distibution by BTC holdings.

Dune Query - https://dune.com/queries/3071755

Last edited: 10.03.2023

*/

WITH bitcoin_wallets AS ( -- get the wallets btc holdings
    SELECT
        bo.address AS wallet_address,
        SUM(bo.value) AS wallet_balance -- total wallet balance
    FROM bitcoin.outputs bo
    WHERE bo.address IS NOT NULL
      AND bo.type != 'nulldata' -- unclassified wallets
      AND NOT EXISTS (SELECT 1 FROM bitcoin.inputs bi
                      WHERE bi.spent_tx_id = bo.tx_id) -- selecting only unspent balances (current balance)
    GROUP BY bo.address
    HAVING SUM(bo.value) >= 0.1 -- wallets with at least 0.1 BTC
),
wallet_types AS (
    SELECT
        bw.wallet_address,
        bw.wallet_balance,
        CASE WHEN bw.wallet_balance >= 0.1 AND bw.wallet_balance <= 1 THEN 'Shrimp <1'
             WHEN bw.wallet_balance > 1 AND bw.wallet_balance <= 10 THEN 'Crab 1-10'
             WHEN bw.wallet_balance > 10 AND bw.wallet_balance <= 50 THEN 'Octopus 10-50'
             WHEN bw.wallet_balance > 50 AND bw.wallet_balance <= 100 THEN 'Fish 50-100'
             WHEN bw.wallet_balance > 100 AND bw.wallet_balance <= 500 THEN 'Dolphin 100-500'
             WHEN bw.wallet_balance > 500 AND bw.wallet_balance <= 1000 THEN 'Shark 500-1k'
             WHEN bw.wallet_balance > 1000 AND bw.wallet_balance <= 5000 THEN 'Whale 1k-5k'
             WHEN bw.wallet_balance > 5000 THEN 'Humpback >5k'
        END AS wallet_holdings
        --^ wallet classification by amount of BTC held
    FROM bitcoin_wallets AS bw
), balance_distribution AS (
    SELECT
        wt.wallet_holdings,
        COUNT(wt.wallet_address) AS total_addresses -- amount of addresses for a specific classification of holders
    FROM wallet_types AS wt
    GROUP BY wt.wallet_holdings
) -- final query to get raw addresses with percentage share
SELECT
    bd.wallet_holdings,
    bd.total_addresses,
    ROUND((CAST(bd.total_addresses AS REAL) / CAST((SELECT SUM(total_addresses) AS all_addresses FROM balance_distribution) AS REAL)), 5) * 100 as percentage_share
    --^ get the total amount of addresses in scope and calculate percentage
FROM balance_distribution AS bd
;