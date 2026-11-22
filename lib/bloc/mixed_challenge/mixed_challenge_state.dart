import 'package:handle_hero/data/sentence_activities.dart';
import 'package:handle_hero/models/models.dart';

enum MixedChallengeActivity { nameSign, findSign, matchPair, sentence }

class MixedChallengeTask {
  const MixedChallengeTask(this.activity, this.letter);

  final MixedChallengeActivity activity;
  final LetterOption letter;
}

class MixedChallengeState {
  const MixedChallengeState({
    required this.tasks,
    required this.letterChoices,
    required this.imageChoices,
    required this.sentenceImageChoices,
    required this.pairLetters,
    required this.pairImages,
    required this.matchedLetters,
    this.taskIndex = 0,
    this.selectedPairLetter,
    this.isComplete = false,
    this.wrongAnswerVersion = 0,
    this.isReady = false,
  });

  final List<MixedChallengeTask> tasks;
  final int taskIndex;
  final List<String> letterChoices;
  final List<LetterOption> imageChoices;
  final List<LetterOption> sentenceImageChoices;
  final List<String> pairLetters;
  final List<LetterOption> pairImages;
  final Set<String> matchedLetters;
  final String? selectedPairLetter;
  final bool isComplete;
  final int wrongAnswerVersion;
  final bool isReady;

  MixedChallengeTask? get currentTask =>
      isReady && taskIndex < tasks.length ? tasks[taskIndex] : null;

  SentencePrompt? get currentSentence {
    final task = currentTask;
    if (task == null) return null;
    final prompts = SentenceActivities.forLetters([task.letter]);
    return prompts.isEmpty ? null : prompts.first;
  }

  MixedChallengeState copyWith({
    List<MixedChallengeTask>? tasks,
    int? taskIndex,
    List<String>? letterChoices,
    List<LetterOption>? imageChoices,
    List<LetterOption>? sentenceImageChoices,
    List<String>? pairLetters,
    List<LetterOption>? pairImages,
    Set<String>? matchedLetters,
    String? selectedPairLetter,
    bool clearSelectedPairLetter = false,
    bool? isComplete,
    int? wrongAnswerVersion,
    bool? isReady,
  }) => MixedChallengeState(
    tasks: tasks ?? this.tasks,
    taskIndex: taskIndex ?? this.taskIndex,
    letterChoices: letterChoices ?? this.letterChoices,
    imageChoices: imageChoices ?? this.imageChoices,
    sentenceImageChoices: sentenceImageChoices ?? this.sentenceImageChoices,
    pairLetters: pairLetters ?? this.pairLetters,
    pairImages: pairImages ?? this.pairImages,
    matchedLetters: matchedLetters ?? this.matchedLetters,
    selectedPairLetter: clearSelectedPairLetter
        ? null
        : selectedPairLetter ?? this.selectedPairLetter,
    isComplete: isComplete ?? this.isComplete,
    wrongAnswerVersion: wrongAnswerVersion ?? this.wrongAnswerVersion,
    isReady: isReady ?? this.isReady,
  );

  static const initial = MixedChallengeState(
    tasks: [],
    letterChoices: [],
    imageChoices: [],
    sentenceImageChoices: [],
    pairLetters: [],
    pairImages: [],
    matchedLetters: {},
  );
}
