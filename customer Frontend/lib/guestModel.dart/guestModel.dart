class Guest {
  String name;
  String email;
  String whatsapp;
  bool isInvited;

  Guest({
    required this.name,
    required this.email,
    required this.whatsapp,
    this.isInvited = false,
  });
}
