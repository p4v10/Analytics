/* get the amunt of sent bitcoins and map it to the owner and sender */
SELECT
  t.block_time,
  t.block_date,
  t.input_value,
  t.output_value,
  t.block_hash
FROM bitcoin.transactions AS t
JOIN bitcoin.blocks AS b
  ON t.block_hash = b.hash
WHERE t.is_coinbase = FALSE
LIMIT 55;