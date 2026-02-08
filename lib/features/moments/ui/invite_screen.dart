import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../data/repo/moments_repo.dart';
import '../state/moment_detail_provider.dart';
import '../state/moments_list_provider.dart';

class InviteScreen extends ConsumerStatefulWidget {
  final String momentId;
  
  const InviteScreen({super.key, required this.momentId});
  
  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedRole = 'contributor';
  bool _isLoading = false;
  
  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }
  
  Future<void> _invite() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final repo = ref.read(momentsRepoProvider);
      await repo.addParticipant(
        widget.momentId,
        _emailController.text,
        _nameController.text.isEmpty ? null : _nameController.text,
        _selectedRole,
      );
      
      ref.invalidate(momentDetailProvider(widget.momentId));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation sent')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to invite: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MomentraColors.charcoal,
      appBar: AppBar(title: const Text('Invite Participant')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Role'),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'contributor', label: Text('Contributor')),
                  ButtonSegment(value: 'observer', label: Text('Observer')),
                ],
                selected: {_selectedRole},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() => _selectedRole = newSelection.first);
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _invite,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Send Invitation'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

