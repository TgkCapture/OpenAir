-- Seed admin user (password: Admin@1234)
INSERT INTO users (email, password_hash, full_name, role) VALUES
('admin@openair.dev', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewKyNiZxGCX5KqH6', 'OpenAir Admin', 'admin');

-- Seed channels
INSERT INTO channels (name, type, stream_url, logo_url, is_premium, is_active, sort_order) VALUES
('TV Channel 1', 'tv', 'http://localhost:8080/hls/tv1.m3u8', null, false, true, 1),
('TV Channel 2', 'tv', 'http://localhost:8080/hls/tv2.m3u8', null, true, true, 2),
('Radio 1',      'radio', 'http://localhost:8080/hls/radio1.m3u8', null, false, true, 1),
('Radio 2',      'radio', 'http://localhost:8080/hls/radio2.m3u8', null, false, true, 2);