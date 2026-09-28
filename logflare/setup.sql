-- For wal
ALTER SYSTEM SET wal_level = 'logical';

-- Allow user access to replication
-- Originally from priv/repo/migrations/20210729161959_subscribe_to_postgres.exs
-- CURRENT_USER is POSTGRES_USER here; there is no separate `logflare` role.
ALTER USER CURRENT_USER WITH REPLICATION;
