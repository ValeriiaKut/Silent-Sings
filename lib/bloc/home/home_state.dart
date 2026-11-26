import 'package:handle_hero/models/models.dart';

class HomeState {
  final List<LevelData> levels;
  final int coins;
  final String? coinError;

  const HomeState({
    required this.levels,
    required this.coins,
    this.coinError,
  });

  HomeState copyWith({
    List<LevelData>? levels,
    int? coins,
    String? coinError,
    bool clearCoinError = false,
  }) {
    return HomeState(
      levels: levels ?? this.levels,
      coins: coins ?? this.coins,
      coinError: clearCoinError ? null : (coinError ?? this.coinError),
    );
  }
}
