-- Create Matrix Synapse database with UTF8 encoding
SELECT 'CREATE DATABASE matrix_synapse ENCODING UTF8 LC_COLLATE ''en_US.UTF-8'' LC_CTYPE ''en_US.UTF-8'' TEMPLATE template0' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'matrix_synapse')\gexec

-- Create matrix_synapse user if not exists
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'matrix_synapse') THEN
    CREATE USER matrix_synapse;
  END IF;
END
$$;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE matrix_synapse TO matrix_synapse;
ALTER DATABASE matrix_synapse OWNER TO matrix_synapse;
