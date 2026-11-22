import 'package:handle_hero/models/models.dart';

sealed class MixedChallengeEvent {}

final class MixedChallengeStarted extends MixedChallengeEvent {}

final class MixedChallengeAnswerSelected extends MixedChallengeEvent {
  MixedChallengeAnswerSelected(this.letter);

  final String letter;
}

final class MixedChallengePairLetterSelected extends MixedChallengeEvent {
  MixedChallengePairLetterSelected(this.letter);

  final String letter;
}

final class MixedChallengePairImageSelected extends MixedChallengeEvent {
  MixedChallengePairImageSelected(this.option);

  final LetterOption option;
}

final class MixedChallengeRetry extends MixedChallengeEvent {}
