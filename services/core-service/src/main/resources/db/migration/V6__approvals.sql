-- ============================================================================
-- WP5 / V6 — approvals: approval_request (plan §2 "Approvals (core)").
-- ADD_PLAYER references the player row created together with the request (status PENDING_APPROVAL), so player_id
-- is never null. An ADMIN's own action is stored as an already APPROVED row (decided by the requester).
-- ============================================================================
create table core.approval_request (
  id                    uuid primary key,
  tenant_id             uuid not null,
  action                text not null check (action in ('ADD_PLAYER', 'WITHDRAW_PLAYER')),
  player_id             uuid not null,
  payload               jsonb not null default '{}'::jsonb,
  requested_by_person_id uuid not null,
  status                text not null default 'PENDING' check (status in ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED')),
  decided_by_person_id  uuid,
  decided_at            timestamptz,
  decision_note         text check (char_length(decision_note) <= 500),
  created_at            timestamptz not null default now(),
  version               bigint not null default 0,
  check ((status = 'PENDING') = (decided_at is null and decided_by_person_id is null)),
  foreign key (tenant_id, player_id) references core.player (tenant_id, id),
  foreign key (tenant_id, requested_by_person_id) references core.person (tenant_id, id),
  foreign key (tenant_id, decided_by_person_id) references core.person (tenant_id, id)
);
-- one PENDING request per (action, player)
create unique index approval_request_pending_uq on core.approval_request (tenant_id, action, player_id)
  where status = 'PENDING';
create index approval_request_status_idx on core.approval_request (tenant_id, status, created_at desc);
create index approval_request_requester_idx on core.approval_request (tenant_id, requested_by_person_id, created_at desc);
select app.enable_tenant_rls('core.approval_request');
