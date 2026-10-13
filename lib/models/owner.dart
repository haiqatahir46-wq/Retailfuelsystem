/// The signed-in station owner, as the drawer and Profile show them.
class Owner {
  final String name;

  /// '' when the owner signed up with a username rather than an email.
  final String email;

  const Owner({required this.name, required this.email});

  /// The owner implied by the signup form's "Username or Gmail" field: text
  /// containing '@' is the email and the part before the '@' is the name;
  /// anything else is the name, with no email. A name that comes out blank
  /// falls back to 'Owner' so the drawer and Profile never show an empty
  /// heading.
  factory Owner.fromSignup(String usernameOrEmail) {
    final typed = usernameOrEmail.trim();
    final at = typed.indexOf('@');
    final name = (at >= 0 ? typed.substring(0, at) : typed).trim();
    return Owner(name: name.isEmpty ? 'Owner' : name, email: at >= 0 ? typed : '');
  }
}
