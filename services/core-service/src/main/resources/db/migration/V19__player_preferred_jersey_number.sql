-- ============================================================================
-- WP96 / V19 — a player's preferred jersey number (decision 70, ADR-0048)
-- A wish, not an assignment: nullable, the pattern of team_player.jersey_number ("0", "00" and "7" are different
-- numbers), not unique (two players may prefer the same number; staff decide on assignment). The table keeps its RLS
-- (V5) and its grants; core_platform still reads nothing of core.player.
-- ============================================================================

alter table core.player add column preferred_jersey_number text
  constraint player_preferred_jersey_number_check check (preferred_jersey_number ~ '^[0-9]{1,2}$');
