import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/failure.dart';
import 'models/food_item.dart';
import 'models/restaurant.dart';

abstract class IFoodRepository {
  Future<List<Restaurant>> fetchRestaurants();
  Future<List<FoodItem>> fetchFoods({String? category, String? searchQuery});
  Future<List<FoodItem>> fetchPopularFoods();
  Future<FoodItem?> fetchFoodById(String id);
  Future<Set<String>> fetchFavoriteFoodIds(String userId);
  Future<void> toggleFavorite({
    required String userId,
    required String foodId,
    required bool isFavorite,
  });
}

class SupabaseFoodRepository implements IFoodRepository {
  final SupabaseClient? client;

  SupabaseFoodRepository({this.client});

  SupabaseClient get _safeClient => client ?? Supabase.instance.client;

  @override
  Future<List<Restaurant>> fetchRestaurants() async {
    try {
      final response = await _safeClient
          .from('restaurants')
          .select()
          .order('rating', ascending: false);

      return (response as List)
          .map((item) => Restaurant.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Failure('Failed to fetch restaurants: $e');
    }
  }

  @override
  Future<List<FoodItem>> fetchFoods({String? category, String? searchQuery}) async {
    try {
      var query = _safeClient.from('foods').select();

      if (category != null && category.isNotEmpty && category != 'All') {
        query = query.eq('category', category);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        query = query.ilike('name', '%${searchQuery.trim()}%');
      }

      final response = await query.order('rating', ascending: false);
      return (response as List)
          .map((item) => FoodItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Failure('Failed to fetch foods: $e');
    }
  }

  @override
  Future<List<FoodItem>> fetchPopularFoods() async {
    try {
      final response = await _safeClient
          .from('foods')
          .select()
          .eq('is_popular', true)
          .order('rating', ascending: false);

      return (response as List)
          .map((item) => FoodItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Failure('Failed to fetch popular foods: $e');
    }
  }

  @override
  Future<FoodItem?> fetchFoodById(String id) async {
    try {
      final response = await _safeClient
          .from('foods')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return FoodItem.fromJson(response);
    } catch (e) {
      throw Failure('Failed to fetch food details: $e');
    }
  }

  @override
  Future<Set<String>> fetchFavoriteFoodIds(String userId) async {
    try {
      final response = await _safeClient
          .from('favorites')
          .select('food_id')
          .eq('user_id', userId);

      final ids = (response as List)
          .map((item) => item['food_id'] as String)
          .toSet();
      return ids;
    } catch (e) {
      return {};
    }
  }

  @override
  Future<void> toggleFavorite({
    required String userId,
    required String foodId,
    required bool isFavorite,
  }) async {
    try {
      if (isFavorite) {
        await _safeClient.from('favorites').insert({
          'user_id': userId,
          'food_id': foodId,
        });
      } else {
        await _safeClient
            .from('favorites')
            .delete()
            .eq('user_id', userId)
            .eq('food_id', foodId);
      }
    } catch (e) {
      throw Failure('Failed to update favorite: $e');
    }
  }
}

