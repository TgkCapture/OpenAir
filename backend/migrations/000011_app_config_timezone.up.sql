-- The station's timezone, as an IANA name such as 'Africa/Blantyre'.
-- It decides where one schedule day ends and the next begins.
ALTER TABLE app_config ADD COLUMN timezone VARCHAR(64) NOT NULL DEFAULT 'UTC';
