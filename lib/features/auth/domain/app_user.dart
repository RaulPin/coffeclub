/// Usuario de la app.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.isSubscriber = false,
  });

  final String id;
  final String name;
  final String email;
  final String? photoUrl;

  /// Indica si el usuario tiene una suscripción de socio activa.
  final bool isSubscriber;

  AppUser copyWith({bool? isSubscriber}) => AppUser(
        id: id,
        name: name,
        email: email,
        photoUrl: photoUrl,
        isSubscriber: isSubscriber ?? this.isSubscriber,
      );
}
