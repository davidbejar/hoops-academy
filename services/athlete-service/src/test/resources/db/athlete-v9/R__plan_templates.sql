-- TEST FIXTURE: R__plan_templates.sql as it was at V9 (before WP92 / V10), for ExerciseCatalogueMigrationTest, which
-- migrates a database of that time with tenant data and then to the current migrations. Never edit; never on the
-- service classpath location db/migration.
-- Global training plan templates (WP9). Repeatable: Flyway re-runs this file when its checksum changes.
-- Idempotent upserts keyed by stable UUIDs (uuid5); item ids derive from plan id + position.
-- Texts are seeded in English (locale 'en', the name / title / description columns) with Spanish and Indonesian in
-- i18n (V4, decision 43); the service shows them in the caller's language and a copy keeps the language it was made
-- in. name_key is a stable key per template. Tenants cannot change templates (RLS), they copy them.
--
-- The app and migrator roles are subject to FORCEd row level security; templates (owner_tenant_id null) can only
-- be written with the table owner exempted, so FORCE is lifted for the duration of this transaction (DDL is
-- transactional: a failure leaves FORCE in place) and restored before it commits.
alter table athlete.training_plan no force row level security;
alter table athlete.plan_item no force row level security;

insert into athlete.training_plan (id, owner_tenant_id, name_key, name, description, is_template, locale, i18n)
values ('55a86283-88a0-5ae9-9be6-97c0ed421c07', null, 'warm-up-mobility', 'Warm-up & mobility', 'Dynamic warm-up that raises heart rate and prepares joints before any session.', true, 'en',
  '{"es": {"name": "Calentamiento y movilidad", "description": "Calentamiento dinámico que eleva el pulso y prepara las articulaciones antes de cualquier sesión."}, "id": {"name": "Pemanasan & mobilitas", "description": "Pemanasan dinamis untuk menaikkan denyut jantung dan menyiapkan sendi sebelum setiap sesi."}}')
on conflict (id) do update set name_key = excluded.name_key, name = excluded.name,
  description = excluded.description, is_template = true, locale = excluded.locale, i18n = excluded.i18n,
  owner_tenant_id = null, updated_at = now();
delete from athlete.plan_item where plan_id = '55a86283-88a0-5ae9-9be6-97c0ed421c07';
insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, description, duration_min, i18n) values
  ('e3d5a421-2fa1-5002-83c7-f04618af9da2', '55a86283-88a0-5ae9-9be6-97c0ed421c07', null, 0, 'Easy jog and skips', 'Two laps of the court: jog, high knees, butt kicks, side shuffles.', 5,
   '{"es": {"title": "Trote suave y skipping", "description": "Dos vueltas a la cancha: trote, rodillas arriba, talones al glúteo, desplazamientos laterales."}, "id": {"title": "Jogging ringan dan skipping", "description": "Dua putaran lapangan: jogging, angkat lutut tinggi, tendang bokong, geser ke samping."}}'),
  ('27b35cc0-3142-58e2-94ce-20b53473c297', '55a86283-88a0-5ae9-9be6-97c0ed421c07', null, 1, 'Dynamic leg swings', 'Front/back and side leg swings, 10 per leg.', 3,
   '{"es": {"title": "Balanceos dinámicos de piernas", "description": "Balanceos adelante/atrás y laterales, 10 por pierna."}, "id": {"title": "Ayunan kaki dinamis", "description": "Ayunan kaki depan/belakang dan samping, 10 kali per kaki."}}'),
  ('9bc19056-823f-554c-b4b9-5b7014cfa782', '55a86283-88a0-5ae9-9be6-97c0ed421c07', null, 2, 'Hip and ankle mobility', 'Hip circles, ankle rolls and deep lunges with rotation.', 4,
   '{"es": {"title": "Movilidad de cadera y tobillo", "description": "Círculos de cadera, giros de tobillo y zancadas profundas con rotación."}, "id": {"title": "Mobilitas pinggul dan pergelangan kaki", "description": "Putaran pinggul, putaran pergelangan kaki dan lunge dalam dengan rotasi."}}'),
  ('5d29e87d-835c-58b9-806f-df064186fd1a', '55a86283-88a0-5ae9-9be6-97c0ed421c07', null, 3, 'Arm circles and shoulder openers', 'Small to large circles, band-free shoulder dislocates with a towel.', 3,
   '{"es": {"title": "Círculos de brazos y apertura de hombros", "description": "Círculos de pequeños a grandes; dislocaciones de hombro con una toalla, sin banda."}, "id": {"title": "Putaran lengan dan pembuka bahu", "description": "Putaran kecil hingga besar; dislokasi bahu dengan handuk, tanpa band."}}'),
  ('a78050ba-a429-58a6-9f98-c7a55619a0e3', '55a86283-88a0-5ae9-9be6-97c0ed421c07', null, 4, 'Defensive slide and backpedal lines', 'Slide baseline to baseline, backpedal, sprint.', 5,
   '{"es": {"title": "Desplazamiento defensivo y carrera hacia atrás", "description": "Desplazamiento de fondo a fondo, carrera hacia atrás, sprint."}, "id": {"title": "Geser bertahan dan lari mundur", "description": "Geser dari garis akhir ke garis akhir, lari mundur, sprint."}}'),
  ('5a7ba5ff-f5fa-5cff-aa5b-07b4689449c4', '55a86283-88a0-5ae9-9be6-97c0ed421c07', null, 5, 'Progressive jumps', 'Squat jumps and tuck jumps, building intensity.', 3,
   '{"es": {"title": "Saltos progresivos", "description": "Sentadillas con salto y saltos con rodillas al pecho, aumentando la intensidad."}, "id": {"title": "Lompatan progresif", "description": "Squat jump dan tuck jump, intensitas naik bertahap."}}');

insert into athlete.training_plan (id, owner_tenant_id, name_key, name, description, is_template, locale, i18n)
values ('1eea7dee-240e-582c-873d-be1b8f6cb283', null, 'ball-handling-basics', 'Ball handling basics', 'Fundamental dribbling skills with both hands, stationary and moving.', true, 'en',
  '{"es": {"name": "Fundamentos de manejo de balón", "description": "Habilidades básicas de bote con ambas manos, en estático y en movimiento."}, "id": {"name": "Dasar-dasar menggiring bola", "description": "Keterampilan dasar dribel dengan kedua tangan, di tempat dan sambil bergerak."}}')
on conflict (id) do update set name_key = excluded.name_key, name = excluded.name,
  description = excluded.description, is_template = true, locale = excluded.locale, i18n = excluded.i18n,
  owner_tenant_id = null, updated_at = now();
delete from athlete.plan_item where plan_id = '1eea7dee-240e-582c-873d-be1b8f6cb283';
insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, description, duration_min, i18n) values
  ('3e9c60d9-f42a-5444-82be-fb7f86f1bd51', '1eea7dee-240e-582c-873d-be1b8f6cb283', null, 0, 'Stationary pound dribble', 'Low and high pound dribble, 30 seconds each hand.', 4,
   '{"es": {"title": "Bote fuerte en estático", "description": "Bote fuerte bajo y alto, 30 segundos con cada mano."}, "id": {"title": "Dribel keras di tempat", "description": "Dribel keras rendah dan tinggi, 30 detik tiap tangan."}}'),
  ('69b76d93-e2bc-58ec-bdf8-141cfa2f3dea', '1eea7dee-240e-582c-873d-be1b8f6cb283', null, 1, 'Figure-eight and around-the-leg', 'Control the ball through and around the legs.', 5,
   '{"es": {"title": "Ocho y alrededor de la pierna", "description": "Controla el balón entre y alrededor de las piernas."}, "id": {"title": "Angka delapan dan memutari kaki", "description": "Kuasai bola di antara dan memutari kaki."}}'),
  ('dc7744c6-4117-5f18-bd55-5779c61c3494', '1eea7dee-240e-582c-873d-be1b8f6cb283', null, 2, 'Two-ball dribbling', 'Alternate and simultaneous dribbles, eyes up.', 5,
   '{"es": {"title": "Bote con dos balones", "description": "Botes alternos y simultáneos, con la vista arriba."}, "id": {"title": "Dribel dua bola", "description": "Dribel bergantian dan bersamaan, pandangan ke depan."}}'),
  ('0164391e-fdf0-506d-9776-80a553b519ae', '1eea7dee-240e-582c-873d-be1b8f6cb283', null, 3, 'Crossover and between-the-legs', 'Walk the line, then at speed.', 8,
   '{"es": {"title": "Cambio de mano y entre las piernas", "description": "Recorre la línea caminando y luego a velocidad."}, "id": {"title": "Crossover dan di antara kaki", "description": "Susuri garis sambil berjalan, lalu dengan cepat."}}'),
  ('9fd42bbc-2429-53e9-9bcb-2099ac1ab552', '1eea7dee-240e-582c-873d-be1b8f6cb283', null, 4, 'Change of pace dribble', 'Slow, fast, slow along the court.', 6,
   '{"es": {"title": "Bote con cambio de ritmo", "description": "Lento, rápido, lento a lo largo de la cancha."}, "id": {"title": "Dribel ganti tempo", "description": "Pelan, cepat, pelan sepanjang lapangan."}}'),
  ('a31ba770-740e-56a4-ac85-5a0f67ab5656', '1eea7dee-240e-582c-873d-be1b8f6cb283', null, 5, 'Dribble with a defender cue', 'Partner points; react with a crossover or retreat dribble.', 7,
   '{"es": {"title": "Bote con señal del defensor", "description": "El compañero señala; reacciona con un cambio de mano o un bote de retroceso."}, "id": {"title": "Dribel dengan isyarat bertahan", "description": "Rekan menunjuk; bereaksi dengan crossover atau dribel mundur."}}');

insert into athlete.training_plan (id, owner_tenant_id, name_key, name, description, is_template, locale, i18n)
values ('51da6d79-c6d1-5e6e-80dd-405d599f4090', null, 'form-shooting', 'Form shooting', 'Mechanics first: close-range shooting with perfect form before range is added.', true, 'en',
  '{"es": {"name": "Técnica de tiro", "description": "Primero la mecánica: tiro cercano con técnica perfecta antes de ganar distancia."}, "id": {"name": "Teknik menembak", "description": "Mekanika dulu: tembakan jarak dekat dengan teknik sempurna sebelum menambah jarak."}}')
on conflict (id) do update set name_key = excluded.name_key, name = excluded.name,
  description = excluded.description, is_template = true, locale = excluded.locale, i18n = excluded.i18n,
  owner_tenant_id = null, updated_at = now();
delete from athlete.plan_item where plan_id = '51da6d79-c6d1-5e6e-80dd-405d599f4090';
insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, description, duration_min, i18n) values
  ('d987225b-dc7f-5177-ab50-963dd1c48d0f', '51da6d79-c6d1-5e6e-80dd-405d599f4090', null, 0, 'One-hand form shots', 'Shooting hand only, 1 metre from the rim, 15 makes.', 5,
   '{"es": {"title": "Tiros a una mano", "description": "Solo la mano de tiro, a 1 metro del aro, 15 aciertos."}, "id": {"title": "Tembakan satu tangan", "description": "Hanya tangan penembak, 1 meter dari ring, 15 masuk."}}'),
  ('22c8ef40-4d95-5e45-8eec-f2aaa4777b70', '51da6d79-c6d1-5e6e-80dd-405d599f4090', null, 1, 'Both hands form shots', 'Add the guide hand, 15 makes.', 5,
   '{"es": {"title": "Tiros con las dos manos", "description": "Añade la mano guía, 15 aciertos."}, "id": {"title": "Tembakan dua tangan", "description": "Tambahkan tangan penyeimbang, 15 masuk."}}'),
  ('7907e105-582d-5280-800e-60249c8234f8', '51da6d79-c6d1-5e6e-80dd-405d599f4090', null, 2, 'Step-back from three spots', 'Short distance, left, centre, right, 10 each.', 8,
   '{"es": {"title": "Paso atrás desde tres puntos", "description": "Distancia corta, izquierda, centro, derecha, 10 en cada uno."}, "id": {"title": "Mundur dari tiga titik", "description": "Jarak pendek, kiri, tengah, kanan, masing-masing 10."}}'),
  ('fab587b0-510a-5c33-86dd-fdc556d3179f', '51da6d79-c6d1-5e6e-80dd-405d599f4090', null, 3, 'Catch-and-shoot', 'Partner passes, feet ready, 20 shots.', 8,
   '{"es": {"title": "Recibir y tirar", "description": "El compañero pasa, pies preparados, 20 tiros."}, "id": {"title": "Tangkap dan tembak", "description": "Rekan mengoper, kaki siap, 20 tembakan."}}'),
  ('33a32db3-8139-5548-801f-ff4ae3a22e33', '51da6d79-c6d1-5e6e-80dd-405d599f4090', null, 4, 'Free-throw line shots', 'Straight-on form from the line, 20 shots.', 6,
   '{"es": {"title": "Tiros desde la línea de tiros libres", "description": "Técnica de frente desde la línea, 20 tiros."}, "id": {"title": "Tembakan dari garis lemparan bebas", "description": "Teknik lurus dari garis, 20 tembakan."}}'),
  ('8b0addf1-0377-5ff1-ba71-312ca9a1b655', '51da6d79-c6d1-5e6e-80dd-405d599f4090', null, 5, 'Game-speed mid-range', 'Move off a cone, shoot, rebound, repeat.', 8,
   '{"es": {"title": "Media distancia a ritmo de partido", "description": "Sal desde un cono, tira, rebotea y repite."}, "id": {"title": "Jarak menengah dengan kecepatan pertandingan", "description": "Bergerak dari kerucut, tembak, rebound, ulangi."}}');

insert into athlete.training_plan (id, owner_tenant_id, name_key, name, description, is_template, locale, i18n)
values ('e06333ee-a8d9-5017-a476-751f9a99b45c', null, 'free-throw-routine', 'Free-throw routine', 'Build a repeatable pre-shot routine and shoot under light fatigue.', true, 'en',
  '{"es": {"name": "Rutina de tiros libres", "description": "Construye una rutina previa al tiro repetible y tira con fatiga ligera."}, "id": {"name": "Rutinitas lemparan bebas", "description": "Bangun rutinitas sebelum menembak yang konsisten dan menembak dalam kondisi sedikit lelah."}}')
on conflict (id) do update set name_key = excluded.name_key, name = excluded.name,
  description = excluded.description, is_template = true, locale = excluded.locale, i18n = excluded.i18n,
  owner_tenant_id = null, updated_at = now();
delete from athlete.plan_item where plan_id = 'e06333ee-a8d9-5017-a476-751f9a99b45c';
insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, description, duration_min, i18n) values
  ('8954d035-c9ef-5b88-b4be-a7366cbd6f31', 'e06333ee-a8d9-5017-a476-751f9a99b45c', null, 0, 'Breathing and routine rehearsal', 'Dribble count, breath, visualise, no ball release.', 3,
   '{"es": {"title": "Respiración y ensayo de la rutina", "description": "Cuenta de botes, respiración, visualización, sin soltar el balón."}, "id": {"title": "Latihan napas dan rutinitas", "description": "Hitungan dribel, napas, visualisasi, tanpa melepas bola."}}'),
  ('540d36e9-aa01-599b-913d-8614edfdc77c', 'e06333ee-a8d9-5017-a476-751f9a99b45c', null, 1, 'Ten free throws', 'Shoot ten with the full routine, record makes.', 6,
   '{"es": {"title": "Diez tiros libres", "description": "Lanza diez con la rutina completa y anota los aciertos."}, "id": {"title": "Sepuluh lemparan bebas", "description": "Lempar sepuluh kali dengan rutinitas lengkap, catat yang masuk."}}'),
  ('5f6b176c-51a6-516a-b33f-1fcf254ddd98', 'e06333ee-a8d9-5017-a476-751f9a99b45c', null, 2, 'Make two in a row', 'Two consecutive makes before moving on, five rounds.', 8,
   '{"es": {"title": "Dos aciertos seguidos", "description": "Dos aciertos consecutivos antes de avanzar, cinco rondas."}, "id": {"title": "Dua masuk berturut-turut", "description": "Dua masuk berturut-turut sebelum lanjut, lima ronde."}}'),
  ('dd0c04e2-e374-5223-80f5-4a71e25b9f72', 'e06333ee-a8d9-5017-a476-751f9a99b45c', null, 3, 'Fatigue free throws', 'Sprint baseline to baseline, then two free throws, x6.', 10,
   '{"es": {"title": "Tiros libres con fatiga", "description": "Sprint de fondo a fondo y luego dos tiros libres, x6."}, "id": {"title": "Lemparan bebas saat lelah", "description": "Sprint dari garis akhir ke garis akhir, lalu dua lemparan bebas, x6."}}'),
  ('4b7367a3-269d-5fae-a026-fe21ceea1832', 'e06333ee-a8d9-5017-a476-751f9a99b45c', null, 4, 'Pressure finish', 'Partner counts score; first to 8 makes out of 10 wins.', 6,
   '{"es": {"title": "Final bajo presión", "description": "El compañero lleva la cuenta; gana el primero en lograr 8 de 10."}, "id": {"title": "Penutup di bawah tekanan", "description": "Rekan menghitung skor; yang pertama memasukkan 8 dari 10 menang."}}');

insert into athlete.training_plan (id, owner_tenant_id, name_key, name, description, is_template, locale, i18n)
values ('7bdee8e3-0ee8-5f9e-ad50-b24203a86937', null, 'finishing-at-the-rim', 'Finishing at the rim', 'Layups, floaters and contact finishes with both hands.', true, 'en',
  '{"es": {"name": "Finalización junto al aro", "description": "Bandejas, bombas y finalizaciones con contacto con ambas manos."}, "id": {"name": "Penyelesaian di dekat ring", "description": "Layup, floater dan penyelesaian dengan kontak menggunakan kedua tangan."}}')
on conflict (id) do update set name_key = excluded.name_key, name = excluded.name,
  description = excluded.description, is_template = true, locale = excluded.locale, i18n = excluded.i18n,
  owner_tenant_id = null, updated_at = now();
delete from athlete.plan_item where plan_id = '7bdee8e3-0ee8-5f9e-ad50-b24203a86937';
insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, description, duration_min, i18n) values
  ('35cefaab-c696-555c-8901-6166bef26d62', '7bdee8e3-0ee8-5f9e-ad50-b24203a86937', null, 0, 'Right and left layup lines', 'Two-step layup, soft touch off the glass.', 6,
   '{"es": {"title": "Filas de bandeja por derecha e izquierda", "description": "Bandeja en dos tiempos, toque suave al tablero."}, "id": {"title": "Barisan layup kanan dan kiri", "description": "Layup dua langkah, sentuhan lembut ke papan."}}'),
  ('e1b54b52-0ede-58af-ac34-c3c7e6a38cfe', '7bdee8e3-0ee8-5f9e-ad50-b24203a86937', null, 1, 'Reverse layup', 'Finish on the far side of the rim.', 6,
   '{"es": {"title": "Bandeja a aro pasado", "description": "Finaliza por el lado contrario del aro."}, "id": {"title": "Reverse layup", "description": "Selesaikan di sisi jauh ring."}}'),
  ('dac9351e-bbb0-51e9-8e02-1a1f83be52a4', '7bdee8e3-0ee8-5f9e-ad50-b24203a86937', null, 2, 'Euro step', 'Attack, step through, finish.', 6,
   '{"es": {"title": "Paso europeo", "description": "Ataca, cambia de paso y finaliza."}, "id": {"title": "Euro step", "description": "Serang, langkah menyilang, selesaikan."}}'),
  ('274b2695-a9ac-57fc-801f-80e3cc800bb6', '7bdee8e3-0ee8-5f9e-ad50-b24203a86937', null, 3, 'Floater', 'Short high-arc shot over a cone defender.', 6,
   '{"es": {"title": "Bomba", "description": "Tiro corto de parábola alta por encima de un cono defensor."}, "id": {"title": "Floater", "description": "Tembakan pendek melambung tinggi melewati kerucut bertahan."}}'),
  ('bb506620-23c9-50e1-84a1-bd3a70eb2357', '7bdee8e3-0ee8-5f9e-ad50-b24203a86937', null, 4, 'Contact finishes', 'Finish through a pad, ball high.', 7,
   '{"es": {"title": "Finalizaciones con contacto", "description": "Finaliza contra un escudo, balón arriba."}, "id": {"title": "Penyelesaian dengan kontak", "description": "Selesaikan melawan bantalan, bola tetap tinggi."}}'),
  ('c956242b-2808-5ca3-a562-e9a36d94b3f7', '7bdee8e3-0ee8-5f9e-ad50-b24203a86937', null, 5, 'Game-speed transition finishes', 'Full-court dribble to layup, x8.', 8,
   '{"es": {"title": "Finalizaciones en transición a ritmo de partido", "description": "Bote a campo completo hasta la bandeja, x8."}, "id": {"title": "Penyelesaian transisi kecepatan pertandingan", "description": "Dribel sepanjang lapangan hingga layup, x8."}}');

insert into athlete.training_plan (id, owner_tenant_id, name_key, name, description, is_template, locale, i18n)
values ('5828cd70-c51f-5eb7-aa8b-9193f2d31d3e', null, 'defensive-footwork', 'Defensive footwork', 'Stance, slides and closeouts that keep a defender in front of the ball.', true, 'en',
  '{"es": {"name": "Trabajo de pies defensivo", "description": "Posición, desplazamientos y cierres que mantienen al defensor delante del balón."}, "id": {"name": "Gerak kaki bertahan", "description": "Kuda-kuda, geser dan closeout agar pemain bertahan tetap di depan bola."}}')
on conflict (id) do update set name_key = excluded.name_key, name = excluded.name,
  description = excluded.description, is_template = true, locale = excluded.locale, i18n = excluded.i18n,
  owner_tenant_id = null, updated_at = now();
delete from athlete.plan_item where plan_id = '5828cd70-c51f-5eb7-aa8b-9193f2d31d3e';
insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, description, duration_min, i18n) values
  ('b03ced21-c3c5-51cd-97f4-fe670916a7e8', '5828cd70-c51f-5eb7-aa8b-9193f2d31d3e', null, 0, 'Stance and slide', 'Low stance, hands active, slide across the key, x6.', 5,
   '{"es": {"title": "Posición y desplazamiento", "description": "Posición baja, manos activas, desplazamiento a lo ancho de la zona, x6."}, "id": {"title": "Kuda-kuda dan geser", "description": "Kuda-kuda rendah, tangan aktif, geser melintasi area kunci, x6."}}'),
  ('17295378-f854-5ab7-b5fd-c75ae5a6c6fc', '5828cd70-c51f-5eb7-aa8b-9193f2d31d3e', null, 1, 'Drop-step and recover', 'Open the hips, recover to stance.', 5,
   '{"es": {"title": "Paso de caída y recuperación", "description": "Abre la cadera y recupera la posición."}, "id": {"title": "Drop-step dan pulih", "description": "Buka pinggul, kembali ke kuda-kuda."}}'),
  ('5a4d493b-3601-55a6-8aaa-cbce6ca23aeb', '5828cd70-c51f-5eb7-aa8b-9193f2d31d3e', null, 2, 'Closeout drill', 'Sprint, chop steps, hand up, x8.', 6,
   '{"es": {"title": "Ejercicio de cierre", "description": "Sprint, pasos cortos, mano arriba, x8."}, "id": {"title": "Latihan closeout", "description": "Sprint, langkah pendek cepat, tangan ke atas, x8."}}'),
  ('792ec5e1-6ebc-5fbb-9fbd-dbf2efb9732e', '5828cd70-c51f-5eb7-aa8b-9193f2d31d3e', null, 3, 'Mirror drill', 'Partner leads, defender mirrors with slides.', 6,
   '{"es": {"title": "Ejercicio del espejo", "description": "El compañero guía, el defensor lo imita con desplazamientos."}, "id": {"title": "Latihan cermin", "description": "Rekan memimpin, pemain bertahan menirukan dengan geser."}}'),
  ('0416b853-f774-50f5-88b1-4f776804cebd', '5828cd70-c51f-5eb7-aa8b-9193f2d31d3e', null, 4, 'Shell drill (4v4)', 'Positioning on ball movement, jump to the pass.', 12,
   '{"es": {"title": "Defensa en caja (4c4)", "description": "Colocación según el movimiento del balón, salta al pase."}, "id": {"title": "Latihan shell (4v4)", "description": "Posisi mengikuti pergerakan bola, lompat ke arah operan."}}'),
  ('91f175fc-433d-5544-8f26-1d06406ca78f', '5828cd70-c51f-5eb7-aa8b-9193f2d31d3e', null, 5, 'Charge-taking', 'Set feet and absorb contact with a pad.', 5,
   '{"es": {"title": "Recibir falta en ataque", "description": "Planta los pies y absorbe el contacto con un escudo."}, "id": {"title": "Menerima charge", "description": "Pasang kaki dan serap kontak dengan bantalan."}}');

insert into athlete.training_plan (id, owner_tenant_id, name_key, name, description, is_template, locale, i18n)
values ('04e7d5f6-d05a-5794-a53e-aac6bf3ce48f', null, 'conditioning-intervals', 'Conditioning (intervals)', 'Court-based interval conditioning; stop early on pain or dizziness.', true, 'en',
  '{"es": {"name": "Acondicionamiento (intervalos)", "description": "Acondicionamiento por intervalos en la cancha; para antes si hay dolor o mareo."}, "id": {"name": "Kondisi fisik (interval)", "description": "Latihan kondisi interval di lapangan; berhenti lebih awal jika nyeri atau pusing."}}')
on conflict (id) do update set name_key = excluded.name_key, name = excluded.name,
  description = excluded.description, is_template = true, locale = excluded.locale, i18n = excluded.i18n,
  owner_tenant_id = null, updated_at = now();
delete from athlete.plan_item where plan_id = '04e7d5f6-d05a-5794-a53e-aac6bf3ce48f';
insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, description, duration_min, i18n) values
  ('ca8ad256-6b93-5d0e-9d4d-c1758577fc41', '04e7d5f6-d05a-5794-a53e-aac6bf3ce48f', null, 0, 'Easy warm-up jog', 'Three minutes easy.', 3,
   '{"es": {"title": "Trote suave de calentamiento", "description": "Tres minutos suaves."}, "id": {"title": "Jogging pemanasan ringan", "description": "Tiga menit santai."}}'),
  ('f0ac5cd5-1a04-512c-9163-21a6278fbfe2', '04e7d5f6-d05a-5794-a53e-aac6bf3ce48f', null, 1, 'Suicides', 'Four lines to half court; 30 s work, 60 s rest, x4.', 8,
   '{"es": {"title": "Suicidios", "description": "Cuatro líneas hasta medio campo; 30 s de trabajo, 60 s de descanso, x4."}, "id": {"title": "Suicide run", "description": "Empat garis hingga tengah lapangan; 30 dtk kerja, 60 dtk istirahat, x4."}}'),
  ('d1e55c14-5874-5698-b1e1-e09dce5955a0', '04e7d5f6-d05a-5794-a53e-aac6bf3ce48f', null, 2, 'Line sprints', 'Baseline to baseline, 20 s work, 40 s rest, x6.', 6,
   '{"es": {"title": "Sprints de línea", "description": "De fondo a fondo, 20 s de trabajo, 40 s de descanso, x6."}, "id": {"title": "Sprint garis", "description": "Garis akhir ke garis akhir, 20 dtk kerja, 40 dtk istirahat, x6."}}'),
  ('a7158a06-00f1-503d-9433-7269868763fc', '04e7d5f6-d05a-5794-a53e-aac6bf3ce48f', null, 3, 'Defensive slide intervals', 'Free-throw lane slides, 30 s work, 30 s rest, x6.', 6,
   '{"es": {"title": "Intervalos de desplazamiento defensivo", "description": "Desplazamientos en la zona de tiros libres, 30 s de trabajo, 30 s de descanso, x6."}, "id": {"title": "Interval geser bertahan", "description": "Geser di area lemparan bebas, 30 dtk kerja, 30 dtk istirahat, x6."}}'),
  ('c4bf2cd8-4ed5-5f36-8e82-971c6af58dda', '04e7d5f6-d05a-5794-a53e-aac6bf3ce48f', null, 4, 'Full-court layup relay', 'Two teams, race with a layup at each end.', 8,
   '{"es": {"title": "Relevos de bandeja a campo completo", "description": "Dos equipos, carrera con una bandeja en cada canasta."}, "id": {"title": "Estafet layup lapangan penuh", "description": "Dua tim, berlomba dengan layup di setiap ujung."}}'),
  ('c8e8410f-dc5f-5357-9824-19b9eb8272a0', '04e7d5f6-d05a-5794-a53e-aac6bf3ce48f', null, 5, 'Walk and shake out', 'Walk it down and sip water.', 4,
   '{"es": {"title": "Caminar y soltar", "description": "Camina para bajar pulsaciones y bebe agua a sorbos."}, "id": {"title": "Jalan dan lemaskan", "description": "Berjalan santai dan minum air sedikit-sedikit."}}');

insert into athlete.training_plan (id, owner_tenant_id, name_key, name, description, is_template, locale, i18n)
values ('f89774bb-eada-53ce-bfbe-a2d7e3c3e195', null, 'passing-decision-making', 'Passing & decision making', 'Pass types, spacing and reading the defence.', true, 'en',
  '{"es": {"name": "Pase y toma de decisiones", "description": "Tipos de pase, espaciado y lectura de la defensa."}, "id": {"name": "Operan & pengambilan keputusan", "description": "Jenis operan, jarak antarpemain dan membaca pertahanan."}}')
on conflict (id) do update set name_key = excluded.name_key, name = excluded.name,
  description = excluded.description, is_template = true, locale = excluded.locale, i18n = excluded.i18n,
  owner_tenant_id = null, updated_at = now();
delete from athlete.plan_item where plan_id = 'f89774bb-eada-53ce-bfbe-a2d7e3c3e195';
insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, description, duration_min, i18n) values
  ('6ddfdd25-01fe-5ab4-92cf-0079bd60d32f', 'f89774bb-eada-53ce-bfbe-a2d7e3c3e195', null, 0, 'Chest and bounce pass pairs', 'Stationary then moving, 2 minutes each.', 5,
   '{"es": {"title": "Parejas de pase de pecho y picado", "description": "Primero en estático y luego en movimiento, 2 minutos cada uno."}, "id": {"title": "Berpasangan operan dada dan pantul", "description": "Di tempat lalu bergerak, masing-masing 2 menit."}}'),
  ('d372e215-5f7a-5f8e-a408-05b620558913', 'f89774bb-eada-53ce-bfbe-a2d7e3c3e195', null, 1, 'Overhead and outlet pass', 'Rebound, outlet to the wing, fill lanes.', 6,
   '{"es": {"title": "Pase por encima de la cabeza y de salida", "description": "Rebote, pase de salida al ala, ocupar carriles."}, "id": {"title": "Operan atas kepala dan outlet", "description": "Rebound, outlet ke sayap, isi jalur."}}'),
  ('cca630ad-1e59-58c3-b06d-97505dbef4ab', 'f89774bb-eada-53ce-bfbe-a2d7e3c3e195', null, 2, 'Three-man weave', 'Pass and go behind, finish with a layup.', 8,
   '{"es": {"title": "Ocho de tres", "description": "Pasa y corta por detrás, termina con una bandeja."}, "id": {"title": "Weave tiga orang", "description": "Oper lalu lari ke belakang, akhiri dengan layup."}}'),
  ('a9aa6841-9acc-5f52-957f-7eba391b3feb', 'f89774bb-eada-53ce-bfbe-a2d7e3c3e195', null, 3, 'Pass fake and pivot', 'Pivot under pressure, make the next pass.', 6,
   '{"es": {"title": "Finta de pase y pivote", "description": "Pivota bajo presión y da el siguiente pase."}, "id": {"title": "Tipuan operan dan pivot", "description": "Pivot di bawah tekanan, lakukan operan berikutnya."}}'),
  ('d44b8542-0835-5463-a1fe-0e04600ac897', 'f89774bb-eada-53ce-bfbe-a2d7e3c3e195', null, 4, '4v3 advantage decisions', 'Attack the numbers; pass or shoot?', 10,
   '{"es": {"title": "Decisiones en ventaja 4c3", "description": "Ataca la superioridad: ¿pasar o tirar?"}, "id": {"title": "Keputusan unggul jumlah 4v3", "description": "Manfaatkan keunggulan jumlah; oper atau tembak?"}}'),
  ('5e6c68cc-0bbf-5bc1-9e47-df165f7cdb5d', 'f89774bb-eada-53ce-bfbe-a2d7e3c3e195', null, 5, 'Small-sided game 3v3', 'Four passes before a shot.', 12,
   '{"es": {"title": "Juego reducido 3c3", "description": "Cuatro pases antes de tirar."}, "id": {"title": "Permainan kecil 3v3", "description": "Empat operan sebelum menembak."}}');

insert into athlete.training_plan (id, owner_tenant_id, name_key, name, description, is_template, locale, i18n)
values ('19140123-d5d8-579b-999d-002c3c4eabc1', null, 'rebounding-box-out', 'Rebounding & box-out', 'Finding the body, boxing out and securing the ball.', true, 'en',
  '{"es": {"name": "Rebote y bloqueo", "description": "Buscar el cuerpo, bloquear el rebote y asegurar el balón."}, "id": {"name": "Rebound & box-out", "description": "Mencari badan lawan, melakukan box-out dan mengamankan bola."}}')
on conflict (id) do update set name_key = excluded.name_key, name = excluded.name,
  description = excluded.description, is_template = true, locale = excluded.locale, i18n = excluded.i18n,
  owner_tenant_id = null, updated_at = now();
delete from athlete.plan_item where plan_id = '19140123-d5d8-579b-999d-002c3c4eabc1';
insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, description, duration_min, i18n) values
  ('2e681409-7528-530a-ad52-03ab0cc457cb', '19140123-d5d8-579b-999d-002c3c4eabc1', null, 0, 'Box-out footwork', 'Pivot into the partner without contact, x10.', 4,
   '{"es": {"title": "Pies del bloqueo de rebote", "description": "Pivota hacia el compañero sin contacto, x10."}, "id": {"title": "Gerak kaki box-out", "description": "Pivot ke arah rekan tanpa kontak, x10."}}'),
  ('0dcc3be5-20b5-56ca-9cd6-99fb2158288f', '19140123-d5d8-579b-999d-002c3c4eabc1', null, 1, 'Box-out with contact', 'Hold position for three seconds.', 5,
   '{"es": {"title": "Bloqueo de rebote con contacto", "description": "Mantén la posición durante tres segundos."}, "id": {"title": "Box-out dengan kontak", "description": "Tahan posisi selama tiga detik."}}'),
  ('db2bcbdb-93b9-51b6-9f47-a0b67d9d335b', '19140123-d5d8-579b-999d-002c3c4eabc1', null, 2, 'Tip drill', 'Tip the ball off the glass until a secure catch.', 5,
   '{"es": {"title": "Ejercicio de palmeo", "description": "Palmea el balón contra el tablero hasta atraparlo con seguridad."}, "id": {"title": "Latihan tip", "description": "Tepis bola ke papan hingga tertangkap dengan aman."}}'),
  ('6518d692-2f56-562d-a809-9d6a6be9fccb', '19140123-d5d8-579b-999d-002c3c4eabc1', null, 3, 'Chin the ball', 'Two-hand rebound, chin it and outlet.', 5,
   '{"es": {"title": "Balón a la barbilla", "description": "Rebote a dos manos, balón a la barbilla y pase de salida."}, "id": {"title": "Bola ke dagu", "description": "Rebound dua tangan, bawa ke dagu lalu outlet."}}'),
  ('2ec6e412-69c8-5cee-8669-cdb6583d4fc4', '19140123-d5d8-579b-999d-002c3c4eabc1', null, 4, 'Rebounding 2v2', 'Defence boxes out; offence crashes.', 10,
   '{"es": {"title": "Rebote 2c2", "description": "La defensa bloquea; el ataque va al rebote."}, "id": {"title": "Rebound 2v2", "description": "Pertahanan box-out; penyerang menyerbu ring."}}'),
  ('88de9a2e-53dc-596b-9e2e-599bac67adf2', '19140123-d5d8-579b-999d-002c3c4eabc1', null, 5, 'Competitive rebounding game', 'First to 10 rebounds.', 8,
   '{"es": {"title": "Juego competitivo de rebote", "description": "Gana el primero en llegar a 10 rebotes."}, "id": {"title": "Permainan rebound kompetitif", "description": "Yang pertama meraih 10 rebound."}}');

insert into athlete.training_plan (id, owner_tenant_id, name_key, name, description, is_template, locale, i18n)
values ('bb3471e5-78dc-59a8-b593-b578722f4b31', null, 'cool-down-stretching', 'Cool-down & stretching', 'Lower heart rate and stretch the main muscle groups.', true, 'en',
  '{"es": {"name": "Vuelta a la calma y estiramientos", "description": "Baja el pulso y estira los principales grupos musculares."}, "id": {"name": "Pendinginan & peregangan", "description": "Turunkan denyut jantung dan regangkan kelompok otot utama."}}')
on conflict (id) do update set name_key = excluded.name_key, name = excluded.name,
  description = excluded.description, is_template = true, locale = excluded.locale, i18n = excluded.i18n,
  owner_tenant_id = null, updated_at = now();
delete from athlete.plan_item where plan_id = 'bb3471e5-78dc-59a8-b593-b578722f4b31';
insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, description, duration_min, i18n) values
  ('f5dfefc4-ad28-531f-95b9-69ddd0e12234', 'bb3471e5-78dc-59a8-b593-b578722f4b31', null, 0, 'Easy walk and breathing', 'Two laps walking, slow breathing.', 3,
   '{"es": {"title": "Paseo suave y respiración", "description": "Dos vueltas caminando, respiración lenta."}, "id": {"title": "Jalan santai dan bernapas", "description": "Dua putaran berjalan, napas pelan."}}'),
  ('4035fcea-17ab-5c70-9c24-8796938acbbb', 'bb3471e5-78dc-59a8-b593-b578722f4b31', null, 1, 'Calf and hamstring stretch', 'Hold 30 seconds each side.', 4,
   '{"es": {"title": "Estiramiento de gemelos e isquiotibiales", "description": "Mantén 30 segundos por lado."}, "id": {"title": "Peregangan betis dan hamstring", "description": "Tahan 30 detik tiap sisi."}}'),
  ('ad032209-9af1-5b51-bf38-e7f9aa53878d', 'bb3471e5-78dc-59a8-b593-b578722f4b31', null, 2, 'Quad and hip flexor stretch', 'Hold 30 seconds each side.', 4,
   '{"es": {"title": "Estiramiento de cuádriceps y flexores de cadera", "description": "Mantén 30 segundos por lado."}, "id": {"title": "Peregangan paha depan dan fleksor pinggul", "description": "Tahan 30 detik tiap sisi."}}'),
  ('a43d0c7b-32a6-59b7-9faf-41c4f344a0e7', 'bb3471e5-78dc-59a8-b593-b578722f4b31', null, 3, 'Groin and glute stretch', 'Hold 30 seconds each side.', 4,
   '{"es": {"title": "Estiramiento de aductores y glúteos", "description": "Mantén 30 segundos por lado."}, "id": {"title": "Peregangan selangkangan dan bokong", "description": "Tahan 30 detik tiap sisi."}}'),
  ('105a97b3-f90a-5676-a335-1003528e1bea', 'bb3471e5-78dc-59a8-b593-b578722f4b31', null, 4, 'Shoulder and triceps stretch', 'Hold 20 seconds each side.', 3,
   '{"es": {"title": "Estiramiento de hombros y tríceps", "description": "Mantén 20 segundos por lado."}, "id": {"title": "Peregangan bahu dan trisep", "description": "Tahan 20 detik tiap sisi."}}'),
  ('c8284862-9120-5bb7-abb6-49050f4bcb64', 'bb3471e5-78dc-59a8-b593-b578722f4b31', null, 5, 'Team reflection', 'Two things that went well, one to improve.', 3,
   '{"es": {"title": "Reflexión en equipo", "description": "Dos cosas que salieron bien y una para mejorar."}, "id": {"title": "Refleksi tim", "description": "Dua hal yang berjalan baik, satu yang perlu diperbaiki."}}');

alter table athlete.training_plan force row level security;
alter table athlete.plan_item force row level security;
