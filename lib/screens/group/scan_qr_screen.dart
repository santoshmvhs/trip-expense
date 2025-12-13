import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required to scan QR codes'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _processQrCode(String qrData) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Parse QR code data as JSON
      Map<String, dynamic> invitationData;
      try {
        invitationData = jsonDecode(qrData) as Map<String, dynamic>;
      } catch (e) {
        throw Exception('Invalid QR code format. Please scan a valid group invitation QR code.');
      }

      if (invitationData['type'] != 'group_invite') {
        throw Exception('This QR code is not a group invitation');
      }

      final groupId = invitationData['group_id'] as String?;
      if (groupId == null || groupId.isEmpty) {
        throw Exception('Invalid group ID in QR code');
      }

      final userId = currentUser()?.id;
      if (userId == null) {
        throw Exception('Please sign in to join a group');
      }

      // Check existing membership
      final existingMember = await supabase()
          .from('group_members')
          .select()
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingMember != null) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are already a member of this group'),
              backgroundColor: Colors.orange,
            ),
          );
          context.go('/shell/group/$groupId');
        }
        return;
      }

      // Add user to group
      await supabase().from('group_members').insert({
        'group_id': groupId,
        'user_id': userId,
        'role': 'member',
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully joined the group!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/shell/group/$groupId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
      body: FutureBuilder(
        future: _requestCameraPermission(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              MobileScanner(
                controller: _controller,
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty && !_isProcessing) {
                    final barcode = barcodes.first;
                    if (barcode.rawValue != null) {
                      _processQrCode(barcode.rawValue!);
                    }
                  }
                },
              ),
              // Overlay
              CustomPaint(
                painter: _QrOverlayPainter(
                  cutOutSize: 250,
                  borderColor: Theme.of(context).colorScheme.primary,
                ),
              ),
              if (_isProcessing)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Processing...',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _QrOverlayPainter extends CustomPainter {
  final double cutOutSize;
  final Color borderColor;

  _QrOverlayPainter({
    required this.cutOutSize,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final overlayColor = Colors.black.withOpacity(0.5);
    final backgroundPaint = Paint()..color = overlayColor;
    
    // Draw overlay
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);
    
    // Calculate cutout position (center)
    final left = (size.width - cutOutSize) / 2;
    final top = (size.height - cutOutSize) / 2;
    final cutOutRect = Rect.fromLTWH(left, top, cutOutSize, cutOutSize);
    
    // Cut out the center
    final cutOutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(cutOutRect, const Radius.circular(10)));
    
    canvas.drawPath(
      Path.combine(PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        cutOutPath,
      ),
      backgroundPaint,
    );
    
    // Draw border corners
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    
    final cornerLength = 30.0;
    
    // Top-left
    canvas.drawLine(Offset(left, top + cornerLength), Offset(left, top), borderPaint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), borderPaint);
    
    // Top-right
    canvas.drawLine(Offset(left + cutOutSize - cornerLength, top), Offset(left + cutOutSize, top), borderPaint);
    canvas.drawLine(Offset(left + cutOutSize, top), Offset(left + cutOutSize, top + cornerLength), borderPaint);
    
    // Bottom-left
    canvas.drawLine(Offset(left, top + cutOutSize - cornerLength), Offset(left, top + cutOutSize), borderPaint);
    canvas.drawLine(Offset(left, top + cutOutSize), Offset(left + cornerLength, top + cutOutSize), borderPaint);
    
    // Bottom-right
    canvas.drawLine(Offset(left + cutOutSize - cornerLength, top + cutOutSize), Offset(left + cutOutSize, top + cutOutSize), borderPaint);
    canvas.drawLine(Offset(left + cutOutSize, top + cutOutSize - cornerLength), Offset(left + cutOutSize, top + cutOutSize), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

