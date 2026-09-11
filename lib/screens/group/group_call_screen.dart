
import 'package:flutter/material.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../../models/user_model.dart';

class GroupCallScreen extends StatefulWidget {
  const GroupCallScreen({
    super.key,
    required this.users,
    required this.me,
  });

  final List<UserModel> users;
  final UserModel? me;

  @override
  State<GroupCallScreen> createState() => _GroupCallScreenState();
}

class _GroupCallScreenState extends State<GroupCallScreen> {
  static const int maxParticipants = 4;

  final Set<String> _selected = <String>{};

  bool _video = true;
  bool _sending = false;

  List<UserModel> get _candidates {
    return widget.users
        .where((user) => user.id != widget.me?.id)
        .toList();
  }

  List<UserModel> get _selectedUsers {
    return _candidates
        .where((user) => _selected.contains(user.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedUsers = _selectedUsers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Start group call'),
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              10,
            ),
            child: SwitchListTile.adaptive(
              value: _video,
              onChanged: _sending
                  ? null
                  : (value) {
                      setState(() {
                        _video = value;
                      });
                    },
              secondary: Icon(
                _video
                    ? Icons.videocam_rounded
                    : Icons.call_rounded,
              ),
              title: Text(
                _video
                    ? 'Video group call'
                    : 'Audio group call',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: const Text(
                'Invite 2–4 other participants.',
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              4,
              20,
              8,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Select participants',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${selectedUsers.length}/$maxParticipants',
                ),
              ],
            ),
          ),

          Expanded(
            child: _candidates.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Create more ConnectCall accounts to test group calling.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      20,
                    ),
                    itemCount: _candidates.length,

                    // IMPORTANT:
                    // Do not use (_, _) because both parameters
                    // cannot have the same name.
                    separatorBuilder: (
                      context,
                      index,
                    ) =>
                        const Divider(height: 1),

                    itemBuilder: (context, index) {
                      final user = _candidates[index];

                      final selected =
                          _selected.contains(user.id);

                      final disabled =
                          _sending ||
                          (!selected &&
                              _selected.length >=
                                  maxParticipants);

                      return CheckboxListTile(
                        value: selected,
                        onChanged: disabled
                            ? null
                            : (value) {
                                setState(() {
                                  if (value == true) {
                                    if (_selected.length <
                                        maxParticipants) {
                                      _selected.add(user.id);
                                    }
                                  } else {
                                    _selected.remove(user.id);
                                  }
                                });
                              },
                        title: Text(
                          user.name.isEmpty
                              ? user.zegoId
                              : user.name,
                        ),
                        subtitle: Text(
                          user.online
                              ? user.status == 'busy'
                                  ? 'Busy'
                                  : 'Online'
                              : 'Offline',
                        ),
                        secondary: CircleAvatar(
                          child: Text(
                            user.name.isEmpty
                                ? '?'
                                : user.name
                                    .trim()
                                    .substring(0, 1)
                                    .toUpperCase(),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              24,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: _buildButton(selectedUsers),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    List<UserModel> selectedUsers,
  ) {
    final me = widget.me;

    if (me == null) {
      return FilledButton.icon(
        onPressed: null,
        icon: const Icon(Icons.login_rounded),
        label: const Text(
          'Sign in to start a group call',
        ),
      );
    }

    if (selectedUsers.length < 2) {
      return FilledButton.icon(
        onPressed: null,
        icon: const Icon(Icons.groups_rounded),
        label: Text(
          'Select at least 2 people '
          '(${selectedUsers.length}/$maxParticipants)',
        ),
      );
    }

    if (_sending) {
      return FilledButton.icon(
        onPressed: null,
        icon: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
        label: const Text(
          'Starting group call...',
        ),
      );
    }

    return _buildInvitationButton(
      me,
      selectedUsers,
    );
  }

  Widget _buildInvitationButton(
    UserModel me,
    List<UserModel> selectedUsers,
  ) {
    final invitees = selectedUsers
        .map(
          (user) => ZegoUIKitUser(
            id: _safeZegoId(user.zegoId),
            name: user.name.trim().isEmpty
                ? _safeZegoId(user.zegoId)
                : user.name.trim(),
          ),
        )
        .toList();

    final callId =
        'grp_${_safeZegoId(me.id)}_'
        '${DateTime.now().microsecondsSinceEpoch}';

    return ZegoSendCallInvitationButton(
      invitees: invitees,
      isVideoCall: _video,
      callID: callId,
      customData: _customData(
        me,
        selectedUsers,
      ),
      timeoutSeconds: 60,
      verticalLayout: false,
      iconVisible: false,
      text: _video
          ? 'Start video group call'
          : 'Start audio group call',
      buttonSize: const Size(
        double.infinity,
        54,
      ),
      onWillPressed: () async {
        if (_sending) {
          return false;
        }

        if (selectedUsers.length < 2) {
          return false;
        }

        if (!mounted) {
          return false;
        }

        setState(() {
          _sending = true;
        });

        return true;
      },
      onPressed: (
        code,
        message,
        errorInvitees,
      ) {
        if (!mounted) {
          return;
        }

        if (code == '0') {
          Navigator.of(context).pop();
          return;
        }

        setState(() {
          _sending = false;
        });

        final text = message.trim().isEmpty
            ? 'Unable to start the group call.'
            : message.trim();

        final suffix = errorInvitees.isEmpty
            ? ''
            : ' ${errorInvitees.length} invitee(s) '
              'could not be invited.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$text$suffix'),
          ),
        );
      },
    );
  }

  String _customData(
    UserModel me,
    List<UserModel> selectedUsers,
  ) {
    return Uri(
      scheme: 'connectcall',
      host: 'group-call',
      queryParameters: {
        'callerId': me.id,
        'callType': _video
            ? 'video'
            : 'audio',
        'participants': selectedUsers
            .map((user) => user.id)
            .join(','),
      },
    ).toString();
  }

  String _safeZegoId(String value) {
    final cleaned = value
        .trim()
        .replaceAll(
          RegExp(r'[^A-Za-z0-9_]'),
          '_',
        );

    if (cleaned.isEmpty) {
      return 'user_${DateTime.now().millisecondsSinceEpoch}';
    }

    if (cleaned.length <= 32) {
      return cleaned;
    }

    return cleaned.substring(0, 32);
  }
}

