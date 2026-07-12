class UserModel {
  final String id;
  final String email;
  final String name;
  final String? photoURL;
  final String authProvider;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.photoURL,
    this.authProvider = 'email',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'photoURL': photoURL,
        'authProvider': authProvider,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        photoURL: json['photoURL'] as String?,
        authProvider: json['authProvider'] as String? ?? 'email',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
