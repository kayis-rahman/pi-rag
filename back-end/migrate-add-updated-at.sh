#!/bin/bash
#
# Migration script to add updated_at column to user_devices table
# Usage: ./migrate-add-updated-at.sh [host] [port] [database] [user] [password]
#

HOST=${1:-localhost}
PORT=${2:-5432}
DATABASE=${3:-timebeam}
USER=${4:-timebeam}
PASSWORD=${5:-timebeam}

echo "Applying migration: Add updated_at column to user_devices table"
echo "Connecting to: ${HOST}:${PORT}/${DATABASE}"

PGPASSWORD=$PASSWORD psql -h $HOST -p $PORT -U $USER -d $DATABASE -c "
-- Add updated_at column to user_devices table
ALTER TABLE user_devices
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Set updated_at to created_at for existing records where it's NULL
UPDATE user_devices
SET updated_at = created_at
WHERE updated_at IS NULL;

-- Make column NOT NULL after data migration
ALTER TABLE user_devices
ALTER COLUMN updated_at SET NOT NULL;

-- Verify the column was added successfully
\d+ user_devices
"

if [ $? -eq 0 ]; then
    echo "✅ Migration completed successfully!"
else
    echo "❌ Migration failed!"
    exit 1
fi
