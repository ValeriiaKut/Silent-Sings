import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:handle_hero/bloc/home/home_bloc.dart';
import 'package:handle_hero/bloc/home/home_event.dart';
import 'package:handle_hero/data/home_repository.dart';

class _MemoryHomeRepository implements HomeRepository {
  _MemoryHomeRepository(this.coins);

  int coins;
  int changeCalls = 0;
  final _updates = StreamController<int>.broadcast();

  @override
  Future<int> loadCoins(String userId) async => coins;

  @override
  Future<int?> changeCoins(
    String userId,
    int amount, {
    required bool spend,
  }) async {
    changeCalls++;
    if (spend && coins < amount) return null;
    coins = spend ? coins - amount : coins + amount;
    return coins;
  }

  @override
  Stream<int> watchCoins(String userId) => _updates.stream;

  Future<void> updateBalance(int value) async {
    coins = value;
    _updates.add(value);
  }

  Future<void> close() => _updates.close();
}

void main() {
  test('loads levels and the user coin balance', () async {
    final repository = _MemoryHomeRepository(75);
    final bloc = HomeBloc(repository: repository);
    addTearDown(bloc.close);
    addTearDown(repository.close);

    final loaded = bloc.stream.firstWhere((state) => state.coins == 75);
    bloc.add(HomeStarted('user-1'));
    await loaded;

    expect(bloc.state.levels, isNotEmpty);
    expect(bloc.state.coins, 75);
  });

  test('updates coins for earned and spent amounts', () async {
    final repository = _MemoryHomeRepository(100);
    final bloc = HomeBloc(repository: repository);
    addTearDown(bloc.close);
    addTearDown(repository.close);

    final loaded = bloc.stream.firstWhere((state) => state.coins == 100);
    bloc.add(HomeStarted('user-1'));
    await loaded;

    final earned = bloc.stream.firstWhere((state) => state.coins == 125);
    bloc.add(CoinsEarned(25));
    await earned;

    final spent = bloc.stream.firstWhere((state) => state.coins == 105);
    bloc.add(CoinsSpent(20));
    await spent;
    expect(repository.coins, 105);
  });

  test('rejects overspending and ignores non-positive amounts', () async {
    final repository = _MemoryHomeRepository(10);
    final bloc = HomeBloc(repository: repository);
    addTearDown(bloc.close);
    addTearDown(repository.close);

    final loaded = bloc.stream.firstWhere((state) => state.coins == 10);
    bloc.add(HomeStarted('user-1'));
    await loaded;

    bloc.add(CoinsSpent(20));
    bloc.add(CoinsEarned(0));
    bloc.add(CoinsSpent(-1));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.coins, 10);
    expect(repository.coins, 10);
    expect(repository.changeCalls, 1);
  });

  test('applies live balance updates only for the active user', () async {
    final repository = _MemoryHomeRepository(40);
    final bloc = HomeBloc(repository: repository);
    addTearDown(bloc.close);
    addTearDown(repository.close);

    final loaded = bloc.stream.firstWhere((state) => state.coins == 40);
    bloc.add(HomeStarted('user-1'));
    await loaded;

    final updated = bloc.stream.firstWhere((state) => state.coins == 55);
    await repository.updateBalance(55);
    await updated;

    bloc.add(CoinsBalanceSynced('another-user', 999));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.coins, 55);
  });
}
