import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

import '../core/config/app_config.dart';
import '../core/utils/zego_ids.dart';
import '../models/call_model.dart';
import 'call_service.dart';

class ZegoService {
  ZegoService({required CallService callService})
      : _callService = callService;

  final CallService _callService;
  final Set<String> _initialisedUsers = <String>{};
  bool _initialising = false;

  ZegoUIKitPrebuiltCallInvitationService get _invitationService =>
      ZegoUIKitPrebuiltCallInvitationService();

  Future<void> initialiseForUser({
    required String uid,
    required String name,
  }) async {
    if (!AppConfig.hasZegoConfig) {
      debugPrint('ConnectCall: ZEGOCLOUD is not configured.');
      return;
    }

    final safeUid = ZegoIds.fromFirebaseUid(uid);

    if (_initialisedUsers.contains(safeUid) || _initialising) {
      return;
    }

    _initialising = true;

    try {
      await _invitationService.init(
        appID: AppConfig.zegoAppId,
        appSign: AppConfig.zegoAppSign,
        userID: safeUid,
        userName: name.trim().isEmpty ? safeUid : name.trim(),
        plugins: <IZegoUIKitPlugin>[ZegoUIKitSignalingPlugin()],
        config: ZegoCallInvitationConfig(
          permissions: const [
            ZegoCallInvitationPermission.camera,
            ZegoCallInvitationPermission.microphone,
          ],
          missedCall: ZegoCallInvitationMissedCallConfig(
            enabled: true,
            enableDialBack: true,
            timeoutSeconds: 60,
          ),
          inCalling: ZegoCallInvitationInCallingConfig(
            canInvitingInCalling: true,
            onlyInitiatorCanInvite: false,
          ),
        ),
       requireConfig: (data) {
  final ZegoUIKitPrebuiltCallConfig config;

  if (data.invitees.length > 1) {
    config = data.type == ZegoCallInvitationType.videoCall
        ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
        : ZegoUIKitPrebuiltCallConfig.groupVoiceCall();
  } else {
    config = data.type == ZegoCallInvitationType.videoCall
        ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
        : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();
  }

  // Audio
  config.turnOnMicrophoneWhenJoining = true;
  config.useSpeakerWhenJoining = true;

  // Camera
  config.turnOnCameraWhenJoining =
      data.type == ZegoCallInvitationType.videoCall;

  return config;
},
        invitationEvents: ZegoUIKitPrebuiltCallInvitationEvents(
          onIncomingCallReceived: (
            callID,
            caller,
            callType,
            callees,
            customData,
          ) async {
            await _registerIncoming(
              callID: callID,
              caller: caller,
              callType: callType,
              callees: callees,
              customData: customData,
              currentUid: uid,
              currentName: name,
            );
          },
          onOutgoingCallSent: (
            callID,
            caller,
            callType,
            callees,
            customData,
          ) async {
            await _registerOutgoing(
              callID: callID,
              callType: callType,
              callees: callees,
              customData: customData,
              currentUid: uid,
              currentName: name,
            );
          },
          onOutgoingCallAccepted: (callID, callee) async {
            await _safeSetStatus(
              callID,
              CallStatus.connected,
            );
          },
          onOutgoingCallDeclined: (
            callID,
            callee,
            customData,
          ) async {
            await _safeSetStatus(
              callID,
              CallStatus.rejected,
            );
          },
          onOutgoingCallRejectedCauseBusy: (
            callID,
            callee,
            customData,
          ) async {
            await _safeSetStatus(
              callID,
              CallStatus.busy,
            );
          },
          onOutgoingCallTimeout: (
            callID,
            callees,
            isVideoCall,
          ) async {
            await _safeSetStatus(
              callID,
              CallStatus.missed,
            );
          },
          onIncomingCallTimeout: (callID, caller) async {
            await _safeSetStatus(
              callID,
              CallStatus.missed,
            );
          },
          onIncomingCallCanceled: (
            callID,
            caller,
            customData,
          ) async {
            await _safeSetStatus(
              callID,
              CallStatus.ended,
            );
          },
        ),
        events: ZegoUIKitPrebuiltCallEvents(
          onCallEnd: (event, defaultAction) {
            defaultAction.call();
          },
        ),
      );

      _initialisedUsers.add(safeUid);
    } catch (error, stackTrace) {
      _logError(
        'ZEGOCLOUD initialization failed',
        error,
        stackTrace,
      );
      rethrow;
    } finally {
      _initialising = false;
    }
  }

  Future<void> _registerIncoming({
    required String callID,
    required ZegoCallUser caller,
    required ZegoCallInvitationType callType,
    required List<ZegoCallUser> callees,
    required String customData,
    required String currentUid,
    required String currentName,
  }) async {
    final payload = _decodeCustomData(customData);
    final callerId = _stringValue(payload['callerId']) ?? caller.id;
    final type = _resolveCallType(
      callType: callType,
      participantCount: callees.length,
    );

    try {
      await _callService.registerIncoming(
        callId: callID,
        callerId: callerId,
        calleeId: currentUid,
        callerName: caller.name,
        calleeName: currentName,
        type: type,
      );
    } catch (error, stackTrace) {
      _logError(
        'Incoming call history write failed',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _registerOutgoing({
    required String callID,
    required ZegoCallInvitationType callType,
    required List<ZegoCallUser> callees,
    required String customData,
    required String currentUid,
    required String currentName,
  }) async {
    if (callees.isEmpty) return;

    final payload = _decodeCustomData(customData);
    final first = callees.first;
    final calleeId = _stringValue(payload['calleeId']) ?? first.id;
    final callerId = _stringValue(payload['callerId']) ?? currentUid;
    final type = _resolveCallType(
      callType: callType,
      participantCount: callees.length,
    );

    try {
      await _callService.createOutgoing(
        callId: callID,
        callerId: callerId,
        calleeId: calleeId,
        callerName: currentName,
        calleeName: first.name,
        type: type,
      );
    } catch (error, stackTrace) {
      _logError(
        'Outgoing call history write failed',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _safeSetStatus(
    String callID,
    CallStatus status,
  ) async {
    try {
      await _callService.setStatus(
        callID,
        status,
      );
    } catch (error, stackTrace) {
      _logError(
        'Call status update failed',
        error,
        stackTrace,
      );
    }
  }

  CallType _resolveCallType({
    required ZegoCallInvitationType callType,
    required int participantCount,
  }) {
    if (participantCount > 1) {
      return CallType.group;
    }

    if (callType == ZegoCallInvitationType.videoCall) {
      return CallType.video;
    }

    return CallType.audio;
  }

  Future<void> uninitialise() async {
    try {
      await _invitationService.uninit();
    } catch (error, stackTrace) {
      _logError(
        'ZEGOCLOUD uninitialization failed',
        error,
        stackTrace,
      );
    } finally {
      _initialisedUsers.clear();
      _initialising = false;
    }
  }

  static Map<String, dynamic> _decodeCustomData(
    String customData,
  ) {
    if (customData.trim().isEmpty) {
      return const <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(customData);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return decoded.map(
          (key, value) => MapEntry(
            key.toString(),
            value,
          ),
        );
      }
    } catch (error) {
      debugPrint(
        'ConnectCall: invalid ZEGOCLOUD custom data: $error',
      );
    }

    return const <String, dynamic>{};
  }

  static String? _stringValue(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return null;
  }
  
  static void _logError(
    String message,
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint('ConnectCall: $message: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

class CallInvitationButton extends StatelessWidget {
  const CallInvitationButton({
    super.key,
    required this.user,
    required this.isVideo,
    required this.callId,
    this.onPressed,
    this.beforeCall,
    this.customData = '',
  });

  final ZegoUIKitUser user;
  final bool isVideo;
  final String callId;
  final VoidCallback? onPressed;
  final Future<bool> Function()? beforeCall;
  final String customData;

  @override
  Widget build(BuildContext context) {
    return ZegoSendCallInvitationButton(
      invitees: <ZegoUIKitUser>[user],
      isVideoCall: isVideo,
      callID: callId,
      customData: customData,
      timeoutSeconds: 60,
      notificationTitle:
          isVideo ? 'Incoming video call' : 'Incoming audio call',
      notificationMessage:
          'You have an incoming ConnectCall call.',
      iconVisible: true,
      verticalLayout: false,
      buttonSize: const Size(42, 42),
      iconSize: const Size(22, 22),
      onWillPressed: () async {
        try {
          final allowed = await beforeCall?.call() ?? true;
          if (allowed) {
            onPressed?.call();
          }
          return allowed;
        } catch (error, stackTrace) {
          debugPrint(
            'ConnectCall: call invitation validation failed: $error',
          );
          debugPrintStack(stackTrace: stackTrace);
          return false;
        }
      },
    );
  }
}
