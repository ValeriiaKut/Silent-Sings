import 'package:flutter_test/flutter_test.dart';
import 'package:handle_hero/bloc/mixed_challenge/mixed_challenge_bloc.dart';
import 'package:handle_hero/bloc/mixed_challenge/mixed_challenge_event.dart';
import 'package:handle_hero/bloc/mixed_challenge/mixed_challenge_state.dart';
import 'package:handle_hero/models/models.dart';

Future<void> _send(MixedChallengeBloc bloc, MixedChallengeEvent event) async {
  final nextState = bloc.stream.first;
  bloc.add(event);
  await nextState;
}

void main() {
  const letters = [
    LetterOption('A', 'a.png'),
    LetterOption('B', 'b.png'),
    LetterOption('C', 'c.png'),
  ];

  test('builds a balanced challenge containing all module letters', () async {
    final bloc = MixedChallengeBloc(moduleIndex: 3, letters: letters);
    addTearDown(bloc.close);

    await _send(bloc, MixedChallengeStarted());

    expect(bloc.state.tasks, hasLength(16));
    for (final activity in MixedChallengeActivity.values) {
      expect(
        bloc.state.tasks.where((task) => task.activity == activity),
        hasLength(4),
      );
    }
    expect(bloc.state.tasks.map((task) => task.letter.letter).toSet(), {
      'A',
      'B',
      'C',
    });
    expect(bloc.state.currentTask, isNotNull);
  });

  test(
    'wrong answers keep the current task and correct answers advance',
    () async {
      final bloc = MixedChallengeBloc(moduleIndex: 3, letters: letters);
      addTearDown(bloc.close);
      await _send(bloc, MixedChallengeStarted());

      final initialIndex = bloc.state.taskIndex;
      final target = bloc.state.currentTask!.letter.letter;
      final wrong = letters.firstWhere((letter) => letter.letter != target);
      await _send(bloc, MixedChallengeAnswerSelected(wrong.letter));

      expect(bloc.state.taskIndex, initialIndex);
      expect(bloc.state.wrongAnswerVersion, 1);

      await _send(bloc, MixedChallengeAnswerSelected(target));
      expect(bloc.state.taskIndex, initialIndex + 1);
      expect(bloc.state.wrongAnswerVersion, 1);
    },
  );

  test(
    'finishes after the final correct answer and ignores later answers',
    () async {
      final bloc = MixedChallengeBloc(moduleIndex: 3, letters: letters);
      addTearDown(bloc.close);
      await _send(bloc, MixedChallengeStarted());

      while (!bloc.state.isComplete) {
        final task = bloc.state.currentTask!;
        if (task.activity == MixedChallengeActivity.matchPair) {
          for (final letter in bloc.state.pairLetters.toList()) {
            await _send(bloc, MixedChallengePairLetterSelected(letter));
            final image = bloc.state.pairImages.firstWhere(
              (option) => option.letter == letter,
            );
            await _send(bloc, MixedChallengePairImageSelected(image));
          }
        } else {
          await _send(bloc, MixedChallengeAnswerSelected(task.letter.letter));
        }
      }

      expect(bloc.state.isComplete, isTrue);
      expect(bloc.state.taskIndex, bloc.state.tasks.length - 1);
      final completedIndex = bloc.state.taskIndex;
      await _send(bloc, MixedChallengeAnswerSelected('A'));
      expect(bloc.state.taskIndex, completedIndex);
      expect(bloc.state.isComplete, isTrue);
    },
  );

  test(
    'pair selection completes matches and retry clears a wrong pairing',
    () async {
      final bloc = MixedChallengeBloc(moduleIndex: 3, letters: letters);
      addTearDown(bloc.close);
      await _send(bloc, MixedChallengeStarted());

      while (bloc.state.currentTask!.activity !=
          MixedChallengeActivity.matchPair) {
        final target = bloc.state.currentTask!.letter.letter;
        await _send(bloc, MixedChallengeAnswerSelected(target));
      }

      final initialIndex = bloc.state.taskIndex;
      final target = bloc.state.currentTask!.letter.letter;
      final otherLetter = bloc.state.pairLetters.firstWhere(
        (letter) => letter != target,
      );
      final targetImage = bloc.state.pairImages.firstWhere(
        (option) => option.letter == target,
      );

      await _send(bloc, MixedChallengePairLetterSelected(otherLetter));
      await _send(bloc, MixedChallengePairImageSelected(targetImage));
      expect(bloc.state.wrongAnswerVersion, 1);
      expect(bloc.state.taskIndex, initialIndex);

      await _send(bloc, MixedChallengeRetry());
      expect(bloc.state.selectedPairLetter, isNull);
      expect(bloc.state.matchedLetters, isEmpty);

      await _send(bloc, MixedChallengePairLetterSelected(target));
      await _send(bloc, MixedChallengePairImageSelected(targetImage));
      expect(bloc.state.matchedLetters, hasLength(1));
      expect(bloc.state.selectedPairLetter, isNull);
    },
  );
}
