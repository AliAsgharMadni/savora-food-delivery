import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/controllers/auth_state_provider.dart';
import '../../data/models/saved_address.dart';

final savedAddressesProvider =
    FutureProvider.autoDispose<List<SavedAddress>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final response = await Supabase.instance.client
      .from('addresses')
      .select()
      .eq('user_id', user.id)
      .order('is_default', ascending: false)
      .order('created_at', ascending: false);

  return (response as List)
      .map((item) => SavedAddress.fromJson(item as Map<String, dynamic>))
      .toList();
});

final defaultAddressProvider = Provider.autoDispose<SavedAddress?>((ref) {
  final addresses = ref.watch(savedAddressesProvider).valueOrNull;
  if (addresses == null || addresses.isEmpty) return null;
  for (final addr in addresses) {
    if (addr.isDefault) return addr;
  }
  return addresses.first;
});
