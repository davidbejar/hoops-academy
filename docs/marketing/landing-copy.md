# Landing page copy (es / en / id)

Source of truth for the public landing page (WP70). Written 2026-11-06 by the orchestrator (decision 50: the copy
is Fable's; the page is built by an agent). Every string below becomes an l10n key `landing*` in
`apps/web/lib/l10n/app_{es,en,id}.arb`; keep the three languages in step. Tone: confident, concrete, no hype words
("revolutionary", "AI-powered"), no promises the product does not keep. Numbers and claims must stay true to
`README.md` and `docs/conformance.md`.

Brand: "Hoops Academy". Colour: the app's seed `#E8590C` (basketball orange) on near-black and off-white. The page
must feel like a product site, not a dashboard: large type, generous white space, one accent colour, real
screenshots or illustrated mock-ups of the app (the demo mock can be captured), motion kept subtle.

---

## 1. Hero

**Eyebrow**
- en: Built for basketball academies only
- es: Pensado solo para academias de baloncesto
- id: Dibuat khusus untuk akademi basket

**Headline**
- en: Run your academy like a program, not a spreadsheet.
- es: Dirige tu academia como un programa, no como una hoja de cálculo.
- id: Kelola akademimu seperti sebuah program, bukan lembar kerja.

**Subheadline**
- en: Rosters, eligibility, live match stats, training attendance and player development, in one place that works
  courtside, even without signal.
- es: Plantillas, elegibilidad, estadísticas en vivo, asistencia a entrenamientos y desarrollo de jugadores, en un
  solo sitio que funciona a pie de pista, incluso sin cobertura.
- id: Roster, kelayakan, statistik pertandingan langsung, kehadiran latihan, dan perkembangan pemain, dalam satu
  tempat yang bekerja di pinggir lapangan, bahkan tanpa sinyal.

**Primary action** (opens the join form)
- en: Request an invitation
- es: Solicitar una invitación
- id: Minta undangan

**Secondary action** (goes to sign-in)
- en: Sign in
- es: Iniciar sesión
- id: Masuk

**Proof line under the actions** (small)
- en: Open source · Spanish, English and Indonesian · Works offline on any phone or laptop
- es: Código abierto · Español, inglés e indonesio · Funciona sin conexión en cualquier móvil u ordenador
- id: Sumber terbuka · Bahasa Spanyol, Inggris, dan Indonesia · Bekerja offline di ponsel atau laptop apa pun

## 2. Why basketball-only

**Title**
- en: A generic club app knows nothing about a fourth-quarter foul.
- es: Una app genérica de club no sabe lo que es una falta en el último cuarto.
- id: Aplikasi klub generik tidak tahu apa itu foul di kuarter keempat.

**Body**
- en: Hoops Academy is not a sports-club template with basketball bolted on. Age categories, play-up rules, box
  scores, five-player line-ups, fitness tests with basketball norms: the rules of the game are the rules of the
  software. You configure your academy, not the sport.
- es: Hoops Academy no es una plantilla de club deportivo con el baloncesto añadido. Categorías de edad, reglas de
  jugar en categoría superior, hojas de estadísticas, quintetos, pruebas físicas con baremos de baloncesto: las
  reglas del juego son las reglas del programa. Tú configuras tu academia, no el deporte.
- id: Hoops Academy bukan templat klub olahraga yang ditempeli basket. Kategori usia, aturan main di kategori atas,
  box score, lima pemain di lapangan, tes kebugaran dengan norma basket: aturan permainan adalah aturan
  perangkat lunaknya. Kamu mengatur akademimu, bukan olahraganya.

## 3. Features (six cards)

### 3.1 Roster and eligibility
- en title: Rosters that enforce the rules
- en body: Seasons, age categories, teams and players with play-up rules and approvals built in. Season rollover
  moves everyone up in one step, and nobody plays where they are not eligible.
- es title: Plantillas que hacen cumplir las reglas
- es body: Temporadas, categorías de edad, equipos y jugadores con reglas de categoría superior y aprobaciones
  integradas. El cambio de temporada sube a todos de un solo paso, y nadie juega donde no es elegible.
- id title: Roster yang menegakkan aturan
- id body: Musim, kategori usia, tim, dan pemain dengan aturan main di kategori atas serta persetujuan bawaan.
  Pergantian musim menaikkan semua orang dalam satu langkah, dan tidak ada yang bermain di tempat yang tidak
  layak.

### 3.2 Live match statistics
- en title: Stats from the bench, with or without signal
- en body: Score a game from a phone at the scorer's table. Several people can record at once, the box score
  updates live, and if the gym has no coverage the events sync when you are back online.
- es title: Estadísticas desde el banquillo, con o sin cobertura
- es body: Anota el partido desde un móvil en la mesa. Varias personas pueden registrar a la vez, la hoja de
  estadísticas se actualiza en vivo y, si el pabellón no tiene cobertura, los eventos se sincronizan al volver a
  tener conexión.
- id title: Statistik dari bangku cadangan, dengan atau tanpa sinyal
- id body: Catat pertandingan dari ponsel di meja pencatat. Beberapa orang bisa mencatat sekaligus, box score
  diperbarui langsung, dan jika aula tidak ada sinyal, kejadian disinkronkan saat kembali online.

### 3.3 Training and attendance
- en title: Plans, sessions and who actually showed up
- en body: Weekly calendar in your academy's time zone, training plans you can reuse, attendance in two taps, and
  planned absences so coaches know before practice starts.
- es title: Planes, sesiones y quién vino de verdad
- es body: Calendario semanal en la zona horaria de tu academia, planes de entrenamiento reutilizables,
  asistencia en dos toques y ausencias previstas para que el entrenador lo sepa antes de empezar.
- id title: Rencana, sesi, dan siapa yang benar-benar hadir
- id body: Kalender mingguan dalam zona waktu akademimu, rencana latihan yang bisa dipakai ulang, kehadiran dalam
  dua ketukan, dan absen terencana supaya pelatih tahu sebelum latihan dimulai.

### 3.4 Health and fitness
- en title: Growth, injuries and fitness against real norms
- en body: Height and weight over time, injuries with return dates and availability, and physical tests scored
  against published age and sex norms, so a 12-year-old is compared with 12-year-olds.
- es title: Crecimiento, lesiones y forma física con baremos reales
- es body: Altura y peso a lo largo del tiempo, lesiones con fecha de vuelta y disponibilidad, y pruebas físicas
  valoradas con baremos publicados por edad y sexo, para que un niño de 12 años se compare con niños de 12 años.
- id title: Pertumbuhan, cedera, dan kebugaran dengan norma nyata
- id body: Tinggi dan berat dari waktu ke waktu, cedera dengan tanggal kembali dan ketersediaan, serta tes fisik
  yang dinilai dengan norma usia dan jenis kelamin yang terpublikasi, sehingga anak 12 tahun dibandingkan dengan
  anak 12 tahun.

### 3.5 Parents and players
- en title: Families see what matters, nothing more
- en body: Parents follow their own children's sessions, availability and match events. Players see their own
  line. Coaches and admins see their teams. Access follows the role, automatically.
- es title: Las familias ven lo que importa, nada más
- es body: Los padres siguen las sesiones, la disponibilidad y los eventos de partido de sus propios hijos. Los
  jugadores ven su propia línea. Entrenadores y administradores ven sus equipos. El acceso sigue al rol, sin
  configurar nada.
- id title: Keluarga melihat yang penting, tidak lebih
- id body: Orang tua mengikuti sesi, ketersediaan, dan kejadian pertandingan anak mereka sendiri. Pemain melihat
  catatannya sendiri. Pelatih dan admin melihat tim mereka. Akses mengikuti peran, secara otomatis.

### 3.6 One login, many academies
- en title: Each academy is an island; people are not
- en body: Every academy's data is isolated at the database level. A coach who works for two academies, or a
  parent with children in two, uses one login and switches in a tap.
- es title: Cada academia es una isla; las personas no
- es body: Los datos de cada academia están aislados a nivel de base de datos. Un entrenador que trabaja en dos
  academias, o un padre con hijos en dos, usa un solo acceso y cambia con un toque.
- id title: Setiap akademi adalah pulau; orangnya tidak
- id body: Data setiap akademi terisolasi di tingkat basis data. Pelatih yang bekerja di dua akademi, atau orang
  tua dengan anak di dua akademi, memakai satu login dan berpindah dengan satu ketukan.

## 4. For every role (four short lines)

- en: **Admin** · Set up the season once; approvals, eligibility and the audit trail take care of the rest.
- es: **Administrador** · Configura la temporada una vez; aprobaciones, elegibilidad y el registro de actividad
  hacen el resto.
- id: **Admin** · Siapkan musim sekali; persetujuan, kelayakan, dan jejak aktivitas mengurus sisanya.

- en: **Coach** · Your teams, your sessions, your match sheet, on the phone in your pocket.
- es: **Entrenador** · Tus equipos, tus sesiones, tu hoja de partido, en el móvil que llevas en el bolsillo.
- id: **Pelatih** · Tim, sesi, dan lembar pertandinganmu, di ponsel yang ada di sakumu.

- en: **Parent** · Know when practice is, whether your child is cleared to play, and how they did on Saturday.
- es: **Padre o madre** · Sabe cuándo hay entrenamiento, si tu hijo puede jugar y qué tal lo hizo el sábado.
- id: **Orang tua** · Tahu kapan latihan, apakah anakmu boleh bermain, dan bagaimana penampilannya hari Sabtu.

- en: **Player** · Your stats, your tests, your progress. Yours only.
- es: **Jugador** · Tus estadísticas, tus pruebas, tu progreso. Solo tuyos.
- id: **Pemain** · Statistikmu, tesmu, kemajuanmu. Hanya milikmu.

## 5. Why it costs less

**Title**
- en: Less software, fewer subscriptions
- es: Menos programas, menos suscripciones
- id: Lebih sedikit perangkat lunak, lebih sedikit langganan

**Body**
- en: One tool replaces the registration spreadsheet, the stats app, the group chat for attendance and the folder
  of fitness PDFs. It is open source and free during early access; when plans arrive they will be per academy, not
  per coach or per player.
- es: Una sola herramienta sustituye a la hoja de inscripciones, la app de estadísticas, el grupo de chat para la
  asistencia y la carpeta de PDFs de pruebas físicas. Es código abierto y gratuita durante el acceso anticipado;
  cuando lleguen los planes serán por academia, no por entrenador ni por jugador.
- id: Satu alat menggantikan lembar pendaftaran, aplikasi statistik, grup chat untuk kehadiran, dan folder PDF tes
  kebugaran. Sumber terbuka dan gratis selama akses awal; ketika paket hadir, harganya per akademi, bukan per
  pelatih atau per pemain.

## 6. Coming next (roadmap teaser; keep to items in docs/roadmap.md)

**Title**
- en: On the way
- es: En camino
- id: Segera hadir

**Items** (title · one line)
- en: Notifications · Practice reminders, line-up changes and match results on your phone.
- es: Notificaciones · Recordatorios de entrenamiento, cambios de quinteto y resultados en tu móvil.
- id: Notifikasi · Pengingat latihan, perubahan susunan, dan hasil pertandingan di ponselmu.

- en: Self-service sign-up · Academies join from this page; today it is by invitation.
- es: Alta sin invitación · Las academias se darán de alta desde esta página; hoy es por invitación.
- id: Pendaftaran mandiri · Akademi mendaftar dari halaman ini; saat ini masih lewat undangan.

- en: Integrations · Roster and match events published for the tools you already use.
- es: Integraciones · Plantillas y eventos de partido publicados para las herramientas que ya usas.
- id: Integrasi · Roster dan kejadian pertandingan dipublikasikan untuk alat yang sudah kamu pakai.

- en: Season reports · Attendance, minutes and development per player, ready to share with families.
- es: Informes de temporada · Asistencia, minutos y desarrollo por jugador, listos para compartir con las
  familias.
- id: Laporan musim · Kehadiran, menit bermain, dan perkembangan per pemain, siap dibagikan ke keluarga.

## 7. Join (invitation request form; sent to the platform since WP90, ADR-0044)

**Title**
- en: Request an invitation
- es: Solicita una invitación
- id: Minta undangan

**Intro**
- en: Hoops Academy is invitation-only while in early access. Tell us about your academy and we will get back to
  you.
- es: Hoops Academy funciona solo por invitación durante el acceso anticipado. Cuéntanos de tu academia y te
  responderemos.
- id: Hoops Academy hanya lewat undangan selama akses awal. Ceritakan tentang akademimu dan kami akan
  menghubungimu.

**Fields**
- Name · en: Your name · es: Tu nombre · id: Namamu
- E-mail · en: E-mail · es: Correo electrónico · id: Email
- Role · en: Your role · es: Tu rol · id: Peranmu
  - options en: Academy administrator / Coach / Parent
  - options es: Administrador de la academia / Entrenador / Padre o madre
  - options id: Admin akademi / Pelatih / Orang tua
- Academy · en: Academy name · es: Nombre de la academia · id: Nama akademi

**Submit**
- en: Send request
- es: Enviar solicitud
- id: Kirim permintaan

**Confirmation** (after the server received the request)
- en: Thank you. Invitations are being sent by hand during early access; we will write to you at the address
  above.
- es: Gracias. Durante el acceso anticipado las invitaciones se envían a mano; te escribiremos a la dirección
  indicada.
- id: Terima kasih. Selama akses awal, undangan dikirim secara manual; kami akan menulis ke alamat di atas.

**Validation messages**
- en: Enter a valid e-mail · es: Introduce un correo válido · id: Masukkan email yang valid
- en: Choose your role · es: Elige tu rol · id: Pilih peranmu
- en: Enter your academy's name · es: Introduce el nombre de tu academia · id: Masukkan nama akademimu

**Server answers** (added in WP90)
- Academy name taken (shown under the academy field): en: An academy with this name already exists or has been
  requested · es: Ya existe o se ha solicitado una academia con este nombre · id: Akademi dengan nama ini sudah ada
  atau sudah diminta
- Not sent (rate limit, no connection, server error; the form keeps its values): en: Your request could not be sent.
  Please try again in a minute. · es: No se ha podido enviar tu solicitud. Inténtalo de nuevo en un minuto. · id:
  Permintaanmu tidak bisa dikirim. Coba lagi sebentar lagi.

## 8. Footer

- en: Hoops Academy is free software under the GNU AGPL v3. Source code on GitHub.
- es: Hoops Academy es software libre bajo la GNU AGPL v3. Código fuente en GitHub.
- id: Hoops Academy adalah perangkat lunak bebas di bawah GNU AGPL v3. Kode sumber di GitHub.

- Language switch labels: Español · English · Bahasa Indonesia
- Link labels: en: Sign in / Privacy · es: Iniciar sesión / Privacidad · id: Masuk / Privasi (the privacy link
  points to the existing policy page if one exists; otherwise omit the link, do not invent a policy)

## 9. Login screen (added in WP70)

- Link back to this page, top left of the sign-in screen: en: Back · es: Volver · id: Kembali
