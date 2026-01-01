import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../widgets/momentra_logo_appbar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cross_file/cross_file.dart';
import '../../core/repositories/groups_repo.dart';
import '../../core/supabase/supabase_client.dart';

final groupsRepoProvider = Provider((_) => GroupsRepo());

final groupProvider = FutureProvider.family((ref, String groupId) {
  return ref.watch(groupsRepoProvider).getGroup(groupId);
});

class QrInviteScreen extends ConsumerStatefulWidget {
  final String groupId;

  const QrInviteScreen({super.key, required this.groupId});

  @override
  ConsumerState<QrInviteScreen> createState() => _QrInviteScreenState();
}

class _QrInviteScreenState extends ConsumerState<QrInviteScreen> {
  final GlobalKey _qrKey = GlobalKey();

  Future<void> _shareQrCode(String groupName, String qrData) async {
    try {
      // Show loading
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing QR code...')),
      );

      // Generate QR code image using QrPainter
      final painter = QrPainter(
        data: qrData,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
        color: Colors.black,
        emptyColor: Colors.white,
      );

      // Render to image
      final picRecorder = ui.PictureRecorder();
      final canvas = Canvas(picRecorder);
      const size = 500.0; // Higher resolution for better quality
      painter.paint(canvas, const Size(size, size));
      final picture = picRecorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      if (kIsWeb) {
        // Web platform: Convert to base64 and share as data URI or text
        final base64Image = base64Encode(pngBytes);
        final dataUri = 'data:image/png;base64,$base64Image';
        
        // For web, share the QR data as text with instructions
        if (!mounted) return;
        await Share.share(
          'Join my expense group "$groupName" on MOMENTRA!\n\nQR Code Data:\n$qrData\n\nOr scan the QR code shown in the app.',
          subject: 'Join ${groupName} on MOMENTRA',
        );
      } else {
        // Mobile platforms: Save to file and share
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/qr_code_${widget.groupId}_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(pngBytes);

        // Share the image file
        if (!mounted) return;
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Join ${groupName} on MOMENTRA',
          text: 'Scan this QR code to join my expense group "${groupName}" on MOMENTRA!',
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing QR code: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncGroup = ref.watch(groupProvider(widget.groupId));
    final currentUser = supabase().auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const MomentraLogoAppBar(),
      ),
      body: asyncGroup.when(
        data: (group) {
          // Create invitation data
          final invitationData = {
            'type': 'group_invite',
            'group_id': widget.groupId,
            'group_name': group.name,
            'invited_by': currentUser?.email ?? '',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          };

          // Convert to JSON string for QR code
          final qrData = jsonEncode(invitationData);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Scan to Join',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  group.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 40),
                // QR Code
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 250.0,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Share this QR code with friends to invite them to the group',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Share button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _shareQrCode(group.name, qrData),
                    icon: const Icon(Icons.share),
                    label: const Text('Share QR Code'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading group')),
      ),
    );
  }
}

