-- Create the botron_web database used by the Web dashboard.
--
-- Postgres auto-runs files in /docker-entrypoint-initdb.d/ on first startup
-- (only when data volume is empty). This ensures botron_web exists
-- alongside the litellm database created by POSTGRES_DB.
--
-- To apply to an existing deployment without data loss, create the DB
-- manually: `docker exec botron-postgres psql -U decepticon -c "CREATE DATABASE botron_web;"`

CREATE DATABASE botron_web;
GRANT ALL PRIVILEGES ON DATABASE botron_web TO decepticon;
