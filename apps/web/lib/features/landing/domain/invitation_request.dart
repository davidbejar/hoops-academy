/// Who may ask for an invitation from the landing page. Players never request
/// a new academy (decisions 51 and 58).
enum InvitationRole { admin, coach, parent }

/// Why an [InvitationRequest] cannot be sent yet.
enum InvitationProblem { invalidEmail, missingRole, missingAcademy }

/// What came of sending a request (ADR-0044). The server answers the same for
/// every valid request, so there is nothing to tell about the e-mail.
enum InvitationOutcome {
  /// Received (or silently dropped as spam: indistinguishable on purpose).
  sent,

  /// An academy or an open request already has this name (409).
  academyTaken,

  /// The server could not take it now (rate limit, network, server error).
  failed,
}

/// What a visitor typed into the landing's invitation form; sent to
/// `POST /platform/academy-requests` (WP90, ADR-0044).
class InvitationRequest {
  const InvitationRequest({
    required this.name,
    required this.email,
    required this.academy,
    this.role,
    this.languageCode = 'es',
    this.website = '',
  });

  /// Optional: the copy has no validation message for it.
  final String name;
  final String email;
  final InvitationRole? role;
  final String academy;

  /// The page's language; the decision e-mail is written in it.
  final String languageCode;

  /// The honeypot: a field no person sees or fills. A request with a value is
  /// answered like any other and dropped by the server.
  final String website;

  Set<InvitationProblem> get problems => {
    if (!isValidEmail(email)) InvitationProblem.invalidEmail,
    if (role == null) InvitationProblem.missingRole,
    if (academy.trim().isEmpty) InvitationProblem.missingAcademy,
  };
}

final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// A pragmatic shape check (local part, `@`, a dotted domain); the server
/// checks the rest.
bool isValidEmail(String value) => _email.hasMatch(value.trim());
