-- ============================================================
-- Seed app_settings table with the latest app version info
-- ============================================================

INSERT INTO public.app_settings (key, value)
VALUES (
  'app_version_info',
  '{"version": "1.0.0", "apk_url": "https://files.catbox.moe/s9uxba.apk", "release_notes": "Initial launch with verification chooser and offline theme caching."}'
)
ON CONFLICT (key) DO UPDATE
SET value = EXCLUDED.value;
