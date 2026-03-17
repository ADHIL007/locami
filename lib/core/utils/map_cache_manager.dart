import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:path_provider/path_provider.dart';

class MapCacheManager {
  MapCacheManager._();
  static final MapCacheManager instance = MapCacheManager._();

  FileCacheStore? _cacheStore;

  Future<FileCacheStore> get cacheStore async {
    if (_cacheStore != null) return _cacheStore!;

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/map_cache';
    _cacheStore = FileCacheStore(path);
    return _cacheStore!;
  }
}
