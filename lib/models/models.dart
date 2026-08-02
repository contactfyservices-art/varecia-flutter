/// Modèles de données — chacun mappe directement les documents Firestore
/// utilisés par l'ancienne version web (mêmes clés, pour compatibilité).

class AppUser {
  final String email;
  final String prenom;
  final String nom;
  final String niveau;
  final String passwordHash; // conservé pour compatibilité, non utilisé si Firebase Auth activé
  final String status; // "pending" | "approved"
  final String? photo;

  AppUser({
    required this.email,
    required this.prenom,
    required this.nom,
    required this.niveau,
    required this.passwordHash,
    required this.status,
    this.photo,
  });

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        email: m['email'] ?? '',
        prenom: m['prenom'] ?? '',
        nom: m['nom'] ?? '',
        niveau: m['niveau'] ?? '',
        passwordHash: m['password'] ?? '',
        status: m['status'] ?? 'pending',
        photo: m['photo'],
      );

  Map<String, dynamic> toMap() => {
        'email': email,
        'prenom': prenom,
        'nom': nom,
        'niveau': niveau,
        'password': passwordHash,
        'status': status,
        if (photo != null) 'photo': photo,
      };

  String get fullName => '$prenom $nom';

  /// Retourne une copie de cet utilisateur avec certains champs remplacés.
  /// Nécessaire pour mettre à jour la photo affichée sans refaire un
  /// appel Firestore (corrige le bug de photo qui ne s'affichait pas).
  AppUser copyWith({
    String? email,
    String? prenom,
    String? nom,
    String? niveau,
    String? passwordHash,
    String? status,
    String? photo,
  }) {
    return AppUser(
      email: email ?? this.email,
      prenom: prenom ?? this.prenom,
      nom: nom ?? this.nom,
      niveau: niveau ?? this.niveau,
      passwordHash: passwordHash ?? this.passwordHash,
      status: status ?? this.status,
      photo: photo ?? this.photo,
    );
  }
}

class Post {
  final int index; // position dans le tableau Firestore
  final String author;
  final String authorEmail;
  final String text;
  final String date;

  Post({
    required this.index,
    required this.author,
    required this.authorEmail,
    required this.text,
    required this.date,
  });

  factory Post.fromMap(Map<String, dynamic> m, int index) => Post(
        index: index,
        author: m['author'] ?? '',
        authorEmail: m['authorEmail'] ?? '',
        text: m['text'] ?? '',
        date: m['date'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'author': author,
        'authorEmail': authorEmail,
        'text': text,
        'date': date,
      };
}

class LibraryItem {
  final int index;
  final String title;
  final String author;
  final String authorEmail;
  final String date;
  final String? link;
  final String? fileData; // base64
  final String? fileName;
  final String? fileType;

  LibraryItem({
    required this.index,
    required this.title,
    required this.author,
    required this.authorEmail,
    required this.date,
    this.link,
    this.fileData,
    this.fileName,
    this.fileType,
  });

  factory LibraryItem.fromMap(Map<String, dynamic> m, int index) =>
      LibraryItem(
        index: index,
        title: m['title'] ?? '',
        author: m['author'] ?? '',
        authorEmail: m['authorEmail'] ?? '',
        date: m['date'] ?? '',
        link: m['link'],
        fileData: m['fileData'],
        fileName: m['fileName'],
        fileType: m['fileType'],
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'author': author,
        'authorEmail': authorEmail,
        'date': date,
        if (link != null) 'link': link,
        if (fileData != null) 'fileData': fileData,
        if (fileName != null) 'fileName': fileName,
        if (fileType != null) 'fileType': fileType,
      };
}

class GalleryItem {
  final int index;
  final String? image; // base64
  final String? videoLink;
  final String caption;
  final String author;
  final String authorEmail;
  final List<String> likes; // emails
  final List<Map<String, dynamic>> comments;

  GalleryItem({
    required this.index,
    this.image,
    this.videoLink,
    required this.caption,
    required this.author,
    required this.authorEmail,
    required this.likes,
    required this.comments,
  });

  factory GalleryItem.fromMap(Map<String, dynamic> m, int index) =>
      GalleryItem(
        index: index,
        image: m['image'],
        videoLink: m['videoLink'],
        caption: m['caption'] ?? '',
        author: m['author'] ?? '',
        authorEmail: m['authorEmail'] ?? '',
        likes: List<String>.from(m['likes'] ?? []),
        comments: List<Map<String, dynamic>>.from(m['comments'] ?? []),
      );

  Map<String, dynamic> toMap() => {
        if (image != null) 'image': image,
        if (videoLink != null) 'videoLink': videoLink,
        'caption': caption,
        'author': author,
        'authorEmail': authorEmail,
        'likes': likes,
        'comments': comments,
      };
}

class MeetingState {
  final bool active;
  final String? room;

  MeetingState({required this.active, this.room});

  factory MeetingState.fromMap(Map<String, dynamic> m) => MeetingState(
        active: m['active'] ?? false,
        room: m['room'],
      );

  Map<String, dynamic> toMap() => {
        'active': active,
        if (room != null) 'room': room,
      };
}
