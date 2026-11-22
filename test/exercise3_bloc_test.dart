import 'package:flutter_test/flutter_test.dart';
import 'package:handle_hero/bloc/exercise3/exercise3_bloc.dart';
import 'package:handle_hero/bloc/exercise3/exercise3_event.dart';
import 'package:handle_hero/models/models.dart';

void main() {
  const letters = [LetterOption('A', 'a.png'), LetterOption('B', 'b.png')];

  test('starts with all configured letters and images', () async {
    final bloc = Exercise3Bloc(letters: letters);
    addTearDown(bloc.close);

    bloc.add(Exercise3Started());
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.shuffledLetters.toSet(), {'A', 'B'});
    expect(bloc.state.shuffledImages.map((item) => item.letter).toSet(), {
      'A',
      'B',
    });
    expect(bloc.state.completed, isEmpty);
  });

  test('matching the selected letter completes it and clears selection',
      () async {
    final bloc = Exercise3Bloc(letters: letters);
    addTearDown(bloc.close);

    bloc.add(Exercise3Started());
    await Future<void>.delayed(Duration.zero);
    bloc.add(Exercise3LetterSelected('A'));
    await Future<void>.delayed(Duration.zero);
    bloc.add(Exercise3ImageTapped('A'));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.completed, contains('A'));
    expect(bloc.state.selectedLetter, isNull);
    expect(bloc.state.lastMatchCorrect, isNull);
  });

  test('wrong match clears selection and exposes incorrect feedback',
      () async {
    final bloc = Exercise3Bloc(letters: letters);
    addTearDown(bloc.close);

    bloc.add(Exercise3Started());
    await Future<void>.delayed(Duration.zero);
    bloc.add(Exercise3LetterSelected('A'));
    await Future<void>.delayed(Duration.zero);
    bloc.add(Exercise3ImageTapped('B'));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.completed, isEmpty);
    expect(bloc.state.selectedLetter, isNull);
    expect(bloc.state.lastMatchCorrect, isFalse);
  });
}
