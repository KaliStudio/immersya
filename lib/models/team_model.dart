// lib/models/team_model.dart

class Team {
  final String id;
  final String name;
  final String tag; // ex: [IMSYA]
  final String description;
  final String bannerUrl; // Une URL pour une image de bannière
  final String creatorId;

  Team({
    required this.id,
    required this.name,
    required this.tag,
    required this.description,
    required this.bannerUrl,
    required this.creatorId,
  });
}