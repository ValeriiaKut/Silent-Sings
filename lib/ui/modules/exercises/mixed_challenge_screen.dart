import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:handle_hero/bloc/mixed_challenge/mixed_challenge_bloc.dart';
import 'package:handle_hero/bloc/mixed_challenge/mixed_challenge_event.dart';
import 'package:handle_hero/bloc/mixed_challenge/mixed_challenge_state.dart';
import 'package:handle_hero/bloc/home/home_bloc.dart';
import 'package:handle_hero/bloc/home/home_event.dart';
import 'package:handle_hero/bloc/level/level_bloc.dart';
import 'package:handle_hero/bloc/level/level_state.dart';
import 'package:handle_hero/data/sentence_activities.dart';
import 'package:handle_hero/models/models.dart';
import 'package:handle_hero/ui/modules/overview/level_overview_screen.dart';
import 'package:handle_hero/utils/my_images.dart';
import 'package:handle_hero/widgets/letter_sign.dart';
import 'package:handle_hero/widgets/letter_glyph.dart';
import 'package:handle_hero/widgets/lives_bar.dart';
import 'package:handle_hero/widgets/module_completion_dialog.dart';
import 'package:handle_hero/widgets/out_of_lives_dialog.dart';

class MixedChallengeScreen extends StatelessWidget {
  const MixedChallengeScreen({super.key, required this.moduleIndex});

  final int moduleIndex;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        MixedChallengeBloc(moduleIndex: moduleIndex)
          ..add(MixedChallengeStarted()),
    child: _MixedChallengeView(moduleIndex: moduleIndex),
  );
}

class _MixedChallengeView extends StatelessWidget {
  const _MixedChallengeView({required this.moduleIndex});

  final int moduleIndex;

  void _finishChallenge(BuildContext context) {
    final mistakes = context.read<LevelBloc>().state.mistakes;
    final reward = switch (mistakes) {
      0 => 20,
      1 => 10,
      2 => 15,
      _ => 0,
    };
    context.read<HomeBloc>().add(CoinsEarned(reward));
    showModuleCompletionDialog(
      context: context,
      mistakes: mistakes,
      reward: reward,
      onConfirm: () {
        Navigator.pop(context);
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<LevelBloc, LevelState>(
          listenWhen: (previous, current) =>
              previous.isOutOfLives && !current.isOutOfLives,
          listener: (context, state) =>
              context.read<MixedChallengeBloc>().add(MixedChallengeRetry()),
        ),
        BlocListener<MixedChallengeBloc, MixedChallengeState>(
          listenWhen: (previous, current) =>
              previous.wrongAnswerVersion != current.wrongAnswerVersion,
          listener: (context, state) {
            handleWrongAnswer(
              context: context,
              moduleIndex: moduleIndex,
              onTryAgain: () =>
                  context.read<MixedChallengeBloc>().add(MixedChallengeRetry()),
            );
          },
        ),
        BlocListener<MixedChallengeBloc, MixedChallengeState>(
          listenWhen: (previous, current) =>
              !previous.isComplete && current.isComplete,
          listener: (context, state) => _finishChallenge(context),
        ),
      ],
      child: BlocBuilder<MixedChallengeBloc, MixedChallengeState>(
        builder: (context, state) {
          final task = state.currentTask;
          if (task == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(MyImages.background, fit: BoxFit.cover),
                ),
                LevelHeader(
                  onBack: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          LevelOverviewScreen(moduleIndex: moduleIndex),
                    ),
                  ),
                ),
                Positioned.fill(
                  top: 108,
                  bottom: 20,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _outlinedText(
                          "GODS' TRIAL ${moduleIndex ~/ 4 + 1}",
                          fontSize: 22,
                        ),
                        const SizedBox(height: 8),
                        _outlinedText(
                          'RITE ${state.taskIndex + 1} OF ${state.tasks.length} · ${_activityName(task.activity)}',
                          fontSize: 13,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            value: (state.taskIndex + 1) / state.tasks.length,
                            backgroundColor: const Color(0xFF414536),
                            color: const Color(0xFFD1C27E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(child: _activityView(context, state, task)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _activityView(
    BuildContext context,
    MixedChallengeState state,
    MixedChallengeTask task,
  ) {
    return switch (task.activity) {
      MixedChallengeActivity.nameSign => _nameSignView(context, state, task),
      MixedChallengeActivity.findSign => _findSignView(context, state, task),
      MixedChallengeActivity.matchPair => _matchPairView(context, state, task),
      MixedChallengeActivity.sentence => _sentenceView(context, state, task),
    };
  }

  Widget _nameSignView(
    BuildContext context,
    MixedChallengeState state,
    MixedChallengeTask task,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _outlinedText('Reveal the letter', fontSize: 18),
        const SizedBox(height: 12),
        Expanded(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) => Transform.translate(
                offset: const Offset(0, -30),
                child: LetterSign(
                  option: task.letter,
                  size: math.min(constraints.maxWidth, constraints.maxHeight),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 128,
          child: Transform.translate(
            offset: const Offset(0, -8),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final letter in state.letterChoices)
                  _letterChoiceButton(
                    letter,
                    compact: true,
                    onTap: () => context.read<MixedChallengeBloc>().add(
                      MixedChallengeAnswerSelected(letter),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _findSignView(
    BuildContext context,
    MixedChallengeState state,
    MixedChallengeTask task,
  ) {
    return Column(
      children: [
        _outlinedText('Seek the sign for ${task.letter.letter}', fontSize: 18),
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final rows = (state.imageChoices.length / 2).ceil();
              const spacing = 14.0;
              final imageSize = math.min(
                (constraints.maxWidth - spacing) / 2,
                (constraints.maxHeight - spacing * (rows - 1)) / rows,
              );
              return Wrap(
                alignment: WrapAlignment.center,
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final option in state.imageChoices)
                    _imageChoice(context, task, option, imageSize),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _matchPairView(
    BuildContext context,
    MixedChallengeState state,
    MixedChallengeTask task,
  ) {
    return Column(
      children: [
        _outlinedText('Bind the pairs', fontSize: 18),
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final rowHeight =
                  constraints.maxHeight / state.pairLetters.length;
              final signSize = math.min(
                180.0,
                math.min(constraints.maxWidth / 2.15, rowHeight * 1.06),
              );
              return Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PairConnectionPainter(
                        letters: state.pairLetters,
                        images: state.pairImages
                            .map((option) => option.letter)
                            .toList(),
                        connected: state.matchedLetters,
                        rowHeight: rowHeight,
                        width: constraints.maxWidth,
                        imageSize: signSize,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            for (final letter in state.pairLetters)
                              SizedBox(
                                height: rowHeight,
                                child: Center(
                                  child: _letterChoiceButton(
                                    letter,
                                    imageSize: signSize,
                                    onTap: () =>
                                        context.read<MixedChallengeBloc>().add(
                                          MixedChallengePairLetterSelected(
                                            letter,
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            for (final option in state.pairImages)
                              SizedBox(
                                height: rowHeight,
                                child: Center(
                                  child: _imageChoice(
                                    context,
                                    task,
                                    option,
                                    signSize,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        _outlinedText(
          'Matched ${state.matchedLetters.length} of ${state.pairLetters.length}',
          fontSize: 13,
          color: Colors.white,
        ),
      ],
    );
  }

  Widget _sentenceView(
    BuildContext context,
    MixedChallengeState state,
    MixedChallengeTask task,
  ) {
    final prompt = state.currentSentence!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Transform.translate(
          offset: const Offset(0, -20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _outlinedText('Restore the inscription', fontSize: 18),
              const SizedBox(height: 18),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 28,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34382D),
                    border: Border.all(
                      color: const Color(0xFF7C806C),
                      width: 4,
                    ),
                  ),
                  child: Text.rich(
                    _sentenceSpan(prompt),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: MediaQuery.sizeOf(context).height * .4,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final imageSize = math.min(
                (constraints.maxWidth - 12) / 2,
                (constraints.maxHeight - 12) / 2,
              );
              return Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final option in state.sentenceImageChoices)
                    _imageChoice(context, task, option, imageSize),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  TextSpan _sentenceSpan(SentencePrompt prompt) {
    final parts = prompt.sentence.split('_');
    return TextSpan(
      style: const TextStyle(
        color: Color(0xFFE3D9AA),
        fontSize: 24,
        fontWeight: FontWeight.w800,
        height: 1.45,
      ),
      children: [
        TextSpan(text: parts.first),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              width: 42,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF617347),
                border: Border.all(color: const Color(0xFF25291F), width: 4),
              ),
              child: const Text(
                '?',
                style: TextStyle(
                  color: Color(0xFFE3D9AA),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        if (parts.length > 1) TextSpan(text: parts.last),
      ],
    );
  }

  Widget _letterChoiceButton(
    String letter, {
    required VoidCallback onTap,
    bool compact = false,
    double? imageSize,
  }) {
    final size = imageSize ?? (compact ? 60.0 : 76.0);
    return InkWell(
      onTap: onTap,
      child: SizedBox.square(
        dimension: size,
        child: LetterGlyph(letter: letter, size: size),
      ),
    );
  }

  Widget _imageChoice(
    BuildContext context,
    MixedChallengeTask task,
    LetterOption option,
    double size,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (task.activity == MixedChallengeActivity.matchPair) {
            context.read<MixedChallengeBloc>().add(
              MixedChallengePairImageSelected(option),
            );
          } else {
            context.read<MixedChallengeBloc>().add(
              MixedChallengeAnswerSelected(option.letter),
            );
          }
        },
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: LetterSign(option: option, size: size),
          ),
        ),
      ),
    );
  }

  Widget _outlinedText(
    String text, {
    required double fontSize,
    Color color = const Color(0xFFE3D9AA),
  }) {
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      height: 1.2,
      letterSpacing: .4,
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = Colors.black,
          ),
        ),
        Text(
          text,
          textAlign: TextAlign.center,
          style: style.copyWith(color: color),
        ),
      ],
    );
  }

  String _activityName(MixedChallengeActivity activity) => switch (activity) {
    MixedChallengeActivity.nameSign => 'REVEAL THE LETTER',
    MixedChallengeActivity.findSign => 'SEEK THE SIGN',
    MixedChallengeActivity.matchPair => 'BIND THE PAIRS',
    MixedChallengeActivity.sentence => 'RESTORE THE INSCRIPTION',
  };
}

class _PairConnectionPainter extends CustomPainter {
  const _PairConnectionPainter({
    required this.letters,
    required this.images,
    required this.connected,
    required this.rowHeight,
    required this.width,
    required this.imageSize,
  });

  final List<String> letters;
  final List<String> images;
  final Set<String> connected;
  final double rowHeight;
  final double width;
  final double imageSize;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..color = const Color(0xFF34382D)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.square;
    final line = Paint()
      ..color = const Color(0xFFD1C27E)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.square;

    for (final letter in connected) {
      final letterIndex = letters.indexOf(letter);
      final imageIndex = images.indexOf(letter);
      if (letterIndex < 0 || imageIndex < 0) continue;
      final start = Offset(width * .25, rowHeight * (letterIndex + .5));
      final end = Offset(width * .75, rowHeight * (imageIndex + .5));
      canvas.drawLine(start, end, outline);
      canvas.drawLine(start, end, line);
    }
  }

  @override
  bool shouldRepaint(covariant _PairConnectionPainter oldDelegate) =>
      oldDelegate.letters != letters ||
      oldDelegate.images != images ||
      oldDelegate.connected != connected ||
      oldDelegate.rowHeight != rowHeight ||
      oldDelegate.imageSize != imageSize;
}
