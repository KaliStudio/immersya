// lib/features/gallery/screens/contribution_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:immersya_mobile_app/api/mock_api_service.dart';
import 'package:intl/intl.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ContributionDetailScreen extends StatelessWidget {
  final Contribution contribution;

  const ContributionDetailScreen({super.key, required this.contribution});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // On utilise un CustomScrollView pour un effet de "parallax" sur l'image
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildTitleSection(context),
              _buildInfoSection(context),
              _build3dPreviewSection(context),
              _buildCommentsSection(context),
              const SizedBox(height: 80), // Espace pour le bouton flottant
            ]),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  // --- WIDGETS DÉDIÉS POUR LA LISIBILITÉ ---

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250.0,
      pinned: true,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          contribution.type,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16.0,
            shadows: [Shadow(blurRadius: 4, color: Colors.black)],
          ),
        ),
        background: Image.network(
          contribution.thumbnailUrl ?? 'https://via.placeholder.com/400x250/CCCCCC/FFFFFF?Text=No+Image',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(child: Icon(Icons.image_not_supported, color: Colors.grey));
          },
        ),
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            contribution.title,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                '${contribution.qualityScore}/5.0',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.comment_outlined, color: Colors.grey, size: 18),
              const SizedBox(width: 4),
              Text(
                '${contribution.comments.length} avis',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _infoColumn(Icons.calendar_today_outlined, 'Date', DateFormat('dd/MM/yyyy').format(contribution.date)),
              _infoColumn(Icons.camera_alt_outlined, 'Photos', contribution.photoCount.toString()),
              _infoColumn(Icons.check_circle_outline, 'Statut', contribution.status.name),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _infoColumn(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[400]),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _build3dPreviewSection(BuildContext context) {
    if (contribution.status != ContributionStatus.completed || contribution.model3DUrl == null) {
      return const SizedBox.shrink(); // Ne rien afficher si pas de modèle
    }

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Prévisualisation 3D', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ModelViewer(
                src: contribution.model3DUrl!,
                alt: "Modèle 3D de ${contribution.title}",
                ar: true,
                autoRotate: true,
                cameraControls: true,
                backgroundColor: theme.colorScheme.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Commentaires', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          if (contribution.comments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(child: Text('Aucun commentaire pour le moment.')),
            )
          else
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: contribution.comments.length,
              itemBuilder: (context, index) {
                final comment = contribution.comments[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  color: theme.colorScheme.surface,
                  child: ListTile(
                    leading: CircleAvatar(child: Text(comment.username.substring(0, 1))),
                    title: Text(comment.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(comment.comment),
                    trailing: Text(DateFormat('dd/MM').format(comment.date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
  
  Widget? _buildFloatingActionButton(BuildContext context) {
    if (contribution.status != ContributionStatus.completed) {
      return null;
    }
    return FloatingActionButton.extended(
      onPressed: () {
        // Pour l'instant, on simule l'action avec une SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fonctionnalité "Ajouter un commentaire" à venir !')),
        );
      },
      label: const Text('Ajouter un commentaire'),
      icon: const Icon(Icons.edit_outlined),
    );
  }
}