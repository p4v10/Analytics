/*
In this query...

Dune Query - 

Last edited: 10.29.2023

*/

-- DEX volume and comparison
SELECT
    *
FROM dex.trades 
WHERE blockchain = 'ethereum'
limit 55;