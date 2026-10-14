import '../models/owner.dart';

/// The demo account. There is no backend, so any login signs in as this
/// owner; AppSession.signInDemo shows the email typed at Login instead of
/// this placeholder one, but only when what was typed is a valid email (a
/// username keeps this one).
const demoOwner = Owner(name: 'Haiqa Tahir', email: 'haiqa@parco.example');
