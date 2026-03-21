-- Create synapse_user if it doesn't exist
DO
$do$
BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_user WHERE usename = 'synapse_user'
  ) THEN
    CREATE USER synapse_user WITH PASSWORD 'synapse_password';
  END IF;
END
$do$;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE synapse TO synapse_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO synapse_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO synapse_user;
