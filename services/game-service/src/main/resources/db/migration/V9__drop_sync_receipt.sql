-- game-service WP126 (GAME-02, GAME-13): game.sync_receipt (V1, a WP7 placeholder) was written once per accepted event
-- and never read; a device's highest client sequence is max(client_seq) over match_event's unique
-- (match_id, device_id, client_seq). match_event's unique key on server_seq alone served no query (every read filters
-- match_id first and uses (match_id, server_seq)); the bigserial keeps the numbers unique. Runs as game_migrator.
drop table game.sync_receipt;

alter table game.match_event drop constraint match_event_server_seq_key;
