import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../../core/repositories/groups_repo.dart';

final groupsRepoProvider = Provider((_) => GroupsRepo());

class InviteMemberDialog extends ConsumerStatefulWidget {
  final String groupId;

  const InviteMemberDialog({super.key, required this.groupId});

  @override
  ConsumerState<InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends ConsumerState<InviteMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _inviteMember() async {
    debugPrint('🎯 InviteMemberDialog._inviteMember called');
    developer.log('🎯 InviteMemberDialog._inviteMember called');
    
    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ Form validation failed');
      developer.log('❌ Form validation failed');
      return;
    }

    final email = _emailController.text.trim();
    debugPrint('📧 Inviting email: $email to group: ${widget.groupId}');
    developer.log('📧 Inviting email: $email to group: ${widget.groupId}');

    setState(() {
      _isLoading = true;
    });

    try {
      developer.log('📞 Calling addMemberToGroup...');
      final result = await ref.read(groupsRepoProvider).addMemberToGroup(
            widget.groupId,
            email,
          );
      developer.log('✅ addMemberToGroup returned: $result');

      if (mounted) {
        Navigator.of(context).pop();

        String message;
        Color backgroundColor;

        switch (result) {
          case 'success':
            message = 'Member added successfully!';
            backgroundColor = Colors.green;
            break;
          case 'already_member':
            message = 'User is already a member of this group.';
            backgroundColor = Colors.orange;
            break;
          case 'invitation_sent':
            message = 'Invitation sent! Check their email inbox.';
            backgroundColor = Colors.green;
            break;
          case 'invitation_exists':
            message = 'Invitation already sent to this email.';
            backgroundColor = Colors.orange;
            break;
          default:
            message = result;
            backgroundColor = Colors.blue;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      developer.log('❌ ERROR in _inviteMember: $e');
      developer.log('❌ Stack trace: $stackTrace');
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      developer.log('🏁 _inviteMember finished');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    developer.log('🎨 InviteMemberDialog.build called for group: ${widget.groupId}');
    return AlertDialog(
      title: const Text('Invite Member'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'Enter email address',
          ),
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter an email address';
            }
            if (!value.contains('@')) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () {
            debugPrint('🔘 Invite button pressed!');
            developer.log('🔘 Invite button pressed!');
            _inviteMember();
          },
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Invite'),
        ),
      ],
    );
  }
}

