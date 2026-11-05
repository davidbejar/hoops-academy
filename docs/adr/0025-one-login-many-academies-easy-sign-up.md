# ADR-0025: One login, many academies; easy sign-up over account-linking safeguards

- Status: Accepted
- Date: 2026-11-05
- Records: the product owner's decisions 1, 2, 3 and 6 of the 2026-11-05 interview (`docs/wp/FOLLOW-UPS.md`, "Plan
  (2026-11-05)")
- Related: ADR-0005 (Keycloak authentication only), ADR-0013 (existing logins are linked on invite), ADR-0023
  (shared-login rule), ADR-0024 (temporary password, no e-mail verification), WP26; security review F-11, F-22

## Context
Hoops Academy is a learning project, not a commercial product (yet). The product owner tests it by creating many users
in many academies, so signing a new person up must be quick: a temporary password shown once to the creator, a new
password chosen at the first sign-in, no e-mail verification and no consent step (ADR-0024).

A person can belong to several academies: a parent with children in two academies, a coach working for two. Keycloak
holds one login per e-mail (ADR-0023: username = e-mail); `core.app_user` maps it to one `person` row per academy. When
an academy invites an e-mail that already signs in, core links that login (ADR-0013) and does not create a second one.

The security review (`docs/security/review-2026-11.md`) and the WP24 handover named the risks this combination brings:
F-11 (an invite links an existing login without its owner's consent and the response reveals that the login exists) and
F-22 (pre-account hijacking: nobody proves that an e-mail belongs to the person, so a login created by one academy can
be linked into another). Suspending or withdrawing an academy also raised the question whether its logins should be
disabled.

## Decision
1. **Easy sign-up stays.** A new login gets a server-generated temporary password and must choose its own at the first
   sign-in (ADR-0024). There is no e-mail verification and no consent flow.
2. **One login may be a member of several academies.** This is a feature, not a defect.
3. **Inviting an existing login links it** (ADR-0013, ADR-0024 §2): its password is never touched, the invitation is
   ACCEPTED at once and the response carries no temporary password. That this reveals the login's existence to the
   inviting admin is accepted (F-11, decision 2).
4. **Pre-account hijacking is accepted** (F-22, decision 3): an academy admin can create a login for an address they do
   not own and choose its password; a later invitation of the same address by another academy links that login.
5. **Logins outlive a suspended or withdrawn academy** (decision 6). Memberships of that academy disappear at once in
   core and within the up-to-30 s membership cache (`hoops.core.cache-ttl`) in game and athlete; there is no cache
   invalidation call. The Keycloak login stays enabled because it may belong to other academies.

## Consequences
- Accepted risks, all inside the "malicious or careless academy admin" threat:
  - **F-11** (Low, CWE-204): the inviting admin learns that an e-mail already has a login (ACCEPTED vs PENDING, presence
    of `temporaryPassword`), and the owner of that login is not asked before it joins another academy.
  - **F-22** (Medium, CWE-287): an admin who created a login for someone else's address can enter a second academy as
    that person once the second academy invites the address.
  - A member of a suspended or withdrawn academy keeps reading game and athlete data of that academy for up to 30 s.
- Temporary passwords still need an expiry; that is a separate decision (decision 4, WP32) and does not change the
  above.
- No code changes follow from this ADR. The FOLLOW-UPS items for F-11, pre-account hijacking and withdrawn-academy
  logins are closed as "accepted by design".

## If the project went commercial
Revisit before real users join:
- Verify the e-mail (a verification link, or a first sign-in from a link sent to the address) before an existing login is
  linked into another academy; until then keep it PENDING for that academy.
- Ask the login's owner for consent on an invitation from another academy, and notify them when a link happens.
- Give every invite the same response whether or not the login existed (closes the F-11 disclosure).
- Decide whether withdrawing an academy should disable logins that belong to no other academy, and add a cache
  invalidation call if 30 s of residual access is too long.
