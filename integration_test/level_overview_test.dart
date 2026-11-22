import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:handle_hero/bloc/level/level_bloc.dart';
import 'package:handle_hero/ui/modules/overview/level_overview_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('learner reviews signs and advances through a module', (
    tester,
  ) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => LevelBloc(),
        child: const MaterialApp(home: LevelOverviewScreen(moduleIndex: 0)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SIGN 1 OF 3'), findsWidgets);
    expect(find.byKey(const ValueKey('question-A')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('question-A')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('answer-A')), findsOneWidget);

    await tester.tap(find.text('NEXT SIGN').last);
    await tester.pumpAndSettle();
    expect(find.text('SIGN 2 OF 3'), findsWidgets);
    expect(find.byKey(const ValueKey('question-B')), findsOneWidget);
  });
}
