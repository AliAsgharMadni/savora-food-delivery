import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/controllers/auth_state_provider.dart';
import '../../data/food_repository.dart';
import '../../data/models/food_item.dart';
import '../../data/models/restaurant.dart';

final foodRepositoryProvider = Provider<IFoodRepository>((ref) {
  return SupabaseFoodRepository();
});

final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

final foodSearchQueryProvider = StateProvider<String>((ref) => '');

final restaurantsProvider = FutureProvider<List<Restaurant>>((ref) async {
  final repository = ref.watch(foodRepositoryProvider);
  return repository.fetchRestaurants();
});

final foodsListProvider = FutureProvider<List<FoodItem>>((ref) async {
  final repository = ref.watch(foodRepositoryProvider);
  final category = ref.watch(selectedCategoryProvider);
  final searchQuery = ref.watch(foodSearchQueryProvider);

  return repository.fetchFoods(
    category: category,
    searchQuery: searchQuery,
  );
});

final popularFoodsProvider = FutureProvider<List<FoodItem>>((ref) async {
  final repository = ref.watch(foodRepositoryProvider);
  return repository.fetchPopularFoods();
});

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  final repository = ref.watch(foodRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);
  return FavoritesNotifier(repository, currentUser?.id);
});

class FavoritesNotifier extends StateNotifier<Set<String>> {
  final IFoodRepository _repository;
  final String? _userId;

  FavoritesNotifier(this._repository, this._userId) : super({}) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (_userId == null) return;
    try {
      final ids = await _repository.fetchFavoriteFoodIds(_userId);
      state = ids;
    } catch (_) {}
  }

  Future<void> toggleFavorite(String foodId) async {
    if (_userId == null) return;

    final isCurrentlyFav = state.contains(foodId);
    final newState = Set<String>.from(state);

    if (isCurrentlyFav) {
      newState.remove(foodId);
    } else {
      newState.add(foodId);
    }
    state = newState;

    try {
      await _repository.toggleFavorite(
        userId: _userId,
        foodId: foodId,
        isFavorite: !isCurrentlyFav,
      );
    } catch (e) {
      // Revert on failure
      state = isCurrentlyFav ? (newState..add(foodId)) : (newState..remove(foodId));
    }
  }
}

