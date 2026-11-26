import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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
    on<CoinOperationFailed>(
      (event, emit) => emit(state.copyWith(coinError: event.message)),
    );
    on<CoinErrorCleared>(
      (event, emit) => emit(state.copyWith(clearCoinError: true)),
    );
  }

  final HomeRepository _repository;
  String? _activeUserId;
  StreamSubscription<int>? _coinsSubscription;

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    if (_activeUserId == event.userId) return;
    _activeUserId = event.userId;
    await _coinsSubscription?.cancel();
    emit(const HomeState(levels: HomeLevels.all, coins: 0));

    try {
      final coins = await _repository.loadCoins(event.userId);
      if (_activeUserId != event.userId) return;
      emit(HomeState(levels: HomeLevels.all, coins: coins));
      _coinsSubscription = _repository.watchCoins(event.userId).listen(
        (coins) => add(CoinsBalanceSynced(event.userId, coins)),
        onError: (Object error) => add(CoinOperationFailed(_errorMessage(error))),
      );
    } catch (error) {
      if (_activeUserId != event.userId) return;
      emit(state.copyWith(coinError: _errorMessage(error)));
    }
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
    try {
      final newBalance = await _repository.changeCoins(
        userId,
        amount,
        spend: spend,
      );
      if (newBalance == null || _activeUserId != userId) return;
      emit(state.copyWith(coins: newBalance, clearCoinError: true));
    } catch (error) {
      if (_activeUserId != userId) return;
      emit(state.copyWith(coinError: _errorMessage(error)));
    }
  }

  Future<void> _onCoinsBalanceSynced(
    CoinsBalanceSynced event,
    Emitter<HomeState> emit,
  ) async {
    if (_activeUserId != event.userId) return;
    emit(state.copyWith(coins: event.coins, clearCoinError: true));
  }

  String _errorMessage(Object error) => error is FirebaseException
      ? 'Firestore ${error.code}: coin balance could not be updated.'
      : 'Coin balance could not be updated: $error';

  @override
  Future<void> close() async {
    await _coinsSubscription?.cancel();
    return super.close();
  }
}
