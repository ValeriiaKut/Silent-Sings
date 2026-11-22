import 'package:flutter_test/flutter_test.dart';
import 'package:handle_hero/bloc/exercise2/exercise2_bloc.dart';
import 'package:handle_hero/bloc/exercise2/exercise2_event.dart';
import 'package:handle_hero/models/models.dart';

void main() {
  const letters = [LetterOption('A', 'a.png'), LetterOption('B', 'b.png')];

  test('starts with one configured target in regular mode', () async {
    final bloc = Exercise2Bloc(letters: const [LetterOption('A', 'a.png')]);
    addTearDown(bloc.close);

    bloc.add(Exercise2Started());
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.targetLetter, 'A');
    expect(bloc.state.totalQuestions, 1);
    expect(bloc.state.hasFeedback, isFalse);
  });

  test('challenge contains all letters and advances after a correct answer',
      () async {
    final bloc = Exercise2Bloc(letters: letters, challengeMode: true);
    addTearDown(bloc.close);

    bloc.add(Exercise2Started());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.totalQuestions, 2);

    final firstTarget = bloc.state.targetLetter;
    bloc.add(Exercise2AnswerSelected(firstTarget));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.isCorrect, isTrue);

    bloc.add(Exercise2NextQuestion());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.questionIndex, 1);
    expect(bloc.state.targetLetter, isNot(firstTarget));
    expect(bloc.state.hasFeedback, isFalse);
  });

  test('cannot advance after a wrong answer', () async {
    final bloc = Exercise2Bloc(letters: const [LetterOption('A', 'a.png')]);
    addTearDown(bloc.close);

    bloc.add(Exercise2Started());
    await Future<void>.delayed(Duration.zero);
    bloc.add(Exercise2AnswerSelected('wrong'));
    await Future<void>.delayed(Duration.zero);
    bloc.add(Exercise2NextQuestion());
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.isCorrect, isFalse);
    expect(bloc.state.questionIndex, 0);
  });
}
