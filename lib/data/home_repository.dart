import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class HomeRepository {
  Future<int> loadCoins(String userId);

  Future<int?> changeCoins(String userId, int amount, {required bool spend});

  Stream<int> watchCoins(String userId);
}

class FirebaseHomeRepository implements HomeRepository {
  FirebaseHomeRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String _coinKey(String userId) => 'coins_$userId';

  DocumentReference<Map<String, dynamic>> _userRef(String userId) =>
      _firestore.collection('users').doc(userId);

  @override
  Future<int> loadCoins(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    final cachedCoins = preferences.getInt(_coinKey(userId)) ?? 100;
    final reference = _userRef(userId);
    final snapshot = await reference.get();
    final storedCoins = (snapshot.data()?['coins'] as num?)?.toInt();
    final coins = storedCoins ?? cachedCoins;
    if (!snapshot.exists) {
      await reference.set({
        'id': userId,
        'name': '',
        'createdAt': FieldValue.serverTimestamp(),
        'coins': coins,
      });
    } else if (storedCoins == null) {
      await reference.set({'coins': coins}, SetOptions(merge: true));
    }
    await preferences.setInt(_coinKey(userId), coins);
    return coins;
  }

  @override
  Future<int?> changeCoins(String userId, int amount, {required bool spend}) =>
      _firestore
          .runTransaction<int?>((transaction) async {
            final reference = _userRef(userId);
            final document = await transaction.get(reference);
            final current = (document.data()?['coins'] as num?)?.toInt() ?? 0;
            if (spend && current < amount) return null;
            final updated = spend ? current - amount : current + amount;
            transaction.set(reference, {
              'coins': updated,
            }, SetOptions(merge: true));
            return updated;
          })
          .then((coins) async {
            if (coins != null) {
              final preferences = await SharedPreferences.getInstance();
              await preferences.setInt(_coinKey(userId), coins);
            }
            return coins;
          });

  @override
  Stream<int> watchCoins(String userId) => _userRef(userId)
      .snapshots()
      .asyncMap((document) async {
        final coins = (document.data()?['coins'] as num?)?.toInt();
        if (coins == null) return null;
        final preferences = await SharedPreferences.getInstance();
        await preferences.setInt(_coinKey(userId), coins);
        return coins;
      })
      .where((coins) => coins != null)
      .cast<int>();
}
