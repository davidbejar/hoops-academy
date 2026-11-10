-- Global training plan templates (WP9). Repeatable: Flyway re-runs this file when its checksum changes.
-- Idempotent upserts keyed by stable UUIDs (uuid5); item ids derive from plan id + position.
-- Plan texts are seeded in English (locale 'en', the name / description columns) with Spanish and Indonesian in i18n
-- (V4, decision 43); the service shows them in the caller's language and a copy keeps the language it was made in.
-- name_key is a stable key per template. Tenants cannot change templates (RLS), they copy them.
--
-- Items (WP92, decision 72, ADR-0047): every item references its exercise of the global catalogue
-- (R__exercise_catalogue.sql, which runs first) and takes the exercise's texts (title, description, es / id
-- translations); the duration is the template's own. A template is a curated list of catalogue exercises.
--
-- The app and migrator roles are subject to FORCEd row level security; templates (owner_tenant_id null) can only
-- be written, and the global exercises read, with the table owner exempted, so FORCE is lifted for the duration of
-- this transaction (DDL is transactional: a failure leaves FORCE in place) and restored before it commits.
alter table athlete.training_plan no force row level security;
alter table athlete.plan_item no force row level security;
alter table athlete.exercise no force row level security;

insert into athlete.training_plan (id, owner_tenant_id, name_key, name, description, is_template, locale, i18n)
values ('55a86283-88a0-5ae9-9be6-97c0ed421c07', null, 'warm-up-mobility', 'Warm-up & mobility', 'Dynamic warm-up that raises heart rate and prepares joints before any session.', true, 'en',
  '{"es": {"name": "Calentamiento y movilidad", "description": "Calentamiento dinámico que eleva el pulso y prepara las articulaciones antes de cualquier sesión."}, "id": {"name": "Pemanasan & mobilitas", "description": "Pemanasan dinamis untuk menaikkan denyut jantung dan menyiapkan sendi sebelum setiap sesi."}}')
on conflict (id) do update set name_key = excluded.name_key, name = excluded.name,
  description = excluded.description, is_template = true, locale = excluded.locale, i18n = excluded.i18n,
  owner_tenant_id = null, updated_at = now();
delete from athlete.plan_item where plan_id = '55a86283-88a0-5ae9-9be6-97c0ed421c07';
insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, description, duration_min, i18n,
  exercise_id)
select v.id, '55a86283-88a0-5ae9-9be6-97c0ed421c07', null, v.position, e.title, e.description, v.duration_min, e.i18n, e.id
  from (values
    ('e3d5a421-2fa1-5002-83c7-f04618af9da2'::uuid, 0, 5, '5772ac6a-8d9e-5070-aab9-468e730aea86'::uuid),  -- Easy jog and skips
    ('27b35cc0-3142-58e2-94ce-20b53473c297'::uuid, 1, 3, 'aadac5db-cfd6-5a64-b1a2-c574b7019820'::uuid),  -- Dynamic leg swings
    ('9bc19056-823f-554c-b4b9-5b7014cfa782'::uuid, 2, 4, 'd5b60d22-da5f-537f-b0fa-4ef5383b760d'::uuid),  -- Hip and ankle mobility
    ('5d29e87d-835c-58b9-806f-df064186fd1a'::uuid, 3, 3, '4481bf2d-fe0a-5693-9b49-a4d814f6a916'::uuid),  -- Arm circles and shoulder openers
    ('a78050ba-a429-58a6-9f98-c7a55619a0e3'::uuid, 4, 5, '0311c481-ef0e-51d4-a466-378cc159dc03'::uuid),  -- Defensive slide and backpedal lines
    ('5a7ba5ff-f5fa-5cff-aa5b-07b4689449c4'::uuid, 5, 3, 'e10d1ed4-dc8a-5593-bf8d-814a6a81a512'::uuid)  -- Progressive jumps
  ) v(id, position, duration_min, exercise_id)
  join athlete.exercise e on e.id = v.exercise_id;

insert into athlete.training_plan (id, owner_tenant_id, name_key, name, description, is_template, locale, i18n)
values ('1eea7dee-240e-582c-873d-be1b8f6cb283', null, 'ball-handling-basics', 'Ball handling basics', 'Fundamental dribbling skills with both hands, stationary and moving.', true, 'en',
  '{"es": {"name": "Fundamentos de manejo de balón", "description": "Habilidades básicas de bote con ambas manos, en estático y en movimiento."}, "id": {"name": "Dasar-dasar menggiring bola", "description": "Keterampilan dasar dribel dengan kedua tangan, di tempat dan sambil bergerak."}}')
on conflict (id) do update set name_key = excluded.name_key, name = excluded.name,
  description = excluded.description, is_template = true, locale = excluded.locale, i18n = excluded.i18n,
  owner_tenant_id = null, updated_at = now();
delete from athlete.plan_item where plan_id = '1eea7dee-240e-582c-873d-be1b8f6cb283';
insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, description, duration_min, i18n,
  exercise_id)
select v.id, '1eea7dee-240e-582c-873d-be1b8f6cb283', null, v.position, e.title, e.description, v.duration_min, e.i18n, e.id
  from (values
    ('3e9c60d9-f42a-5444-82be-fb7f86f1bd51'::uuid, 0, 4, '0896c70c-e24a-5107-94c5-47ebbfa473ae'::uuid),  -- Stationary pound dribble
    ('69b76d93-e2bc-58ec-bdf8-141cfa2f3dea'::uuid, 1, 5, '7246ee01-d900-53db-aeab-384b0400455b'::uuid),  -- Figure-eight and around-the-leg
    ('dc7744c6-4117-5f18-bd55-5779c61c3494'::uuid, 2, 5, '2047c77c-65ee-559e-8a4d-4b2ee42cf955'::uuid),  -- Two-ball dribbling
    ('0164391e-fdf0-506d-9776-80a553b519ae'::uuid, 3, 8, '878cf9f7-8402-5211-9190-4717dbdb2c7a'::uuid),  -- Crossover and between-the-legs
    ('9fd42bbc-2429-53e9-9bcb-2099ac1ab552'::uuid, 4, 6, '0ef5ec55-9c33-580a-81c3-3983175ca46f'::uuid),  -- Change of pace dribble
    ('a31ba770-740e-56a4-ac85-5a0f67ab5656'::uuid, 5, 7, 'c702bd7c-97ab-5841-a3cd-549e7d52facc'::uuid)  -- Dribble with a defender cue
  ) v(id, position, duration_min, exercise_id)
  join athlete.exercise e on e.id = v.exercise_id;

insert into athlete.training_plan (id, owner_tenant_id, name_key, name, description, is_template, locale, i18n)
values ('51da6d79-c6d1-5e6e-80dd-405d599f4090', null, 'form-shooting', 'Form shooting', 'Mechanics first: close-range shooting with perfect form before range is added.', true, 'en',
  '{"es": {"name": "Técnica de tiro", "description": "Primero la mecánica: tiro cercano con técnica perfecta antes de ganar distancia."}, "id": {"name": "Teknik menembak", "description": "Mekanika dulu: tembakan jarak dekat dengan teknik sempurna sebelum menambah jarak."}}')
on conflict (id) do update set name_key = excluded.name_key, name = excluded.name,
  description = excluded.description, is_template = true, locale = excluded.locale, i18n = excluded.i18n,
  owner_tenant_id = null, updated_at = now();
delete from athlete.plan_item where plan_id = '51da6d79-c6d1-5e6e-80dd-405d599f4090';
insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, description, duration_min, i18n,
  exercise_id)
select v.id, '51da6d79-c6d1-5e6e-80dd-405d599f4090', null, v.position, e.title, e.description, v.duration_min, e.i18n, e.id
  from (values
    ('d987225b-dc7f-5177-ab50-963dd1c48d0f'::uuid, 0, 5, '1062744f-053a-5677-a92b-45b3b925c6d5'::uuid),  -- One-hand form shots
    ('22c8ef40-4d95-5e45-8eec-f2aaa4777b70'::uuid, 1, 5, '79a376b7-163a-5866-9073-15e5963b9bc5'::uuid),  -- Both hands form shots
    ('7907e105-582d-5280-800e-60249c8234f8'::uuid, 2, 8, 'b54d6f6e-5935-5ca6-8fac-e79b325c92a8'::uuid),  -- Step-back from three spots
    ('fab587b0-510a-5c33-86dd-fdc556d3179f'::uuid, 3, 8, '50217c97-2f1f-5c34-a6ea-68a86c794679'::uuid),  -- Catch-and-shoot
    ('33a32db3-8139-5548-801f-ff4ae3a22e33'::uuid, 4, 6, '8e421448-7029-5ce9-a09d-358a1e5cf7cf'::uuid),  -- Free-throw line shots
    ('8b0addf1-0377-5ff1-ba71-312ca9a1b655'::uuid, 5, 8, 'fa8fbfa7-3a2a-5bcd-a7d7-210ad4cff446'::uuid)  -- Game-speed mid-range
  ) v(id, position, duration_min, exercise_id)
  join athlete.exercise e on e.id = v.exercise_id;

insert into athlete.training_plan (id, owner_tenant_id, name_key, name, description, is_template, locale, i18n)
values ('e06333ee-a8d9-5017-a476-751f9a99b45c', null, 'free-throw-routine', 'Free-throw routine', 'Build a repeatable pre-shot routine and shoot under light fatigue.', true, 'en',
  '{"es": {"name": "Rutina de tiros libres", "description": "Construye una rutina previa al tiro repetible y tira con fatiga ligera."}, "id": {"name": "Rutinitas lemparan bebas", "description": "Bangun rutinitas sebelum menembak yang konsisten dan menembak dalam kondisi sedikit lelah."}}')
on conflict (id) do update set name_key = excluded.name_key, name = excluded.name,
  description = excluded.description, is_template = true, locale = excluded.locale, i18n = excluded.i18n,
  owner_tenant_id = null, updated_at = now();
delete from athlete.plan_item where plan_id = 'e06333ee-a8d9-5017-a476-751f9a99b45c';
insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, description, duration_min, i18n,
  exercise_id)
select v.id, 'e06333ee-a8d9-5017-a476-751f9a99b45c', null, v.position, e.title, e.description, v.duration_min, e.i18n, e.id
  from (values
    ('8954d035-c9ef-5b88-b4be-a7366cbd6f31'::uuid, 0, 3, '58a16c84-3f12-5b0c-b401-8aecccf8931d'::uuid),  -- Breathing and routine rehearsal
    ('540d36e9-aa01-599b-913d-8614edfdc77c'::uuid, 1, 6, '042d0933-c076-51b4-a2e9-de35e07659e1'::uuid),  -- Ten free throws
    ('5f6b176c-51a6-516a-b33f-1fcf254ddd98'::uuid, 2, 8, '4c9185fc-0810-58ec-a55d-8b92afc30f8f'::uuid),  -- Make two in a row
    ('dd0c04e2-e374-5223-80f5-4a71e25b9f72'::uuid, 3, 10, 'd4399cfd-7282-5e81-a023-eba7d9754042'::uuid),  -- Fatigue free throws
    ('4b7367a3-269d-5fae-a026-fe21ceea1832'::uuid, 4, 6, '843930fd-714c-5f29-9447-843d21c18738'::uuid)  -- Pressure finish
  ) v(id, position, duration_min, exercise_id)
  join athlete.exercise e on e.id = v.exercise_id;

insert into athlete.training_plan (id, owner_tenant_id, name_key, name, description, is_template, locale, i18n)
values ('7bdee8e3-0ee8-5f9e-ad50-b24203a86937', null, 'finishing-at-the-rim', 'Finishing at the rim', 'Layups, floaters and contact finishes with both hands.', true, 'en',
  '{"es": {"name": "Finalización junto al aro", "description": "Bandejas, bombas y finalizaciones con contacto con ambas manos."}, "id": {"name": "Penyelesaian di dekat ring", "description": "Layup, floater dan penyelesaian dengan kontak menggunakan kedua tangan."}}')
on conflict (id) do update set name_key = excluded.name_key, name = excluded.name,
  description = excluded.description, is_template = true, locale = excluded.locale, i18n = excluded.i18n,
  owner_tenant_id = null, updated_at = now();
delete from athlete.plan_item where plan_id = '7bdee8e3-0ee8-5f9e-ad50-b24203a86937';
insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, description, duration_min, i18n,
  exercise_id)
select v.id, '7bdee8e3-0ee8-5f9e-ad50-b24203a86937', null, v.position, e.title, e.description, v.duration_min, e.i18n, e.id
  from (values
    ('35cefaab-c696-555c-8901-6166bef26d62'::uuid, 0, 6, 'c29ba40d-8830-5d99-9af8-d932d567a48c'::uuid),  -- Right and left layup lines
    ('e1b54b52-0ede-58af-ac34-c3c7e6a38cfe'::uuid, 1, 6, 'e0b2c114-895d-5537-bcdf-eae9c02781f5'::uuid),  -- Reverse layup
    ('dac9351e-bbb0-51e9-8e02-1a1f83be52a4'::uuid, 2, 6, '75a93afa-7190-5b59-8390-f302c565a981'::uuid),  -- Euro step
    ('274b2695-a9ac-57fc-801f-80e3cc800bb6'::uuid, 3, 6, '81d47992-0d9e-5e20-b827-ea50813e0dd9'::uuid),  -- Floater
    ('bb506620-23c9-50e1-84a1-bd3a70eb2357'::uuid, 4, 7, '946cf5df-936b-5cd7-a25c-e44d8d91dafc'::uuid),  -- Contact finishes
    ('c956242b-2808-5ca3-a562-e9a36d94b3f7'::uuid, 5, 8, '2d9db179-f809-5228-bfdd-86a207ea81f6'::uuid)  -- Game-speed transition finishes
  ) v(id, position, duration_min, exercise_id)
  join athlete.exercise e on e.id = v.exercise_id;

insert into athlete.training_plan (id, owner_tenant_id, name_key, name, description, is_template, locale, i18n)
values ('5828cd70-c51f-5eb7-aa8b-9193f2d31d3e', null, 'defensive-footwork', 'Defensive footwork', 'Stance, slides and closeouts that keep a defender in front of the ball.', true, 'en',
  '{"es": {"name": "Trabajo de pies defensivo", "description": "Posición, desplazamientos y cierres que mantienen al defensor delante del balón."}, "id": {"name": "Gerak kaki bertahan", "description": "Kuda-kuda, geser dan closeout agar pemain bertahan tetap di depan bola."}}')
on conflict (id) do update set name_key = excluded.name_key, name = excluded.name,
  description = excluded.description, is_template = true, locale = excluded.locale, i18n = excluded.i18n,
  owner_tenant_id = null, updated_at = now();
delete from athlete.plan_item where plan_id = '5828cd70-c51f-5eb7-aa8b-9193f2d31d3e';
insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, description, duration_min, i18n,
  exercise_id)
select v.id, '5828cd70-c51f-5eb7-aa8b-9193f2d31d3e', null, v.position, e.title, e.description, v.duration_min, e.i18n, e.id
  from (values
    ('b03ced21-c3c5-51cd-97f4-fe670916a7e8'::uuid, 0, 5, '9b27c645-5f39-56d8-af48-a443ccacff82'::uuid),  -- Stance and slide
    ('17295378-f854-5ab7-b5fd-c75ae5a6c6fc'::uuid, 1, 5, '67040828-d457-5a8f-8ddb-34b920d4537a'::uuid),  -- Drop-step and recover
    ('5a4d493b-3601-55a6-8aaa-cbce6ca23aeb'::uuid, 2, 6, 'c3f76702-a60d-5f91-bcf6-b8275ee4a939'::uuid),  -- Closeout drill
    ('792ec5e1-6ebc-5fbb-9fbd-dbf2efb9732e'::uuid, 3, 6, '9363ddeb-42da-5251-8a09-2c7924ed4c32'::uuid),  -- Mirror drill
    ('0416b853-f774-50f5-88b1-4f776804cebd'::uuid, 4, 12, 'e9eec0a9-10a5-5bea-94e0-d8e85658f336'::uuid),  -- Shell drill (4v4)
    ('91f175fc-433d-5544-8f26-1d06406ca78f'::uuid, 5, 5, '2a125be5-df22-55aa-b2a8-4543ca499787'::uuid)  -- Charge-taking
  ) v(id, position, duration_min, exercise_id)
  join athlete.exercise e on e.id = v.exercise_id;

insert into athlete.training_plan (id, owner_tenant_id, name_key, name, description, is_template, locale, i18n)
values ('04e7d5f6-d05a-5794-a53e-aac6bf3ce48f', null, 'conditioning-intervals', 'Conditioning (intervals)', 'Court-based interval conditioning; stop early on pain or dizziness.', true, 'en',
  '{"es": {"name": "Acondicionamiento (intervalos)", "description": "Acondicionamiento por intervalos en la cancha; para antes si hay dolor o mareo."}, "id": {"name": "Kondisi fisik (interval)", "description": "Latihan kondisi interval di lapangan; berhenti lebih awal jika nyeri atau pusing."}}')
on conflict (id) do update set name_key = excluded.name_key, name = excluded.name,
  description = excluded.description, is_template = true, locale = excluded.locale, i18n = excluded.i18n,
  owner_tenant_id = null, updated_at = now();
delete from athlete.plan_item where plan_id = '04e7d5f6-d05a-5794-a53e-aac6bf3ce48f';
insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, description, duration_min, i18n,
  exercise_id)
select v.id, '04e7d5f6-d05a-5794-a53e-aac6bf3ce48f', null, v.position, e.title, e.description, v.duration_min, e.i18n, e.id
  from (values
    ('ca8ad256-6b93-5d0e-9d4d-c1758577fc41'::uuid, 0, 3, 'f139dac3-58dc-5fad-b2f2-279ff23a0ed9'::uuid),  -- Easy warm-up jog
    ('f0ac5cd5-1a04-512c-9163-21a6278fbfe2'::uuid, 1, 8, 'b71467aa-790c-52b7-9590-d435137bed4e'::uuid),  -- Suicides
    ('d1e55c14-5874-5698-b1e1-e09dce5955a0'::uuid, 2, 6, '9d48d6a0-8beb-5661-95d5-39aca02c7855'::uuid),  -- Line sprints
    ('a7158a06-00f1-503d-9433-7269868763fc'::uuid, 3, 6, '246df099-8e47-5cd1-80c5-c95809a48166'::uuid),  -- Defensive slide intervals
    ('c4bf2cd8-4ed5-5f36-8e82-971c6af58dda'::uuid, 4, 8, '538d7b75-1a68-5121-a743-7610fac7f80b'::uuid),  -- Full-court layup relay
    ('c8e8410f-dc5f-5357-9824-19b9eb8272a0'::uuid, 5, 4, '15f0cb23-eeff-5a8e-8ff4-c8a218a24965'::uuid)  -- Walk and shake out
  ) v(id, position, duration_min, exercise_id)
  join athlete.exercise e on e.id = v.exercise_id;

insert into athlete.training_plan (id, owner_tenant_id, name_key, name, description, is_template, locale, i18n)
values ('f89774bb-eada-53ce-bfbe-a2d7e3c3e195', null, 'passing-decision-making', 'Passing & decision making', 'Pass types, spacing and reading the defence.', true, 'en',
  '{"es": {"name": "Pase y toma de decisiones", "description": "Tipos de pase, espaciado y lectura de la defensa."}, "id": {"name": "Operan & pengambilan keputusan", "description": "Jenis operan, jarak antarpemain dan membaca pertahanan."}}')
on conflict (id) do update set name_key = excluded.name_key, name = excluded.name,
  description = excluded.description, is_template = true, locale = excluded.locale, i18n = excluded.i18n,
  owner_tenant_id = null, updated_at = now();
delete from athlete.plan_item where plan_id = 'f89774bb-eada-53ce-bfbe-a2d7e3c3e195';
insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, description, duration_min, i18n,
  exercise_id)
select v.id, 'f89774bb-eada-53ce-bfbe-a2d7e3c3e195', null, v.position, e.title, e.description, v.duration_min, e.i18n, e.id
  from (values
    ('6ddfdd25-01fe-5ab4-92cf-0079bd60d32f'::uuid, 0, 5, 'fa82f007-c3a2-5098-8e92-821cec254f64'::uuid),  -- Chest and bounce pass pairs
    ('d372e215-5f7a-5f8e-a408-05b620558913'::uuid, 1, 6, '3eec3a0c-d9e7-5448-9ebf-75e57d897064'::uuid),  -- Overhead and outlet pass
    ('cca630ad-1e59-58c3-b06d-97505dbef4ab'::uuid, 2, 8, '2487e956-cac2-57b0-a7a4-238fb71a386a'::uuid),  -- Three-man weave
    ('a9aa6841-9acc-5f52-957f-7eba391b3feb'::uuid, 3, 6, '5ee21f9b-425a-58ee-b5eb-7229f9219215'::uuid),  -- Pass fake and pivot
    ('d44b8542-0835-5463-a1fe-0e04600ac897'::uuid, 4, 10, 'ee4157d8-fc82-502f-bde9-a43746469a97'::uuid),  -- 4v3 advantage decisions
    ('5e6c68cc-0bbf-5bc1-9e47-df165f7cdb5d'::uuid, 5, 12, '49df442d-1fda-5fc0-a5aa-4e434450e058'::uuid)  -- Small-sided game 3v3
  ) v(id, position, duration_min, exercise_id)
  join athlete.exercise e on e.id = v.exercise_id;

insert into athlete.training_plan (id, owner_tenant_id, name_key, name, description, is_template, locale, i18n)
values ('19140123-d5d8-579b-999d-002c3c4eabc1', null, 'rebounding-box-out', 'Rebounding & box-out', 'Finding the body, boxing out and securing the ball.', true, 'en',
  '{"es": {"name": "Rebote y bloqueo", "description": "Buscar el cuerpo, bloquear el rebote y asegurar el balón."}, "id": {"name": "Rebound & box-out", "description": "Mencari badan lawan, melakukan box-out dan mengamankan bola."}}')
on conflict (id) do update set name_key = excluded.name_key, name = excluded.name,
  description = excluded.description, is_template = true, locale = excluded.locale, i18n = excluded.i18n,
  owner_tenant_id = null, updated_at = now();
delete from athlete.plan_item where plan_id = '19140123-d5d8-579b-999d-002c3c4eabc1';
insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, description, duration_min, i18n,
  exercise_id)
select v.id, '19140123-d5d8-579b-999d-002c3c4eabc1', null, v.position, e.title, e.description, v.duration_min, e.i18n, e.id
  from (values
    ('2e681409-7528-530a-ad52-03ab0cc457cb'::uuid, 0, 4, '6e0f249b-7770-5707-949d-84fb424731a3'::uuid),  -- Box-out footwork
    ('0dcc3be5-20b5-56ca-9cd6-99fb2158288f'::uuid, 1, 5, 'a24c30ef-9ae5-520e-a8a2-032538005c7e'::uuid),  -- Box-out with contact
    ('db2bcbdb-93b9-51b6-9f47-a0b67d9d335b'::uuid, 2, 5, '5e1a57a5-ef7a-5a51-8867-968e16547ba6'::uuid),  -- Tip drill
    ('6518d692-2f56-562d-a809-9d6a6be9fccb'::uuid, 3, 5, '13100a6d-5669-5bbe-a3a7-ad0ea5c15578'::uuid),  -- Chin the ball
    ('2ec6e412-69c8-5cee-8669-cdb6583d4fc4'::uuid, 4, 10, '637b52cb-eb00-5417-b95d-ce55a58bfc52'::uuid),  -- Rebounding 2v2
    ('88de9a2e-53dc-596b-9e2e-599bac67adf2'::uuid, 5, 8, 'b1f118fd-a2d6-5da8-a751-d5cda61ceef3'::uuid)  -- Competitive rebounding game
  ) v(id, position, duration_min, exercise_id)
  join athlete.exercise e on e.id = v.exercise_id;

insert into athlete.training_plan (id, owner_tenant_id, name_key, name, description, is_template, locale, i18n)
values ('bb3471e5-78dc-59a8-b593-b578722f4b31', null, 'cool-down-stretching', 'Cool-down & stretching', 'Lower heart rate and stretch the main muscle groups.', true, 'en',
  '{"es": {"name": "Vuelta a la calma y estiramientos", "description": "Baja el pulso y estira los principales grupos musculares."}, "id": {"name": "Pendinginan & peregangan", "description": "Turunkan denyut jantung dan regangkan kelompok otot utama."}}')
on conflict (id) do update set name_key = excluded.name_key, name = excluded.name,
  description = excluded.description, is_template = true, locale = excluded.locale, i18n = excluded.i18n,
  owner_tenant_id = null, updated_at = now();
delete from athlete.plan_item where plan_id = 'bb3471e5-78dc-59a8-b593-b578722f4b31';
insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, description, duration_min, i18n,
  exercise_id)
select v.id, 'bb3471e5-78dc-59a8-b593-b578722f4b31', null, v.position, e.title, e.description, v.duration_min, e.i18n, e.id
  from (values
    ('f5dfefc4-ad28-531f-95b9-69ddd0e12234'::uuid, 0, 3, '35a29e40-a5fb-5ecd-ac09-5fe8363a5dd6'::uuid),  -- Easy walk and breathing
    ('4035fcea-17ab-5c70-9c24-8796938acbbb'::uuid, 1, 4, '908b7ff7-e6b9-5269-8413-5b14daeebb17'::uuid),  -- Calf and hamstring stretch
    ('ad032209-9af1-5b51-bf38-e7f9aa53878d'::uuid, 2, 4, 'cb4d149d-6c7c-59f2-8a04-2fec17e25cd3'::uuid),  -- Quad and hip flexor stretch
    ('a43d0c7b-32a6-59b7-9faf-41c4f344a0e7'::uuid, 3, 4, '4e093dd8-c5e5-5b01-9157-67fe527ac334'::uuid),  -- Groin and glute stretch
    ('105a97b3-f90a-5676-a335-1003528e1bea'::uuid, 4, 3, '37560ae4-1bf2-5eeb-984d-9ed6a6789a32'::uuid),  -- Shoulder and triceps stretch
    ('c8284862-9120-5bb7-abb6-49050f4bcb64'::uuid, 5, 3, '23fabe3e-c505-5672-a447-3bc58b61e99a'::uuid)  -- Team reflection
  ) v(id, position, duration_min, exercise_id)
  join athlete.exercise e on e.id = v.exercise_id;

alter table athlete.training_plan force row level security;
alter table athlete.plan_item force row level security;
alter table athlete.exercise force row level security;
