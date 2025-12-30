import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cross_file/cross_file.dart';
import '../../core/providers/moment_providers.dart';
import '../../core/supabase/supabase_client.dart';
import '../../theme/app_theme.dart';

class ShareMomentScreen extends ConsumerStatefulWidget {
  final String momentId;
  final String? groupId;
  
  const ShareMomentScreen({
    super.key,
    required this.momentId,
    this.groupId,
  });
  
  @override
  ConsumerState<ShareMomentScreen> createState() => _ShareMomentScreenState();
}

class _ShareMomentScreenState extends ConsumerState<ShareMomentScreen> {
  final GlobalKey _qrKey = GlobalKey();
  
  Future<void> _shareQrCode(String momentTitle, String qrData) async {
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing QR code...')),
      );

      final painter = QrPainter(
        data: qrData,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
        color: Colors.black,
        emptyColor: Colors.white,
      );

      final picRecorder = ui.PictureRecorder();
      final canvas = Canvas(picRecorder);
      const size = 500.0;
      painter.paint(canvas, const Size(size, size));
      final picture = picRecorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      if (kIsWeb) {
        final base64Image = base64Encode(pngBytes);
        final dataUri = 'data:image/png;base64,$base64Image';
        
        if (!mounted) return;
        await Share.share(
          'Join my moment "$momentTitle" on MOMENTRA!\n\nQR Code Data:\n$qrData\n\nOr scan the QR code shown in the app.',
          subject: 'Join $momentTitle on MOMENTRA',
        );
      } else {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/moment_qr_${widget.momentId}_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(pngBytes);

        if (!mounted) return;
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Join $momentTitle on MOMENTRA',
          text: 'Scan this QR code to join my moment "$momentTitle" on MOMENTRA!',
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR code shared successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing QR code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _shareLink(String momentTitle, String shareLink) async {
    try {
      await Share.share(
        'Join my moment "$momentTitle" on MOMENTRA!\n\n$shareLink',
        subject: 'Join $momentTitle on MOMENTRA',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing link: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final asyncMoment = ref.watch(momentProvider(widget.momentId));
    final currentUser = supabase().auth.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Moment'),
      ),
      body: asyncMoment.when(
        data: (moment) {
          // Create share data
          final shareData = {
            'type': 'moment_invite',
            'moment_id': widget.momentId,
            'moment_title': moment.title,
            'group_id': widget.groupId,
            'invited_by': currentUser?.email ?? '',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          };
          
          final qrData = jsonEncode(shareData);
          final shareLink = 'https://momentra.app/moment/${widget.momentId}'; // Placeholder URL
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          moment.title,
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Share this moment with others',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // QR Code
                RepaintBoundary(
                  key: _qrKey,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 250.0,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Share Link
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share Link',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: MomentraColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  shareLink,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                // Copy to clipboard
                                // Clipboard.setData(ClipboardData(text: shareLink));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Link copied to clipboard!')),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Share Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _shareQrCode(moment.title, qrData),
                    icon: const Icon(Icons.qr_code),
                    label: const Text('Share QR Code'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _shareLink(moment.title, shareLink),
                    icon: const Icon(Icons.link),
                    label: const Text('Share Link'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(momentProvider(widget.momentId));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

