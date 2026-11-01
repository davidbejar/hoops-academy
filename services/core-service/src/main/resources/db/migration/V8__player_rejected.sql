-- WP2c: a rejected ADD_PLAYER request leaves the player REJECTED (never admitted), distinct from WITHDRAWN (left the
-- academy, or the requester cancelled the request). No backfill: rows rejected before this migration stay WITHDRAWN
-- (pre-release data only; the approval_request row keeps the decision, and FORCE RLS applies to the migrator too).
alter table core.player drop constraint player_status_check;
alter table core.player add constraint player_status_check
  check (status in ('PENDING_APPROVAL', 'ACTIVE', 'ORPHAN', 'WITHDRAWN', 'REJECTED'));
