-- Add updated_at column to user_devices table
-- Migration for existing data to support UserDevice.updatedAt field

ALTER TABLE user_devices
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Set updated_at to created_at for existing records where it's NULL
UPDATE user_devices
SET updated_at = created_at
WHERE updated_at IS NULL;

-- Make the column NOT NULL after data migration
ALTER TABLE user_devices
ALTER COLUMN updated_at SET NOT NULL;
