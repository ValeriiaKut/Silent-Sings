import 'package:flutter_test/flutter_test.dart';
import 'package:handle_hero/bloc/level/level_bloc.dart';
import 'package:handle_hero/bloc/level/level_event.dart';
import 'package:handle_hero/bloc/level/level_state.dart';

Future<void> _send(LevelBloc bloc, LevelEvent event) async {
  final nextState = bloc.stream.first;
  bloc.add(event);
  await nextState;
}

void main() {
  test('starts with three lives and no mistakes', () async {
    final bloc = LevelBloc();
    addTearDown(bloc.close);

    expect(bloc.state.lives, LevelState.defaultLives);
    expect(bloc.state.mistakes, 0);
    expect(bloc.state.isOutOfLives, isFalse);
  });

  test('loses lives, records mistakes, and restores lives', () async {
    final bloc = LevelBloc();
    addTearDown(bloc.close);

    await _send(bloc, LifeLost());
    expect(bloc.state.lives, 2);
    expect(bloc.state.mistakes, 1);

    await _send(bloc, LivesRestored());
    expect(bloc.state.lives, LevelState.defaultLives);
    expect(bloc.state.mistakes, 1);
  });

  test('does not allow lives below zero and resets a new level', () async {
    final bloc = LevelBloc();
    addTearDown(bloc.close);

    await _send(bloc, LifeLost());
    await _send(bloc, LifeLost());
    await _send(bloc, LifeLost());
    expect(bloc.state.lives, 0);
    expect(bloc.state.isOutOfLives, isTrue);

    await _send(bloc, LevelStarted());
    expect(bloc.state.lives, LevelState.defaultLives);
    expect(bloc.state.mistakes, 0);
  });
}
