import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:handle_hero/bloc/home/home_event.dart';
import 'package:handle_hero/bloc/home/home_state.dart';
import 'package:handle_hero/data/home_levels.dart';
import 'package:handle_hero/data/home_repository.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({HomeRepository? repository})
    : _repository = repository ?? FirebaseHomeRepository(),
      super(const HomeState(levels: [], coins: 0)) {
    on<HomeStarted>(_onStarted);
    on<CoinsSpent>(_onCoinsSpent);
    on<CoinsEarned>(_onCoinsEarned);
    on<CoinsBalanceSynced>(_onCoinsBalanceSynced);
  }

  final HomeRepository _repository;
  String? _activeUserId;
  StreamSubscription<int>? _coinsSubscription;

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    if (_activeUserId == event.userId) return;
    _activeUserId = event.userId;
    await _coinsSubscription?.cancel();
    emit(const HomeState(levels: HomeLevels.all, coins: 0));

    final coins = await _repository.loadCoins(event.userId);
    if (_activeUserId != event.userId) return;
    emit(HomeState(levels: HomeLevels.all, coins: coins));
    _coinsSubscription = _repository
        .watchCoins(event.userId)
        .listen((coins) => add(CoinsBalanceSynced(event.userId, coins)));
  }

  Future<void> _onCoinsSpent(CoinsSpent event, Emitter<HomeState> emit) async {
    if (event.amount <= 0) return;
    await _changeCoins(event.amount, spend: true, emit: emit);
  }

  Future<void> _onCoinsEarned(
    CoinsEarned event,
    Emitter<HomeState> emit,
  ) async {
    if (event.amount <= 0) return;
    await _changeCoins(event.amount, spend: false, emit: emit);
  }

  Future<void> _changeCoins(
    int amount, {
    required bool spend,
    required Emitter<HomeState> emit,
  }) async {
    final userId = _activeUserId;
    if (userId == null) return;
    final newBalance = await _repository.changeCoins(
      userId,
      amount,
      spend: spend,
    );
    if (newBalance == null || _activeUserId != userId) return;
    emit(state.copyWith(coins: newBalance));
  }

  Future<void> _onCoinsBalanceSynced(
    CoinsBalanceSynced event,
    Emitter<HomeState> emit,
  ) async {
    if (_activeUserId != event.userId) return;
    emit(state.copyWith(coins: event.coins));
  }

  @override
  Future<void> close() async {
    await _coinsSubscription?.cancel();
    return super.close();
  }
}
