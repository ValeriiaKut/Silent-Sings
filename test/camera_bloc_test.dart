import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hand_detection/hand_detection.dart' as hand;
import 'package:handle_hero/bloc/camera/camera_bloc.dart';
import 'package:handle_hero/bloc/camera/camera_event.dart';
import 'package:handle_hero/data/camera_service.dart';

class _FakeCameraService implements CameraServiceContract {
  bool failInitialization = false;
  bool switchable = true;
  bool frontCamera = false;
  bool classifierReady = true;
  String? classifierFailure;
  int pauses = 0;
  int initializations = 0;
  int switches = 0;
  int resumes = 0;
  int disposals = 0;
  XFile? capturedPhoto;

  @override
  CameraController? get controller => null;

  @override
  bool get canSwitchCamera => switchable;

  @override
  bool get isClassifierReady => classifierReady;

  @override
  String? get classifierError => classifierFailure;

  @override
  bool get isFrontCamera => frontCamera;

  @override
  Future<void> initialize({
    required void Function(List<hand.Hand>, Size, String?) onHands,
  }) async {
    initializations++;
    if (failInitialization) {
      throw CameraException('CameraAccessDenied', 'Camera permission denied.');
    }
  }

  @override
  Future<void> switchCamera({
    required void Function(List<hand.Hand>, Size, String?) onHands,
  }) async {
    switches++;
    frontCamera = !frontCamera;
  }

  @override
  Future<XFile?> capture() async => capturedPhoto;

  @override
  Future<void> resumeDetection({
    required void Function(List<hand.Hand>, Size, String?) onHands,
  }) async {
    resumes++;
  }

  @override
  Future<void> pause() async {
    pauses++;
  }

  @override
  Future<void> dispose() async {
    disposals++;
  }
}

void main() {
  test('limits challenge size and initializes camera state', () async {
    final service = _FakeCameraService();
    final bloc = CameraBloc(service, challengeIndex: 0);
    addTearDown(bloc.close);

    expect(bloc.state.challengeLetters, hasLength(5));
    expect(bloc.state.challengeLetters.toSet().length, 5);
    expect(bloc.state.challengeLetters.every('ABCDEFGHI'.contains), isTrue);

    final ready = bloc.stream.firstWhere((state) => state.isCameraReady);
    bloc.add(CameraStarted());
    await ready;

    expect(bloc.state.isLoading, isFalse);
    expect(bloc.state.isClassifierReady, isTrue);
    expect(service.pauses, 1);
    expect(service.initializations, 1);
  });

  test('reports denied camera permission and allows retry', () async {
    final service = _FakeCameraService()..failInitialization = true;
    final bloc = CameraBloc(service, challengeIndex: 1);
    addTearDown(bloc.close);

    final denied = bloc.stream.firstWhere((state) => state.error != null);
    bloc.add(CameraStarted());
    await denied;
    expect(bloc.state.error, 'Allow camera access to use this screen.');
    expect(bloc.state.isCameraReady, isFalse);
    expect(bloc.state.isLoading, isFalse);

    service.failInitialization = false;
    final ready = bloc.stream.firstWhere((state) => state.isCameraReady);
    bloc.add(CameraRetryRequested());
    await ready;
    expect(bloc.state.error, isNull);
  });

  test('switches cameras only when the service supports switching', () async {
    final service = _FakeCameraService();
    final bloc = CameraBloc(service, challengeIndex: 2);
    addTearDown(bloc.close);
    final ready = bloc.stream.firstWhere((state) => state.isCameraReady);
    bloc.add(CameraStarted());
    await ready;

    final switched = bloc.stream.firstWhere(
      (state) => !state.isLoading && state.isFrontCamera,
    );
    bloc.add(CameraSwitchRequested());
    await switched;
    expect(service.switches, 1);

    service.switchable = false;
    bloc.add(CameraSwitchRequested());
    await Future<void>.delayed(Duration.zero);
    expect(service.switches, 1);
  });

  test('captures, retakes, and disposes through the service', () async {
    final service = _FakeCameraService()..capturedPhoto = XFile('photo.jpg');
    final bloc = CameraBloc(service, challengeIndex: 0);
    addTearDown(bloc.close);
    final ready = bloc.stream.firstWhere((state) => state.isCameraReady);
    bloc.add(CameraStarted());
    await ready;

    final captured = bloc.stream.firstWhere((state) => state.photo != null);
    bloc.add(CameraCaptureRequested());
    await captured;
    expect(bloc.state.photo?.path, 'photo.jpg');

    final retaken = bloc.stream.firstWhere((state) => state.photo == null);
    bloc.add(CameraRetakeRequested());
    await retaken;
    expect(service.resumes, 1);
  });
}
