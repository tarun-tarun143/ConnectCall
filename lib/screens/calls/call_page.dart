import 'package:flutter/material.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../../core/config/app_config.dart';
import '../../models/user_model.dart';

class CallPage extends StatefulWidget {
  const CallPage({
    super.key,
    required this.callId,
    required this.me,
    required this.video,
    this.remote,
  });

  final String callId;
  final UserModel me;
  final bool video;
  final UserModel? remote;

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Start the call with speaker output enabled.
      ZegoUIKit().setAudioOutputToSpeaker(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ZegoUIKitPrebuiltCallConfig config = widget.video
        ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
        : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();

    // Audio
    config.turnOnMicrophoneWhenJoining = true;
    config.useSpeakerWhenJoining = true;

    // Camera
    config.turnOnCameraWhenJoining = widget.video;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ZegoUIKitPrebuiltCall(
          appID: AppConfig.zegoAppId,
          appSign: AppConfig.zegoAppSign,
          callID: widget.callId,
          userID: _safeZegoUserId(widget.me.zegoId),
          userName: _safeUserName(widget.me),
          config: config,
          events: ZegoUIKitPrebuiltCallEvents(
            onCallEnd: (event, defaultAction) {
              defaultAction.call();

              if (context.mounted &&
                  Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
      ),
    );
  }

  String _safeZegoUserId(String value) {
    final cleaned = value
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');

    if (cleaned.isEmpty) {
      return 'user_${DateTime.now().millisecondsSinceEpoch}';
    }

    if (cleaned.length <= 32) {
      return cleaned;
    }

    return cleaned.substring(0, 32);
  }

  String _safeUserName(UserModel user) {
    final name = user.name.trim();

    if (name.isNotEmpty) {
      return name;
    }

    final zegoId = user.zegoId.trim();

    if (zegoId.isNotEmpty) {
      return zegoId;
    }

    return 'User';
  }
}