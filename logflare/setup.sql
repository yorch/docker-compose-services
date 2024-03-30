-- For wal
ALTER SYSTEM SET wal_level = 'logical';

-- Allow user access to replication
-- Originally from priv/repo/migrations/20210729161959_subscribe_to_postgres.exs
ALTER USER logflare WITH REPLICATION;
