import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temple_adventures_admin/database/enums/supabase_tables.enum.dart';

import '../../../services/logging.dart';
import '../model/dive_site.model.dart';

class DiveSiteRepository {
  final SupabaseClient supabase = Supabase.instance.client;

  DiveSiteRepository();

  Future<DiveSite?> addDiveSite(DiveSite diveSite) async {
    final Map<String, dynamic> diveSiteMap = diveSite.toMap();
    diveSiteMap.remove('id');
    final response =
        await supabase.from(SupabaseTable.diveSitesNavigation.toValue()).insert(diveSiteMap).select('*').maybeSingle();
    if (response != null) {
      final DiveSite result = DiveSiteMapper.fromMap(response);
      return result;
    }
    return null;
  }

  Future<DiveSite?> editDiveSite(DiveSite diveSite) async {
    if (diveSite.id == null) {
      throw Exception('Dive Site Id is required to edit dive site');
    }
    final diveSiteMap = diveSite.toMap();
    diveSiteMap.remove('id');
    final response =
        await supabase
            .from(SupabaseTable.diveSitesNavigation.toValue())
            .update(diveSiteMap)
            .eq('id', diveSite.id!)
            .select('*')
            .maybeSingle();
    if (response != null) {
      final DiveSite updatedDiveSite = DiveSiteMapper.fromMap(response);
      return updatedDiveSite;
    }
    return null;
  }

  Future<bool> deleteDiveSite(int id) async {
    try {
      await supabase.from(SupabaseTable.diveSitesNavigation.toValue()).delete().eq('id', id);
      return true;
    } catch (e, stack) {
      Log.e('Error deleting event', error: e, stackTrace: stack);
      return false;
    }
  }

  Future<List<DiveSite>> fetchAllDiveSites() async {
    final List<dynamic> response = await supabase.from(SupabaseTable.diveSitesNavigation.toValue()).select('*');
    return response.map((diveSite) => DiveSiteMapper.fromMap(diveSite as Map<String, dynamic>)).toList();
  }
}
