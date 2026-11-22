import 'package:flutter_test/flutter_test.dart';
import 'package:handle_hero/bloc/exercise4/exercise4_bloc.dart';
import 'package:handle_hero/bloc/exercise4/exercise4_event.dart';
import 'package:handle_hero/models/models.dart';

void main() {
  const letters = [LetterOption('A', 'a.png'), LetterOption('B', 'b.png')];

  test('starts with activities and choices for configured letters', () async {
    final bloc = Exercise4Bloc(letters: letters);
    addTearDown(bloc.close);

    bloc.add(Exercise4Started());
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.hasQuestions, isTrue);
    expect(bloc.state.choices.toSet(), {'A', 'B'});
    expect(bloc.state.questions.map((question) => question.letter).toSet(), {
      'A',
      'B',
    });
  });

  test('marks a correct answer and advances to the next prompt', () async {
    final bloc = Exercise4Bloc(letters: letters);
    addTearDown(bloc.close);

    bloc.add(Exercise4Started());
    await Future<void>.delayed(Duration.zero);
    final currentLetter = bloc.state.currentQuestion!.letter;
    bloc.add(Exercise4AnswerSelected(currentLetter));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.isCorrect, isTrue);

    bloc.add(Exercise4NextQuestion());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.questionIndex, 1);
    expect(bloc.state.hasFeedback, isFalse);
  });

  test('does not advance after an incorrect answer', () async {
    final bloc = Exercise4Bloc(
      letters: const [LetterOption('A', 'a.png')],
    );
    addTearDown(bloc.close);

    bloc.add(Exercise4Started());
    await Future<void>.delayed(Duration.zero);
    bloc.add(Exercise4AnswerSelected('wrong'));
    await Future<void>.delayed(Duration.zero);
    bloc.add(Exercise4NextQuestion());
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.isCorrect, isFalse);
    expect(bloc.state.questionIndex, 0);
  });
}
