# Core-service model

The core service owns tenancy and identity: academies (tenants) with their settings and logo, the people and
app users behind Keycloak logins, memberships and roles, the guardian links, and the roster: seasons, age categories,
teams, staff and players, plus eligibility cases and approvals. It also owns the billing seams (plans and
subscriptions in the `billing` schema), the audit log, usage snapshots, the academy sign-up requests and the outbox
that publishes roster events to the other services. Roles and the rules are in
[authz-matrix.md](authz-matrix.md) and [glossary.md](glossary.md).

The tables and classes below are generated, not drawn: do not edit between the markers. After changing a Flyway
migration or a `domain` / `application` type, run `just diagrams` and commit the page; `just diagrams-check` (and CI)
fails when a page is stale. A table with more than 24 columns is summarised; private members are left out and
long member lists are capped.

## Tables

<!-- BEGIN GENERATED: er -->
<details open>
<summary>billing_plan, billing_tenant_subscription</summary>

```mermaid
erDiagram
    billing_plan {
        text code PK
        text name "not null"
        integer max_members
        integer max_players
        integer max_teams
    }
    billing_tenant_subscription {
        uuid tenant_id PK "RLS"
        text plan_code FK "not null"
        text status "not null"
        timestamptz started_at "not null"
    }
    billing_plan ||--o{ billing_tenant_subscription : "plan_code"
```

</details>

<details open>
<summary>age_category and 12 more</summary>

```mermaid
erDiagram
    age_category {
        uuid id PK
        uuid tenant_id "RLS, not null"
        text code "not null"
        text name "not null"
        integer max_age
        integer sort_rank "not null"
    }
    app_user {
        uuid id PK
        text keycloak_sub UK "not null"
        text email
        text locale
        timestamptz created_at "not null"
        timestamptz temporary_password_issued_at
        timestamptz temporary_password_expired_at
    }
    approval_request {
        uuid id PK
        uuid tenant_id FK "RLS, not null"
        text action "not null"
        uuid player_id FK "not null"
        jsonb payload "not null"
        uuid requested_by_person_id FK "not null"
        text status "not null"
        uuid decided_by_person_id FK
        timestamptz decided_at
        text decision_note
        timestamptz created_at "not null"
        bigint version "not null"
    }
    eligibility_case {
        uuid id PK
        uuid tenant_id FK "RLS, not null"
        uuid player_id FK "not null"
        uuid team_player_id FK "not null"
        text reason "not null"
        text status "not null"
        text resolution
        text resolution_note
        uuid resolved_by_person_id FK
        timestamptz created_at "not null"
        timestamptz resolved_at
    }
    guardian_link {
        uuid id PK
        uuid tenant_id FK "RLS, not null"
        uuid guardian_person_id FK "not null"
        uuid player_id FK "not null"
        timestamptz created_at "not null"
    }
    membership_role {
        uuid tenant_id FK "RLS, not null"
        uuid person_id PK,FK
        text role PK
        timestamptz granted_at "not null"
    }
    person {
        uuid id PK
        uuid tenant_id "RLS, not null"
        uuid user_id FK
        text given_name "not null"
        text family_name "not null"
        text email
        text phone
        date birth_date
        text gender
        text locale
        boolean active "not null"
        text invitation_status "not null"
        timestamptz created_at "not null"
        timestamptz deactivated_at
    }
    player {
        uuid id PK
        uuid tenant_id FK "RLS, not null"
        uuid person_id FK,UK "not null"
        text status "not null"
        timestamptz created_at "not null"
    }
    season {
        uuid id PK
        uuid tenant_id "RLS, not null"
        text name "not null"
        date start_date "not null"
        date end_date "not null"
        integer reference_year "not null"
        timestamptz created_at "not null"
    }
    team {
        uuid id PK
        uuid tenant_id FK "RLS, not null"
        uuid season_id FK "not null"
        text name "not null"
        text alias
        uuid age_category_id FK "not null"
        text gender_policy "not null"
        timestamptz created_at "not null"
    }
    team_player {
        uuid id PK
        uuid tenant_id FK "RLS, not null"
        uuid team_id FK "not null"
        uuid player_id FK "not null"
        text jersey_number
        date joined_on "not null"
        date left_on
        integer play_up_levels "not null"
        timestamptz invalidated_at
        text invalid_reason
    }
    team_staff {
        uuid tenant_id FK "RLS, not null"
        uuid team_id PK,FK
        uuid person_id PK,FK
        text role "not null"
        date since "not null"
    }
    user_membership_index {
        uuid tenant_id PK,FK "RLS"
        text keycloak_sub PK
        uuid person_id FK "not null"
    }
    age_category ||--o{ team : "tenant_id, age_category_id"
    app_user |o--o{ person : "user_id"
    person |o--o{ approval_request : "tenant_id, decided_by_person_id"
    person |o--o{ eligibility_case : "tenant_id, resolved_by_person_id"
    person ||--o{ approval_request : "tenant_id, requested_by_person_id"
    person ||--o{ guardian_link : "tenant_id, guardian_person_id"
    person ||--o{ membership_role : "tenant_id, person_id"
    person ||--o{ player : "tenant_id, person_id"
    person ||--o{ team_staff : "tenant_id, person_id"
    person ||--o{ user_membership_index : "tenant_id, person_id"
    player ||--o{ approval_request : "tenant_id, player_id"
    player ||--o{ eligibility_case : "tenant_id, player_id"
    player ||--o{ guardian_link : "tenant_id, player_id"
    player ||--o{ team_player : "tenant_id, player_id"
    season ||--o{ team : "tenant_id, season_id"
    team ||--o{ team_player : "tenant_id, team_id"
    team ||--o{ team_staff : "tenant_id, team_id"
    team_player ||--o{ eligibility_case : "tenant_id, team_player_id"
```

</details>

<details open>
<summary>tenant, tenant_settings</summary>

```mermaid
erDiagram
    tenant {
        uuid id PK
        text slug UK "not null"
        text name "not null"
        text status "not null"
        text status_reason
        text timezone "not null"
        text default_locale "not null"
        text contact_email
        text website_url
        timestamptz created_at "not null"
        timestamptz suspended_at
        timestamptz withdrawn_at
        date retain_until
    }
    tenant_settings {
        uuid tenant_id PK,FK "RLS"
        text age_rule "not null"
        integer max_play_up_levels
        integer attendance_late_threshold_minutes "not null"
        timestamptz updated_at "not null"
    }
    tenant ||--o{ tenant_settings : "tenant_id"
```

</details>

<details open>
<summary>academy_request and 4 more</summary>

```mermaid
erDiagram
    academy_request {
        uuid id PK
        text status "not null"
        text requester_name
        text email "not null"
        text requester_role "not null"
        text academy_name "not null"
        text locale "not null"
        timestamptz requested_at "not null"
        timestamptz decided_at
        text decided_by
        text reason
        uuid created_tenant_id
        timestamptz notified_at
    }
    audit_event {
        uuid id PK
        bigint seq "not null"
        uuid tenant_id "RLS, not null"
        text actor_sub "not null"
        uuid actor_person_id
        text action "not null"
        text target_type "not null"
        text target_id "not null"
        jsonb metadata "not null"
        timestamptz at "not null"
    }
    outbox {
        uuid id PK
        uuid tenant_id "RLS, not null"
        text event_type "not null"
        text aggregate_type "not null"
        text aggregate_id "not null"
        jsonb payload "not null"
        timestamptz occurred_at "not null"
        timestamptz published_at
        text topic
        bigint seq "not null"
    }
    tenant_logo {
        uuid tenant_id PK "RLS"
        text content_type "not null"
        bytea bytes "not null"
        integer size_bytes "not null"
        text etag "not null"
        timestamptz updated_at "not null"
    }
    usage_snapshot {
        uuid id PK
        uuid tenant_id "RLS, not null"
        timestamptz collected_at "not null"
        jsonb report "not null"
        date snapshot_date
    }
```

</details>
<!-- END GENERATED: er -->

## Domain classes

<!-- BEGIN GENERATED: domain -->
<details open>
<summary>Package approvals</summary>

```mermaid
classDiagram
    class ApprovalAction {
        <<enumeration>>
        ADD_PLAYER
        WITHDRAW_PLAYER
    }
    class ApprovalPayload {
        <<record>>
        +TeamId team
        +JerseyNumber jersey
        +String note
        +String reason
    }
    class ApprovalPolicy {
        +requiresApproval(Set~TenantRole~,ApprovalAction) boolean
    }
    class ApprovalRequest {
        <<record>>
        +ApprovalRequestId id
        +ApprovalAction action
        +PlayerId player
        +ApprovalPayload payload
        +PersonId requestedBy
        +ApprovalStatus status
        +PersonId decidedBy
        +Instant decidedAt
        +String decisionNote
        +Instant createdAt
        and 4 more
    }
    class ApprovalRequestId {
        <<record>>
        +UUID value
    }
    class ApprovalStatus {
        <<enumeration>>
        PENDING
        APPROVED
        REJECTED
        CANCELLED
    }
    ApprovalRequest --> ApprovalAction : action
    ApprovalRequest --> ApprovalPayload : payload
    ApprovalRequest --> ApprovalRequestId : id
    ApprovalRequest --> ApprovalStatus : status
```

</details>

<details open>
<summary>Package eligibility</summary>

```mermaid
classDiagram
    class AgeFunction {
        <<enumeration>>
        BIRTH_YEAR
        BIRTHDAY
    }
    class CaseResolution {
        <<enumeration>>
        REASSIGNED
        REMOVED_FROM_TEAM
        DISMISSED
    }
    class CaseStatus {
        <<enumeration>>
        OPEN
        RESOLVED
    }
    class CategoryLadder {
        +of(Collection~AgeCategory~) CategoryLadder
        +categories() List~AgeCategory~
        +find(AgeCategoryId) Optional~AgeCategory~
        +naturalFor(int) Optional~AgeCategory~
        +levelsBetween(AgeCategory,AgeCategoryId) int
    }
    class Eligibility {
        <<interface>>
        +allowed() boolean
        +playUpLevels() int
        +reasons() List~EligibilityReason~
    }
    class EligibilityCandidate {
        <<record>>
        +PlayerId player
        +PlayerStatus status
        +LocalDate birthDate
        +Gender gender
        +isActive() boolean
    }
    class EligibilityCase {
        <<record>>
        +EligibilityCaseId id
        +PlayerId player
        +TeamPlayerId assignment
        +EligibilityReason reason
        +CaseStatus status
        +Instant openedAt
        +Instant resolvedAt
        +PersonId resolvedBy
        +CaseResolution resolution
        +String resolutionNote
        and 2 more
    }
    class EligibilityCaseId {
        <<record>>
        +UUID value
    }
    class EligibilityEvaluator {
        +evaluate(EligibilityCandidate,Team,Season,LocalDate) Evaluation
    }
    class EligibilityReason {
        <<enumeration>>
        PLAYER_NOT_ACTIVE
        MISSING_BIRTH_DATE
        MISSING_GENDER
        GENDER_POLICY
        CATEGORY_TOO_LOW
        PLAY_UP_LIMIT_EXCEEDED
    }
    class Evaluation {
        <<record>>
        +Eligibility eligibility
        +Integer age
        +AgeCategory naturalCategory
    }
    class PlayerStatusDerivation {
        +derive(PlayerStatus,boolean) PlayerStatus
    }
    EligibilityCase --> CaseResolution : resolution
    EligibilityCase --> CaseStatus : status
    EligibilityCase --> EligibilityCaseId : id
    EligibilityCase --> EligibilityReason : reason
    EligibilityEvaluator --> AgeFunction : ageFunction
    EligibilityEvaluator --> CategoryLadder : ladder
    Evaluation --> Eligibility : eligibility
```

</details>

<details open>
<summary>Package identity</summary>

```mermaid
classDiagram
    class AppUser {
        <<record>>
        +UserId id
        +String subject
        +String email
        +AppLocale locale
        +withEmail(String) AppUser
        +withLocale(AppLocale) AppUser
    }
    class TemporaryPassword {
        +of(String) TemporaryPassword
        +reveal() String
        +equals(Object) boolean
        +hashCode() int
        +toString() String
    }
    class TemporaryPasswordStatus {
        <<enumeration>>
        ACTIVE
        EXPIRED
        NONE
    }
    class UserId {
        <<record>>
        +UUID value
    }
    AppUser --> UserId : id
```

</details>

<details open>
<summary>Package logo</summary>

```mermaid
classDiagram
    class ImageFormat {
        <<enumeration>>
        PNG
        JPEG
        WEBP
    }
    class LogoImage {
        +of(byte[]) LogoImage
        +restore(ImageFormat,byte[],String) LogoImage
        +format() ImageFormat
        +bytes() byte[]
        +sizeBytes() int
        +etag() String
        +matches(String) boolean
    }
    class LogoTooLargeException {
    }
    class UnsupportedLogoFormatException {
    }
    LogoImage --> ImageFormat : format
```

</details>

<details open>
<summary>Package membership</summary>

```mermaid
classDiagram
    class Gender {
        <<enumeration>>
        MALE
        FEMALE
    }
    class GuardianLink {
        <<record>>
        +GuardianLinkId id
        +PersonId guardian
        +PlayerId player
        +Instant createdAt
    }
    class GuardianLinkId {
        <<record>>
        +UUID value
    }
    class InvitationStatus {
        <<enumeration>>
        NONE
        PENDING
        ACCEPTED
    }
    class LastAdminRule {
        +checkRoleChange(Set~TenantRole~,Set~TenantRole~,long) void
        +checkDeactivation(Set~TenantRole~,long) void
    }
    class Person {
        <<record>>
        +PersonId id
        +UserId userId
        +PersonalData data
        +Set~TenantRole~ roles
        +boolean active
        +InvitationStatus invitationStatus
        +Instant createdAt
        +Instant deactivatedAt
        +isPlayer() boolean
        +isAdmin() boolean
        and 6 more
    }
    class PersonId {
        <<record>>
        +UUID value
    }
    class PersonalData {
        <<record>>
        +String givenName
        +String familyName
        +String email
        +String phone
        +LocalDate birthDate
        +Gender gender
        +AppLocale locale
        +displayName() String
    }
    class PersonalDataChanges {
        <<record>>
        +Patch~String~ givenName
        +Patch~String~ familyName
        +Patch~String~ email
        +Patch~String~ phone
        +Patch~LocalDate~ birthDate
        +Patch~Gender~ gender
        +Patch~AppLocale~ locale
        +withGivenName(Patch~String~) PersonalDataChanges
        +withFamilyName(Patch~String~) PersonalDataChanges
        +withEmail(Patch~String~) PersonalDataChanges
        and 4 more
    }
    class PlayerId {
        <<record>>
        +UUID value
    }
    class PlayerStatus {
        <<enumeration>>
        PENDING_APPROVAL
        ACTIVE
        ORPHAN
        WITHDRAWN
        REJECTED
    }
    GuardianLink --> GuardianLinkId : id
    GuardianLink --> PersonId : guardian
    GuardianLink --> PlayerId : player
    Person --> InvitationStatus : invitationStatus
    Person --> PersonId : id
    Person --> PersonalData : data
    PersonalData --> Gender : gender
    PersonalDataChanges --> Gender : gender
```

</details>

<details open>
<summary>Package roster</summary>

```mermaid
classDiagram
    class AgeCategory {
        <<record>>
        +AgeCategoryId id
        +String code
        +String name
        +Integer maxAge
        +int rank
        +isUnlimited() boolean
        +admitsAge(int) boolean
        +apply(AgeCategoryChanges) AgeCategory
    }
    class AgeCategoryChanges {
        <<record>>
        +Patch~String~ code
        +Patch~String~ name
        +Patch~Integer~ maxAge
        +Patch~Integer~ rank
        +changesLadder() boolean
    }
    class AgeCategoryId {
        <<record>>
        +UUID value
    }
    class DefaultAgeCategories {
        +create() List~AgeCategory~
    }
    class EndedSeasons {
        +among(Collection~SeasonId~,Collection~Season~,LocalDate) Set~SeasonId~
    }
    class GenderPolicy {
        <<enumeration>>
        MALE
        FEMALE
        MIXED
    }
    class JerseyNumber {
        <<record>>
        +String value
    }
    class Season {
        <<record>>
        +SeasonId id
        +String name
        +LocalDate startsOn
        +LocalDate endsOn
        +int referenceYear
        +overlaps(Season) boolean
        +isCurrent(LocalDate) boolean
        +hasEnded(LocalDate) boolean
        +apply(SeasonChanges) Season
    }
    class SeasonChanges {
        <<record>>
        +Patch~String~ name
        +Patch~LocalDate~ startsOn
        +Patch~LocalDate~ endsOn
        +Patch~Integer~ referenceYear
        +changesReferenceYear() boolean
    }
    class SeasonId {
        <<record>>
        +UUID value
    }
    class StaffRole {
        <<enumeration>>
        COACH
        ASSISTANT_COACH
    }
    class Team {
        <<record>>
        +TeamId id
        +SeasonId season
        +String name
        +String alias
        +AgeCategoryId category
        +GenderPolicy genderPolicy
        +apply(TeamChanges) Team
        +cloneInto(SeasonId) Team
    }
    class TeamChanges {
        <<record>>
        +Patch~String~ name
        +Patch~String~ alias
        +Patch~AgeCategoryId~ category
        +Patch~GenderPolicy~ genderPolicy
        +changesEligibility() boolean
    }
    class TeamId {
        <<record>>
        +UUID value
    }
    class TeamPlayer {
        <<record>>
        +TeamPlayerId id
        +TeamId team
        +PlayerId player
        +JerseyNumber jersey
        +LocalDate joinedOn
        +LocalDate leftOn
        +int playUpLevels
        +Instant invalidatedAt
        +EligibilityReason invalidReason
        +isOpen() boolean
        and 4 more
    }
    class TeamPlayerId {
        <<record>>
        +UUID value
    }
    class TeamStaffMember {
        <<record>>
        +TeamId team
        +PersonId person
        +StaffRole role
        +LocalDate since
        +withRole(StaffRole) TeamStaffMember
        +forTeam(TeamId,LocalDate) TeamStaffMember
    }
    AgeCategory --> AgeCategoryId : id
    Season --> SeasonId : id
    Team --> AgeCategoryId : category
    Team --> GenderPolicy : genderPolicy
    Team --> SeasonId : season
    Team --> TeamId : id
    TeamChanges --> AgeCategoryId : category
    TeamChanges --> GenderPolicy : genderPolicy
    TeamPlayer --> JerseyNumber : jersey
    TeamPlayer --> TeamId : team
    TeamPlayer --> TeamPlayerId : id
    TeamStaffMember --> StaffRole : role
    TeamStaffMember --> TeamId : team
```

</details>

<details open>
<summary>Package shared</summary>

```mermaid
classDiagram
    class AppLocale {
        <<enumeration>>
        ES
        EN
        ID
    }
    class Patch {
        +absent() Patch~T~
        +of(T) Patch~T~
        +isPresent() boolean
        +clears() boolean
        +applyTo(T) T
        +map(Function~T,R~) Patch~R~
    }
    class Require {
        +text(String,String,int) String
        +present(T,String) T
        +violation(String,String) DomainRuleViolation
    }
    class TenantCalendar {
        +today(Instant,ZoneId) LocalDate
    }
```

</details>

<details open>
<summary>Package signup</summary>

```mermaid
classDiagram
    class AcademyName {
        <<record>>
        +String value
        +toString() String
    }
    class AcademyRequest {
        <<record>>
        +AcademyRequestId id
        +AcademyRequestStatus status
        +Requester requester
        +AcademyName academyName
        +Instant requestedAt
        +Instant decidedAt
        +String decidedBy
        +String reason
        +TenantId tenantId
        +Instant notifiedAt
        and 4 more
    }
    class AcademyRequestId {
        <<record>>
        +UUID value
        +toString() String
    }
    class AcademyRequestStatus {
        <<enumeration>>
        PENDING
        ACCEPTED
        REJECTED
    }
    class PlainText {
    }
    class Requester {
        <<record>>
        +Optional~String~ name
        +String email
        +RequesterRole role
        +AppLocale locale
    }
    class RequesterRole {
        <<enumeration>>
        ADMIN
        COACH
        PARENT
    }
    AcademyRequest --> AcademyName : academyName
    AcademyRequest --> AcademyRequestId : id
    AcademyRequest --> AcademyRequestStatus : status
    AcademyRequest --> Requester : requester
    Requester --> RequesterRole : role
```

</details>

<details open>
<summary>Package tenant</summary>

```mermaid
classDiagram
    class AgeRule {
        <<enumeration>>
        BIRTH_YEAR
        BIRTHDAY
    }
    class Tenant {
        <<record>>
        +TenantId id
        +TenantSlug slug
        +String name
        +TenantStatus status
        +String statusReason
        +ZoneId timezone
        +AppLocale defaultLocale
        +Instant createdAt
        +Instant suspendedAt
        +Instant withdrawnAt
        and 7 more
    }
    class TenantProfile {
        <<record>>
        +TenantId id
        +String slug
        +String name
        +ZoneId timezone
        +AppLocale defaultLocale
        +String contactEmail
        +String websiteUrl
        +TenantStatus status
        +apply(TenantProfileChanges) TenantProfile
    }
    class TenantProfileChanges {
        <<record>>
        +Patch~String~ name
        +Patch~ZoneId~ timezone
        +Patch~AppLocale~ defaultLocale
        +Patch~String~ contactEmail
        +Patch~String~ websiteUrl
    }
    class TenantSettings {
        <<record>>
        +AgeRule ageRule
        +Integer maxPlayUpLevels
        +int attendanceLateThresholdMinutes
        +eligibilityRulesDifferFrom(TenantSettings) boolean
    }
    class TenantSlug {
        <<record>>
        +String value
        +toString() String
    }
    class TenantStatus {
        <<enumeration>>
        ACTIVE
        SUSPENDED
        WITHDRAWN
    }
    Tenant --> TenantSlug : slug
    Tenant --> TenantStatus : status
    TenantProfile --> TenantStatus : status
    TenantSettings --> AgeRule : ageRule
```

</details>
<!-- END GENERATED: domain -->

## Application ports

<!-- BEGIN GENERATED: ports -->
<details open>
<summary>application audit</summary>

```mermaid
classDiagram
    class AuditActorKind {
        <<enumeration>>
        PERSON
        PLATFORM
        SYSTEM
    }
```

</details>

<details open>
<summary>application events</summary>

```mermaid
classDiagram
    class EventTopic {
        <<enumeration>>
        PERSON
        PLAYER
        TEAM
        TEAM_PLAYER
        TEAM_STAFF
        GUARDIAN_LINK
        TENANT
    }
    class RosterChange {
        <<interface>>
    }
```

</details>

<details open>
<summary>application port (1/4)</summary>

```mermaid
classDiagram
    class AcademyRequestNotifier {
        <<interface>>
        +accepted(AcademyRequest,boolean) boolean
        +rejected(AcademyRequest) boolean
    }
    class AcademyRequestRepository {
        <<interface>>
        +insert(AcademyRequest) void
        +tenantNamed(AcademyName) boolean
        +openRequestNamed(AcademyName) boolean
        +pendingFor(String) long
        +find(AcademyRequestId) Optional~AcademyRequest~
        +list(Optional~AcademyRequestStatus~,PageRequest) PageResult~AcademyRequest~
        +decide(AcademyRequest) boolean
        +reopen(AcademyRequestId,TenantId) void
        +markNotified(AcademyRequest) void
    }
    class AgeCategoryRepository {
        <<interface>>
        +insert(AgeCategory) void
        +update(AgeCategory) void
        +delete(AgeCategoryId) void
        +find(AgeCategoryId) Optional~AgeCategory~
        +listByRank() List~AgeCategory~
    }
    class AppUserRepository {
        <<interface>>
        +findBySubject(String) Optional~AppUser~
        +findById(UserId) Optional~AppUser~
        +findOrRegister(String,String) AppUser
        +save(AppUser) void
    }
    class ApprovalRepository {
        <<interface>>
        +insert(ApprovalRequest) void
        +update(ApprovalRequest) void
        +find(ApprovalRequestId) Optional~ApprovalRequest~
        +list(ApprovalFilter,PageRequest) PageResult~ApprovalRequest~
        +addRequesters(Collection~PlayerId~) Map~PlayerId,PersonId~
        +countPending() long
    }
    class AuditAction {
        <<enumeration>>
        ADMIN_ADDED
        ADMIN_REMOVED
        ADMIN_TEMPORARY_PASSWORD_ISSUED
        ADMIN_UPDATED
        APPROVAL_CANCELLED
        GUARDIAN_LINK_CREATED
        GUARDIAN_LINK_REMOVED
        MEMBER_DEACTIVATED
        and 22 more
    }
    class AuditLog {
        <<interface>>
        +record(AuditEvent) void
        +recordAs(PersonId,AuditEvent) void
        +recordFor(TenantId,AuditEvent) void
    }
    class AuditNames {
        <<interface>>
        +persons(Set~UUID~) Map~UUID,String~
        +players(Set~UUID~) Map~UUID,String~
        +tenants(Set~UUID~) Map~UUID,String~
        +activeAdmins(Set~UUID~) Map~UUID,String~
    }
    class AuditTargetType {
        <<enumeration>>
        PERSON
        PLAYER
        TENANT
        APPROVAL_REQUEST
        GUARDIAN_LINK
    }
    class AuditTrail {
        <<interface>>
        +list(AuditFilter,PageRequest) PageResult~AuditRecord~
    }
    class EligibilityCaseRepository {
        <<interface>>
        +insert(EligibilityCase) void
        +update(EligibilityCase) void
        +find(EligibilityCaseId) Optional~CaseOfTeam~
        +openOfPlayer(PlayerId) List~EligibilityCase~
        +list(CaseFilter,PageRequest) PageResult~CaseOfTeam~
    }
    class EntitlementService {
        <<interface>>
        +check(TenantId,Limit) void
    }
    AuditAction --> AuditTargetType : targetType
```

</details>

<details open>
<summary>application port (2/4)</summary>

```mermaid
classDiagram
    class EventBroker {
        <<interface>>
        +send(String,String,String) void
    }
    class GuardianLinkRepository {
        <<interface>>
        +insert(GuardianLink) void
        +exists(PersonId,PlayerId) boolean
        +find(GuardianLinkId) Optional~GuardianLink~
        +delete(GuardianLinkId) void
        +list(Optional~PlayerId~,Optional~PersonId~,PageRequest) PageResult~GuardianLink~
        +playersOf(PersonId) Set~PlayerId~
    }
    class IdentityProviderPort {
        <<interface>>
        +provision(NewIdentity) ProvisionedIdentity
        +setTemporaryPassword(String,TemporaryPassword) void
        +hasOwnPassword(String) boolean
        +updateLogin(LoginUpdate) void
        +disable(String) void
        +enable(String) void
        +delete(String) void
    }
    class LogoRepository {
        <<interface>>
        +find() Optional~StoredLogo~
        +findEtag() Optional~String~
        +save(LogoImage,Instant) StoredLogo
        +delete() boolean
    }
    class MembershipRepository {
        <<interface>>
        +register(String,PersonId) void
        +unregister(PersonId) void
        +ofSubject(String) List~IndexedMembership~
        +linkedInAnotherTenant(String) boolean
        +inOtherTenants(String) List~IndexedMembership~
    }
    class OutboxBacklog {
        <<interface>>
        +pendingByTenant() List~TenantBacklog~
    }
    class OutboxQueue {
        <<interface>>
        +lockNext(int) List~PendingEvent~
        +markPublished(Collection~UUID~) void
    }
    class OutboxWriter {
        <<interface>>
        +write(OutboxEvent) void
    }
    class PendingLoginPersons {
        <<interface>>
        +recordForEach(String,UserId,Function~PersonId,AuditEvent~) int
    }
    class PersonRepository {
        <<interface>>
        +insert(Person) void
        +update(Person) void
        +find(PersonId) Optional~Person~
        +findAll(Collection~PersonId~) List~Person~
        +findActiveByLogin(String) Optional~Person~
        +findByEmail(String) Optional~Person~
        +emailTaken(String,Optional~PersonId~) boolean
        +loginLinked(UserId) boolean
        +countActiveAdmins() long
        +countActive() long
        and 2 more
    }
    class PlatformAuditLog {
        <<interface>>
        +record(TenantId,AuditEvent) void
    }
    class PlatformAuditTrail {
        <<interface>>
        +list(Optional~TenantId~,AuditFilter,PageRequest) PageResult~Row~
    }
```

</details>

<details open>
<summary>application port (3/4)</summary>

```mermaid
classDiagram
    class PlatformOutboxWriter {
        <<interface>>
        +write(OutboxEvent) void
    }
    class PlatformUsers {
        <<interface>>
        +list(Optional~String~,PageRequest) PageResult~Login~
    }
    class PlayerRepository {
        <<interface>>
        +create(PersonId,PlayerStatus) PlayerId
        +findByPerson(PersonId) Optional~PlayerId~
        +findByPersons(Collection~PersonId~) Map~PersonId,PlayerId~
        +personOf(PlayerId) Optional~PersonId~
        +summary(PlayerId) Optional~PlayerSummary~
        +summaries(Collection~PlayerId~) Map~PlayerId,PlayerSummary~
        +find(PlayerId) Optional~PlayerRow~
        +page(PlayerFilter,PageRequest) PageResult~PlayerRow~
        +updateStatus(PlayerId,PlayerStatus) void
        +count() long
        and 2 more
    }
    class RemoteUsagePort {
        <<interface>>
        +service() String
        +fetch(TenantId) Optional~UsageReport~
    }
    class RosterInventory {
        <<interface>>
        +live(EventTopic) List~RosterChange~
        +withEvents(EventTopic,long) Set~String~
        +lastSeq() long
    }
    class RosterStates {
        <<interface>>
        +person(PersonId) Optional~PersonState~
        +player(PlayerId) Optional~PlayerState~
        +team(TeamId) Optional~TeamState~
        +teamsOfSeason(SeasonId) List~TeamId~
        +teamPlayer(TeamPlayerId) Optional~TeamPlayerState~
        +teamStaff(TeamId,PersonId) Optional~TeamStaffState~
        +guardianLink(GuardianLinkId) Optional~GuardianLinkState~
        +tenant() Optional~TenantState~
    }
    class SeasonRepository {
        <<interface>>
        +insert(Season) void
        +update(Season) void
        +find(SeasonId) Optional~Season~
        +listNewestFirst() List~Season~
        +notEndedOn(LocalDate) List~Season~
        +count() long
    }
    class SharedLoginPersons {
        <<interface>>
        +emailTaken(IndexedMembership,String) boolean
        +changeEmail(IndexedMembership,UserId,String,AuditEvent) boolean
    }
    class StaffTeamsQuery {
        <<interface>>
        +staffTeamsOf(PersonId) Set~UUID~
    }
    class SubscriptionRepository {
        <<interface>>
        +subscribe(TenantId,String) void
        +deleteUnprovisioned(TenantId) void
    }
    class TeamPlayerRepository {
        <<interface>>
        +insert(TeamPlayer) void
        +update(TeamPlayer) void
        +find(TeamPlayerId) Optional~TeamPlayer~
        +findOpen(TeamId,PlayerId) Optional~TeamPlayer~
        +ofTeam(TeamId,boolean) List~TeamPlayer~
        +openValidOfTeams(Collection~TeamId~) List~TeamPlayer~
        +openOfPlayers(Collection~PlayerId~) List~TeamPlayer~
        +jerseyTaken(TeamId,JerseyNumber,Optional~TeamPlayerId~) boolean
        +countOpenValid(Collection~TeamId~) Map~TeamId,Long~
    }
    class TeamRepository {
        <<interface>>
        +insert(Team) void
        +update(Team) void
        +find(TeamId) Optional~Team~
        +findAll(Collection~TeamId~) List~Team~
        +inSeasons(Collection~SeasonId~) List~Team~
        +seasonNotEnded(Collection~TeamId~,LocalDate) Set~TeamId~
        +list(TeamFilter,PageRequest) PageResult~Team~
        +nameTaken(SeasonId,String,Optional~TeamId~) boolean
        +usesCategory(AgeCategoryId) boolean
        +count() long
    }
```

</details>

<details open>
<summary>application port (4/4)</summary>

```mermaid
classDiagram
    class TeamStaffRepository {
        <<interface>>
        +ofTeam(TeamId) List~TeamStaffMember~
        +find(TeamId,PersonId) Optional~TeamStaffMember~
        +save(TeamStaffMember) void
        +delete(TeamId,PersonId) void
        +teamsOf(PersonId) Set~TeamId~
    }
    class TemporaryPasswordLogins {
        <<interface>>
        +issued(String,Instant) boolean
        +due(Instant) List~String~
        +lockIfDue(String,Instant) Optional~UserId~
        +expired(String,Instant) void
        +used(String) void
        +statusOf(Collection~UserId~) Map~UserId,TemporaryPasswordStatus~
    }
    class TemporaryPasswordSweeps {
        <<interface>>
        +request() void
    }
    class TenantProfileRepository {
        <<interface>>
        +findCurrent() Optional~TenantProfile~
        +save(TenantProfile) void
    }
    class TenantRepository {
        <<interface>>
        +slugExists(TenantSlug) boolean
        +insert(Tenant) void
        +update(Tenant) void
        +find(TenantId) Optional~Tenant~
        +list(Optional~TenantStatus~,Optional~String~,PageRequest) PageResult~Tenant~
        +ids() List~TenantId~
        +createdBetween(Instant,Instant) List~TenantId~
        +deleteUnprovisioned(TenantId) void
    }
    class TenantSettingsRepository {
        <<interface>>
        +create(TenantSettings) void
        +findCurrent() Optional~TenantSettings~
        +save(TenantSettings) void
    }
    class UsageCounter {
        <<interface>>
        +counters() Map~String,Long~
    }
    class UsageSnapshotRepository {
        <<interface>>
        +save(TenantId,Instant,Object) void
        +history(TenantId,LocalDate,LocalDate) List~DailySnapshot~
    }
```

</details>

<details open>
<summary>application tenant</summary>

```mermaid
classDiagram
    class TenantProvisioningHook {
        <<interface>>
        +onTenantCreated(Tenant) void
    }
    class TenantSettingsListener {
        <<interface>>
        +onEligibilityRulesChanged(TenantSettings,TenantSettings) void
    }
```

</details>
<!-- END GENERATED: ports -->
