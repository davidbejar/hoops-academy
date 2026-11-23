-- athlete-service V11 (WP127, ATH-18): a parent's or player's completion list without an assignment filter selects by
-- tenant (RLS) and player, newest first; plan_completion had only (assignment_id, player_id) and unique (id).
create index plan_completion_player_idx on athlete.plan_completion (tenant_id, player_id, marked_at desc);
