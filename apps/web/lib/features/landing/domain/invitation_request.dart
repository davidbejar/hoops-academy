/// Who may ask for an invitation from the landing page. Players never request
/// a new academy (decision 51).
enum InvitationRole { admin, coach, parent }

/// Why an [InvitationRequest] cannot be accepted yet.
enum InvitationProblem { invalidEmail, missingRole, missingAcademy }

/// What a visitor typed into the landing's invitation form.
///
/// Placeholder (WP70): the request is validated on the client and then
/// dropped; nothing is sent. The real flow (store, super admin workbench,
/// accept = create the academy) is the "Invitation-only sign-up" item in
/// docs/wp/FOLLOW-UPS.md (decision 51).
class InvitationRequest {
  const InvitationRequest({
    required this.name,
    required this.email,
    required this.academy,
    this.role,
  });

  /// Optional: the copy has no validation message for it.
  final String name;
  final String email;
  final InvitationRole? role;
  final String academy;

  Set<InvitationProblem> get problems => {
    if (!isValidEmail(email)) InvitationProblem.invalidEmail,
    if (role == null) InvitationProblem.missingRole,
    if (academy.trim().isEmpty) InvitationProblem.missingAcademy,
  };
}

final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// A pragmatic shape check (local part, `@`, a dotted domain); the server will
/// verify the address by writing to it.
bool isValidEmail(String value) => _email.hasMatch(value.trim());
