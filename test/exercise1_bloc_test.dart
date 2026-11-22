import 'package:flutter_test/flutter_test.dart';
import 'package:handle_hero/bloc/exercise1/exercise1_bloc.dart';
import 'package:handle_hero/bloc/exercise1/exercise1_event.dart';
import 'package:handle_hero/models/models.dart';

void main() {
  const letter = LetterOption('A', 'assets/images/A.png');

  test('starts with the configured question', () async {
    final bloc = Exercise1Bloc(letters: const [letter]);
    addTearDown(bloc.close);

    bloc.add(Exercise1Started());
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.correctAnswer, 'A');
    expect(bloc.state.currentImage, 'assets/images/A.png');
    expect(bloc.state.questionIndex, 0);
    expect(bloc.state.totalQuestions, 1);
    expect(bloc.state.hasFeedback, isFalse);
  });

  test('records correct and incorrect answers as feedback', () async {
    final bloc = Exercise1Bloc(letters: const [letter]);
    addTearDown(bloc.close);

    bloc.add(Exercise1Started());
    await Future<void>.delayed(Duration.zero);
    bloc.add(Exercise1AnswerSelected('wrong'));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.isCorrect, isFalse);

    bloc.add(Exercise1FeedbackCleared());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.hasFeedback, isFalse);

    bloc.add(Exercise1AnswerSelected('A'));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.isCorrect, isTrue);
  });

  test('challenge mode advances only after a correct answer', () async {
    final bloc = Exercise1Bloc(
      letters: const [letter, LetterOption('B', 'assets/images/B.png')],
      challengeMode: true,
    );
    addTearDown(bloc.close);

    bloc.add(Exercise1Started());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.totalQuestions, 2);

    final firstAnswer = bloc.state.correctAnswer;
    bloc.add(Exercise1AnswerSelected('wrong'));
    await Future<void>.delayed(Duration.zero);
    bloc.add(Exercise1NextQuestion());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.questionIndex, 0);

    bloc.add(Exercise1FeedbackCleared());
    await Future<void>.delayed(Duration.zero);
    bloc.add(Exercise1AnswerSelected(firstAnswer));
    await Future<void>.delayed(Duration.zero);
    bloc.add(Exercise1NextQuestion());
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.questionIndex, 1);
    expect(bloc.state.correctAnswer, isNot(firstAnswer));
    expect(bloc.state.hasFeedback, isFalse);
  });
}
