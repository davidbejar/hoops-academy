-- Global training plan templates (WP9). Repeatable: Flyway re-runs this file when its checksum changes.
-- Idempotent upserts keyed by stable UUIDs (uuid5); item ids derive from plan id + position.
-- Texts are seeded in English (locale 'en'); the UI translates template names (es / en / id) by id in its own
-- resources, and shows coach content as stored. Tenants cannot change templates (RLS), they copy them.
--
-- The app and migrator roles are subject to FORCEd row level security; templates (owner_tenant_id null) can only
-- be written with the table owner exempted, so FORCE is lifted for the duration of this transaction (DDL is
-- transactional: a failure leaves FORCE in place) and restored before it commits.
alter table athlete.training_plan no force row level security;
alter table athlete.plan_item no force row level security;

insert into athlete.training_plan (id, owner_tenant_id, name, description, is_template, locale)
values ('55a86283-88a0-5ae9-9be6-97c0ed421c07', null, 'Warm-up & mobility', 'Dynamic warm-up that raises heart rate and prepares joints before any session.', true, 'en')
on conflict (id) do update set name = excluded.name, description = excluded.description,
  is_template = true, locale = excluded.locale, owner_tenant_id = null, updated_at = now();
delete from athlete.plan_item where plan_id = '55a86283-88a0-5ae9-9be6-97c0ed421c07';
insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, description, duration_min) values
  ('e3d5a421-2fa1-5002-83c7-f04618af9da2', '55a86283-88a0-5ae9-9be6-97c0ed421c07', null, 0, 'Easy jog and skips', 'Two laps of the court: jog, high knees, butt kicks, side shuffles.', 5),
  ('27b35cc0-3142-58e2-94ce-20b53473c297', '55a86283-88a0-5ae9-9be6-97c0ed421c07', null, 1, 'Dynamic leg swings', 'Front/back and side leg swings, 10 per leg.', 3),
  ('9bc19056-823f-554c-b4b9-5b7014cfa782', '55a86283-88a0-5ae9-9be6-97c0ed421c07', null, 2, 'Hip and ankle mobility', 'Hip circles, ankle rolls and deep lunges with rotation.', 4),
  ('5d29e87d-835c-58b9-806f-df064186fd1a', '55a86283-88a0-5ae9-9be6-97c0ed421c07', null, 3, 'Arm circles and shoulder openers', 'Small to large circles, band-free shoulder dislocates with a towel.', 3),
  ('a78050ba-a429-58a6-9f98-c7a55619a0e3', '55a86283-88a0-5ae9-9be6-97c0ed421c07', null, 4, 'Defensive slide and backpedal lines', 'Slide baseline to baseline, backpedal, sprint.', 5),
  ('5a7ba5ff-f5fa-5cff-aa5b-07b4689449c4', '55a86283-88a0-5ae9-9be6-97c0ed421c07', null, 5, 'Progressive jumps', 'Squat jumps and tuck jumps, building intensity.', 3);

insert into athlete.training_plan (id, owner_tenant_id, name, description, is_template, locale)
values ('1eea7dee-240e-582c-873d-be1b8f6cb283', null, 'Ball handling basics', 'Fundamental dribbling skills with both hands, stationary and moving.', true, 'en')
on conflict (id) do update set name = excluded.name, description = excluded.description,
  is_template = true, locale = excluded.locale, owner_tenant_id = null, updated_at = now();
delete from athlete.plan_item where plan_id = '1eea7dee-240e-582c-873d-be1b8f6cb283';
insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, description, duration_min) values
  ('3e9c60d9-f42a-5444-82be-fb7f86f1bd51', '1eea7dee-240e-582c-873d-be1b8f6cb283', null, 0, 'Stationary pound dribble', 'Low and high pound dribble, 30 seconds each hand.', 4),
  ('69b76d93-e2bc-58ec-bdf8-141cfa2f3dea', '1eea7dee-240e-582c-873d-be1b8f6cb283', null, 1, 'Figure-eight and around-the-leg', 'Control the ball through and around the legs.', 5),
  ('dc7744c6-4117-5f18-bd55-5779c61c3494', '1eea7dee-240e-582c-873d-be1b8f6cb283', null, 2, 'Two-ball dribbling', 'Alternate and simultaneous dribbles, eyes up.', 5),
  ('0164391e-fdf0-506d-9776-80a553b519ae', '1eea7dee-240e-582c-873d-be1b8f6cb283', null, 3, 'Crossover and between-the-legs', 'Walk the line, then at speed.', 8),
  ('9fd42bbc-2429-53e9-9bcb-2099ac1ab552', '1eea7dee-240e-582c-873d-be1b8f6cb283', null, 4, 'Change of pace dribble', 'Slow, fast, slow along the court.', 6),
  ('a31ba770-740e-56a4-ac85-5a0f67ab5656', '1eea7dee-240e-582c-873d-be1b8f6cb283', null, 5, 'Dribble with a defender cue', 'Partner points; react with a crossover or retreat dribble.', 7);

insert into athlete.training_plan (id, owner_tenant_id, name, description, is_template, locale)
values ('51da6d79-c6d1-5e6e-80dd-405d599f4090', null, 'Form shooting', 'Mechanics first: close-range shooting with perfect form before range is added.', true, 'en')
on conflict (id) do update set name = excluded.name, description = excluded.description,
  is_template = true, locale = excluded.locale, owner_tenant_id = null, updated_at = now();
delete from athlete.plan_item where plan_id = '51da6d79-c6d1-5e6e-80dd-405d599f4090';
insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, description, duration_min) values
  ('d987225b-dc7f-5177-ab50-963dd1c48d0f', '51da6d79-c6d1-5e6e-80dd-405d599f4090', null, 0, 'One-hand form shots', 'Shooting hand only, 1 metre from the rim, 15 makes.', 5),
  ('22c8ef40-4d95-5e45-8eec-f2aaa4777b70', '51da6d79-c6d1-5e6e-80dd-405d599f4090', null, 1, 'Both hands form shots', 'Add the guide hand, 15 makes.', 5),
  ('7907e105-582d-5280-800e-60249c8234f8', '51da6d79-c6d1-5e6e-80dd-405d599f4090', null, 2, 'Step-back from three spots', 'Short distance, left, centre, right, 10 each.', 8),
  ('fab587b0-510a-5c33-86dd-fdc556d3179f', '51da6d79-c6d1-5e6e-80dd-405d599f4090', null, 3, 'Catch-and-shoot', 'Partner passes, feet ready, 20 shots.', 8),
  ('33a32db3-8139-5548-801f-ff4ae3a22e33', '51da6d79-c6d1-5e6e-80dd-405d599f4090', null, 4, 'Free-throw line shots', 'Straight-on form from the line, 20 shots.', 6),
  ('8b0addf1-0377-5ff1-ba71-312ca9a1b655', '51da6d79-c6d1-5e6e-80dd-405d599f4090', null, 5, 'Game-speed mid-range', 'Move off a cone, shoot, rebound, repeat.', 8);

insert into athlete.training_plan (id, owner_tenant_id, name, description, is_template, locale)
values ('e06333ee-a8d9-5017-a476-751f9a99b45c', null, 'Free-throw routine', 'Build a repeatable pre-shot routine and shoot under light fatigue.', true, 'en')
on conflict (id) do update set name = excluded.name, description = excluded.description,
  is_template = true, locale = excluded.locale, owner_tenant_id = null, updated_at = now();
delete from athlete.plan_item where plan_id = 'e06333ee-a8d9-5017-a476-751f9a99b45c';
insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, description, duration_min) values
  ('8954d035-c9ef-5b88-b4be-a7366cbd6f31', 'e06333ee-a8d9-5017-a476-751f9a99b45c', null, 0, 'Breathing and routine rehearsal', 'Dribble count, breath, visualise, no ball release.', 3),
  ('540d36e9-aa01-599b-913d-8614edfdc77c', 'e06333ee-a8d9-5017-a476-751f9a99b45c', null, 1, 'Ten free throws', 'Shoot ten with the full routine, record makes.', 6),
  ('5f6b176c-51a6-516a-b33f-1fcf254ddd98', 'e06333ee-a8d9-5017-a476-751f9a99b45c', null, 2, 'Make two in a row', 'Two consecutive makes before moving on, five rounds.', 8),
  ('dd0c04e2-e374-5223-80f5-4a71e25b9f72', 'e06333ee-a8d9-5017-a476-751f9a99b45c', null, 3, 'Fatigue free throws', 'Sprint baseline to baseline, then two free throws, x6.', 10),
  ('4b7367a3-269d-5fae-a026-fe21ceea1832', 'e06333ee-a8d9-5017-a476-751f9a99b45c', null, 4, 'Pressure finish', 'Partner counts score; first to 8 makes out of 10 wins.', 6);

insert into athlete.training_plan (id, owner_tenant_id, name, description, is_template, locale)
values ('7bdee8e3-0ee8-5f9e-ad50-b24203a86937', null, 'Finishing at the rim', 'Layups, floaters and contact finishes with both hands.', true, 'en')
on conflict (id) do update set name = excluded.name, description = excluded.description,
  is_template = true, locale = excluded.locale, owner_tenant_id = null, updated_at = now();
delete from athlete.plan_item where plan_id = '7bdee8e3-0ee8-5f9e-ad50-b24203a86937';
insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, description, duration_min) values
  ('35cefaab-c696-555c-8901-6166bef26d62', '7bdee8e3-0ee8-5f9e-ad50-b24203a86937', null, 0, 'Right and left layup lines', 'Two-step layup, soft touch off the glass.', 6),
  ('e1b54b52-0ede-58af-ac34-c3c7e6a38cfe', '7bdee8e3-0ee8-5f9e-ad50-b24203a86937', null, 1, 'Reverse layup', 'Finish on the far side of the rim.', 6),
  ('dac9351e-bbb0-51e9-8e02-1a1f83be52a4', '7bdee8e3-0ee8-5f9e-ad50-b24203a86937', null, 2, 'Euro step', 'Attack, step through, finish.', 6),
  ('274b2695-a9ac-57fc-801f-80e3cc800bb6', '7bdee8e3-0ee8-5f9e-ad50-b24203a86937', null, 3, 'Floater', 'Short high-arc shot over a cone defender.', 6),
  ('bb506620-23c9-50e1-84a1-bd3a70eb2357', '7bdee8e3-0ee8-5f9e-ad50-b24203a86937', null, 4, 'Contact finishes', 'Finish through a pad, ball high.', 7),
  ('c956242b-2808-5ca3-a562-e9a36d94b3f7', '7bdee8e3-0ee8-5f9e-ad50-b24203a86937', null, 5, 'Game-speed transition finishes', 'Full-court dribble to layup, x8.', 8);

insert into athlete.training_plan (id, owner_tenant_id, name, description, is_template, locale)
values ('5828cd70-c51f-5eb7-aa8b-9193f2d31d3e', null, 'Defensive footwork', 'Stance, slides and closeouts that keep a defender in front of the ball.', true, 'en')
on conflict (id) do update set name = excluded.name, description = excluded.description,
  is_template = true, locale = excluded.locale, owner_tenant_id = null, updated_at = now();
delete from athlete.plan_item where plan_id = '5828cd70-c51f-5eb7-aa8b-9193f2d31d3e';
insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, description, duration_min) values
  ('b03ced21-c3c5-51cd-97f4-fe670916a7e8', '5828cd70-c51f-5eb7-aa8b-9193f2d31d3e', null, 0, 'Stance and slide', 'Low stance, hands active, slide across the key, x6.', 5),
  ('17295378-f854-5ab7-b5fd-c75ae5a6c6fc', '5828cd70-c51f-5eb7-aa8b-9193f2d31d3e', null, 1, 'Drop-step and recover', 'Open the hips, recover to stance.', 5),
  ('5a4d493b-3601-55a6-8aaa-cbce6ca23aeb', '5828cd70-c51f-5eb7-aa8b-9193f2d31d3e', null, 2, 'Closeout drill', 'Sprint, chop steps, hand up, x8.', 6),
  ('792ec5e1-6ebc-5fbb-9fbd-dbf2efb9732e', '5828cd70-c51f-5eb7-aa8b-9193f2d31d3e', null, 3, 'Mirror drill', 'Partner leads, defender mirrors with slides.', 6),
  ('0416b853-f774-50f5-88b1-4f776804cebd', '5828cd70-c51f-5eb7-aa8b-9193f2d31d3e', null, 4, 'Shell drill (4v4)', 'Positioning on ball movement, jump to the pass.', 12),
  ('91f175fc-433d-5544-8f26-1d06406ca78f', '5828cd70-c51f-5eb7-aa8b-9193f2d31d3e', null, 5, 'Charge-taking', 'Set feet and absorb contact with a pad.', 5);

insert into athlete.training_plan (id, owner_tenant_id, name, description, is_template, locale)
values ('04e7d5f6-d05a-5794-a53e-aac6bf3ce48f', null, 'Conditioning (intervals)', 'Court-based interval conditioning; stop early on pain or dizziness.', true, 'en')
on conflict (id) do update set name = excluded.name, description = excluded.description,
  is_template = true, locale = excluded.locale, owner_tenant_id = null, updated_at = now();
delete from athlete.plan_item where plan_id = '04e7d5f6-d05a-5794-a53e-aac6bf3ce48f';
insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, description, duration_min) values
  ('ca8ad256-6b93-5d0e-9d4d-c1758577fc41', '04e7d5f6-d05a-5794-a53e-aac6bf3ce48f', null, 0, 'Easy warm-up jog', 'Three minutes easy.', 3),
  ('f0ac5cd5-1a04-512c-9163-21a6278fbfe2', '04e7d5f6-d05a-5794-a53e-aac6bf3ce48f', null, 1, 'Suicides', 'Four lines to half court; 30 s work, 60 s rest, x4.', 8),
  ('d1e55c14-5874-5698-b1e1-e09dce5955a0', '04e7d5f6-d05a-5794-a53e-aac6bf3ce48f', null, 2, 'Line sprints', 'Baseline to baseline, 20 s work, 40 s rest, x6.', 6),
  ('a7158a06-00f1-503d-9433-7269868763fc', '04e7d5f6-d05a-5794-a53e-aac6bf3ce48f', null, 3, 'Defensive slide intervals', 'Free-throw lane slides, 30 s work, 30 s rest, x6.', 6),
  ('c4bf2cd8-4ed5-5f36-8e82-971c6af58dda', '04e7d5f6-d05a-5794-a53e-aac6bf3ce48f', null, 4, 'Full-court layup relay', 'Two teams, race with a layup at each end.', 8),
  ('c8e8410f-dc5f-5357-9824-19b9eb8272a0', '04e7d5f6-d05a-5794-a53e-aac6bf3ce48f', null, 5, 'Walk and shake out', 'Walk it down and sip water.', 4);

insert into athlete.training_plan (id, owner_tenant_id, name, description, is_template, locale)
values ('f89774bb-eada-53ce-bfbe-a2d7e3c3e195', null, 'Passing & decision making', 'Pass types, spacing and reading the defence.', true, 'en')
on conflict (id) do update set name = excluded.name, description = excluded.description,
  is_template = true, locale = excluded.locale, owner_tenant_id = null, updated_at = now();
delete from athlete.plan_item where plan_id = 'f89774bb-eada-53ce-bfbe-a2d7e3c3e195';
insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, description, duration_min) values
  ('6ddfdd25-01fe-5ab4-92cf-0079bd60d32f', 'f89774bb-eada-53ce-bfbe-a2d7e3c3e195', null, 0, 'Chest and bounce pass pairs', 'Stationary then moving, 2 minutes each.', 5),
  ('d372e215-5f7a-5f8e-a408-05b620558913', 'f89774bb-eada-53ce-bfbe-a2d7e3c3e195', null, 1, 'Overhead and outlet pass', 'Rebound, outlet to the wing, fill lanes.', 6),
  ('cca630ad-1e59-58c3-b06d-97505dbef4ab', 'f89774bb-eada-53ce-bfbe-a2d7e3c3e195', null, 2, 'Three-man weave', 'Pass and go behind, finish with a layup.', 8),
  ('a9aa6841-9acc-5f52-957f-7eba391b3feb', 'f89774bb-eada-53ce-bfbe-a2d7e3c3e195', null, 3, 'Pass fake and pivot', 'Pivot under pressure, make the next pass.', 6),
  ('d44b8542-0835-5463-a1fe-0e04600ac897', 'f89774bb-eada-53ce-bfbe-a2d7e3c3e195', null, 4, '4v3 advantage decisions', 'Attack the numbers; pass or shoot?', 10),
  ('5e6c68cc-0bbf-5bc1-9e47-df165f7cdb5d', 'f89774bb-eada-53ce-bfbe-a2d7e3c3e195', null, 5, 'Small-sided game 3v3', 'Four passes before a shot.', 12);

insert into athlete.training_plan (id, owner_tenant_id, name, description, is_template, locale)
values ('19140123-d5d8-579b-999d-002c3c4eabc1', null, 'Rebounding & box-out', 'Finding the body, boxing out and securing the ball.', true, 'en')
on conflict (id) do update set name = excluded.name, description = excluded.description,
  is_template = true, locale = excluded.locale, owner_tenant_id = null, updated_at = now();
delete from athlete.plan_item where plan_id = '19140123-d5d8-579b-999d-002c3c4eabc1';
insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, description, duration_min) values
  ('2e681409-7528-530a-ad52-03ab0cc457cb', '19140123-d5d8-579b-999d-002c3c4eabc1', null, 0, 'Box-out footwork', 'Pivot into the partner without contact, x10.', 4),
  ('0dcc3be5-20b5-56ca-9cd6-99fb2158288f', '19140123-d5d8-579b-999d-002c3c4eabc1', null, 1, 'Box-out with contact', 'Hold position for three seconds.', 5),
  ('db2bcbdb-93b9-51b6-9f47-a0b67d9d335b', '19140123-d5d8-579b-999d-002c3c4eabc1', null, 2, 'Tip drill', 'Tip the ball off the glass until a secure catch.', 5),
  ('6518d692-2f56-562d-a809-9d6a6be9fccb', '19140123-d5d8-579b-999d-002c3c4eabc1', null, 3, 'Chin the ball', 'Two-hand rebound, chin it and outlet.', 5),
  ('2ec6e412-69c8-5cee-8669-cdb6583d4fc4', '19140123-d5d8-579b-999d-002c3c4eabc1', null, 4, 'Rebounding 2v2', 'Defence boxes out; offence crashes.', 10),
  ('88de9a2e-53dc-596b-9e2e-599bac67adf2', '19140123-d5d8-579b-999d-002c3c4eabc1', null, 5, 'Competitive rebounding game', 'First to 10 rebounds.', 8);

insert into athlete.training_plan (id, owner_tenant_id, name, description, is_template, locale)
values ('bb3471e5-78dc-59a8-b593-b578722f4b31', null, 'Cool-down & stretching', 'Lower heart rate and stretch the main muscle groups.', true, 'en')
on conflict (id) do update set name = excluded.name, description = excluded.description,
  is_template = true, locale = excluded.locale, owner_tenant_id = null, updated_at = now();
delete from athlete.plan_item where plan_id = 'bb3471e5-78dc-59a8-b593-b578722f4b31';
insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, description, duration_min) values
  ('f5dfefc4-ad28-531f-95b9-69ddd0e12234', 'bb3471e5-78dc-59a8-b593-b578722f4b31', null, 0, 'Easy walk and breathing', 'Two laps walking, slow breathing.', 3),
  ('4035fcea-17ab-5c70-9c24-8796938acbbb', 'bb3471e5-78dc-59a8-b593-b578722f4b31', null, 1, 'Calf and hamstring stretch', 'Hold 30 seconds each side.', 4),
  ('ad032209-9af1-5b51-bf38-e7f9aa53878d', 'bb3471e5-78dc-59a8-b593-b578722f4b31', null, 2, 'Quad and hip flexor stretch', 'Hold 30 seconds each side.', 4),
  ('a43d0c7b-32a6-59b7-9faf-41c4f344a0e7', 'bb3471e5-78dc-59a8-b593-b578722f4b31', null, 3, 'Groin and glute stretch', 'Hold 30 seconds each side.', 4),
  ('105a97b3-f90a-5676-a335-1003528e1bea', 'bb3471e5-78dc-59a8-b593-b578722f4b31', null, 4, 'Shoulder and triceps stretch', 'Hold 20 seconds each side.', 3),
  ('c8284862-9120-5bb7-abb6-49050f4bcb64', 'bb3471e5-78dc-59a8-b593-b578722f4b31', null, 5, 'Team reflection', 'Two things that went well, one to improve.', 3);

alter table athlete.training_plan force row level security;
alter table athlete.plan_item force row level security;
