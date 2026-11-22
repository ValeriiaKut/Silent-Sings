import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:handle_hero/bloc/mixed_challenge/mixed_challenge_event.dart';
import 'package:handle_hero/bloc/mixed_challenge/mixed_challenge_state.dart';
import 'package:handle_hero/data/module_catalog.dart';
import 'package:handle_hero/models/models.dart';

class MixedChallengeBloc
    extends Bloc<MixedChallengeEvent, MixedChallengeState> {
  MixedChallengeBloc({
    required this.moduleIndex,
    Random? random,
    List<LetterOption>? letters,
  }) : _random = random ?? Random(),
       _moduleLetters = letters ?? ModuleCatalog.lettersFor(moduleIndex),
       super(MixedChallengeState.initial) {
    on<MixedChallengeStarted>(_onStarted);
    on<MixedChallengeAnswerSelected>(_onAnswerSelected);
    on<MixedChallengePairLetterSelected>(_onPairLetterSelected);
    on<MixedChallengePairImageSelected>(_onPairImageSelected);
    on<MixedChallengeRetry>(_onRetry);
  }

  final int moduleIndex;
  final Random _random;
  final List<LetterOption> _moduleLetters;
  static const _tasksPerActivity = 4;
  bool _resetPairsAfterRetry = false;

  void _onStarted(
    MixedChallengeStarted event,
    Emitter<MixedChallengeState> emit,
  ) {
    if (_moduleLetters.isEmpty) return;
    final letters = _shuffled([..._moduleLetters]);
    final tasks = _buildTasks(letters);
    emit(_prepareTask(tasks, 0));
  }

  List<MixedChallengeTask> _buildTasks(List<LetterOption> letters) {
    final activities = MixedChallengeActivity.values;
    final counts = {for (final activity in activities) activity: 0};
    final tasks = <MixedChallengeTask>[];

    for (final letter in _shuffled([...letters])) {
      final available = activities
          .where((activity) => counts[activity]! < _tasksPerActivity)
          .toList();
      if (available.isEmpty) break;
      final activity = available[_random.nextInt(available.length)];
      tasks.add(MixedChallengeTask(activity, letter));
      counts[activity] = counts[activity]! + 1;
    }

    while (tasks.length < activities.length * _tasksPerActivity) {
      final available = activities
          .where((activity) => counts[activity]! < _tasksPerActivity)
          .toList();
      final activity = available[_random.nextInt(available.length)];
      tasks.add(
        MixedChallengeTask(activity, letters[_random.nextInt(letters.length)]),
      );
      counts[activity] = counts[activity]! + 1;
    }
    return _shuffled(tasks);
  }

  MixedChallengeState _prepareTask(List<MixedChallengeTask> tasks, int index) {
    final task = tasks[index];
    final target = task.letter;
    final distractors = _shuffled(
      _moduleLetters.where((item) => item.letter != target.letter).toList(),
    );
    final nameChoices = task.activity == MixedChallengeActivity.nameSign
        ? _moduleLetters.map((item) => item.letter).toList()
        : tasks.map((item) => item.letter.letter).toSet().toList();
    final pairOptions = [
      target,
      ..._shuffled(
        _moduleLetters.where((item) => item.letter != target.letter).toList(),
      ).take(2),
    ];
    final sentenceChoices = [target, ...distractors.take(3)];

    return MixedChallengeState(
      tasks: tasks,
      taskIndex: index,
      letterChoices: _shuffled(nameChoices),
      imageChoices: _shuffled([target, ...distractors.take(5)]),
      sentenceImageChoices: _shuffled(sentenceChoices),
      pairLetters: _shuffled(pairOptions.map((item) => item.letter).toList()),
      pairImages: _shuffled(pairOptions),
      matchedLetters: const {},
      isReady: true,
    );
  }

  void _onAnswerSelected(
    MixedChallengeAnswerSelected event,
    Emitter<MixedChallengeState> emit,
  ) {
    final task = state.currentTask;
    if (task == null || state.isComplete) return;
    if (event.letter == task.letter.letter) {
      _advance(emit);
    } else {
      _markWrong(emit);
    }
  }

  void _onPairLetterSelected(
    MixedChallengePairLetterSelected event,
    Emitter<MixedChallengeState> emit,
  ) {
    if (!state.pairLetters.contains(event.letter) ||
        state.matchedLetters.contains(event.letter) ||
        state.isComplete) {
      return;
    }
    emit(state.copyWith(selectedPairLetter: event.letter));
  }

  void _onPairImageSelected(
    MixedChallengePairImageSelected event,
    Emitter<MixedChallengeState> emit,
  ) {
    final selected = state.selectedPairLetter;
    if (selected == null ||
        state.matchedLetters.contains(event.option.letter) ||
        state.isComplete) {
      return;
    }
    if (selected != event.option.letter) {
      _resetPairsAfterRetry = true;
      _markWrong(emit);
      return;
    }

    final matched = {...state.matchedLetters, selected};
    if (matched.length == state.pairLetters.length) {
      _advance(emit);
      return;
    }
    emit(
      state.copyWith(matchedLetters: matched, clearSelectedPairLetter: true),
    );
  }

  void _onRetry(MixedChallengeRetry event, Emitter<MixedChallengeState> emit) {
    emit(
      state.copyWith(
        matchedLetters: _resetPairsAfterRetry ? const {} : state.matchedLetters,
        clearSelectedPairLetter: true,
      ),
    );
    _resetPairsAfterRetry = false;
  }

  void _markWrong(Emitter<MixedChallengeState> emit) {
    emit(state.copyWith(wrongAnswerVersion: state.wrongAnswerVersion + 1));
  }

  void _advance(Emitter<MixedChallengeState> emit) {
    if (state.taskIndex == state.tasks.length - 1) {
      emit(state.copyWith(isComplete: true, clearSelectedPairLetter: true));
      return;
    }
    emit(_prepareTask(state.tasks, state.taskIndex + 1));
  }

  List<T> _shuffled<T>(List<T> values) => values..shuffle(_random);
}
