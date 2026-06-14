-- Create app_settings table for global app configuration
-- This table stores theme settings controlled by admin

CREATE TABLE IF NOT EXISTS app_settings (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL DEFAULT '{}',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

-- Everyone can READ app settings (theme applies to all users)
CREATE POLICY "Anyone can read app settings"
  ON app_settings FOR SELECT
  USING (true);

-- Only admin can INSERT/UPDATE app settings
CREATE POLICY "Admin can insert app settings"
  ON app_settings FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Admin can update app settings"
  ON app_settings FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Insert default theme
INSERT INTO app_settings (key, value)
VALUES ('app_theme', '{"theme_mode": 2, "color_index": 0}')
ON CONFLICT (key) DO NOTHING;
