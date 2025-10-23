SELECT
  datname as database_name,
  pg_size_pretty(pg_database_size(datname)) as total_size
FROM pg_database
WHERE datname NOT IN ('template0', 'template1', 'postgres')
ORDER BY pg_database_size(datname) DESC;