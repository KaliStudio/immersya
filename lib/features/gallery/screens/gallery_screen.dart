// lib/features/gallery/screens/gallery_screen.dart
import 'package:flutter/material.dart';
import 'package:immersya_mobile_app/api/mock_api_service.dart';
import 'package:immersya_mobile_app/features/gallery/screens/contribution_detail_screen.dart'; // Import de l'écran de détail
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> with AutomaticKeepAliveClientMixin {
  Future<List<Contribution>>? _contributionsFuture;

  @override
  void initState() {
    super.initState();
    // Utiliser addPostFrameCallback pour appeler le Provider après la construction initiale
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContributions();
    });
  }

  void _loadContributions() {
    if (mounted) {
      final apiService = context.read<MockApiService>();
      setState(() {
        _contributionsFuture = apiService.fetchUserContributions();
      });
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Contributions'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Contribution>>(
        future: _contributionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucune contribution pour le moment.'));
          }

          final contributions = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async { _loadContributions(); },
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: contributions.length,
              itemBuilder: (context, index) {
                return _buildContributionCard(contributions[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildContributionCard(Contribution contribution) {
    final theme = Theme.of(context);
    final statusInfo = _getStatusInfo(contribution.status);

    // --- CORRECTION ICI ---
    // On enveloppe le Card dans un InkWell pour le rendre cliquable.
    return InkWell(
      onTap: () {
        // Logique de navigation vers l'écran de détail
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContributionDetailScreen(contribution: contribution),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bannière de l'image
            Stack(
              alignment: Alignment.bottomLeft,
              children: [
                Image.network(
                  contribution.thumbnailUrl ?? 'https://placehold.co/600x400/000000/FFFFFF/png',
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    return progress == null ? child : const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()));
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(height: 150, child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey));
                  },
                ),
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withAlpha(204)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    contribution.title,
                    style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // Corps de la carte
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(statusInfo['icon'], color: statusInfo['color'], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        statusInfo['text']!,
                        style: TextStyle(color: statusInfo['color'], fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Type: ${contribution.type}'),
                      Text('${contribution.photoCount} photos'),
                      Text(DateFormat('dd/MM/yyyy').format(contribution.date)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(ContributionStatus status) {
    switch (status) {
      case ContributionStatus.completed:
        return {'color': Colors.green, 'icon': Icons.check_circle, 'text': 'Modélisé'};
      case ContributionStatus.processing:
        return {'color': Colors.orange, 'icon': Icons.hourglass_top, 'text': 'En Traitement'};
      case ContributionStatus.pending:
        return {'color': Colors.grey, 'icon': Icons.cloud_upload_outlined, 'text': 'En Attente'};
      case ContributionStatus.failed:
        return {'color': Colors.red, 'icon': Icons.error, 'text': 'Échec'};
    }
  }
}