import 'dart:io';
import 'dart:typed_data';

import 'package:campus_domain/campus_domain.dart';
import 'package:app_guia_ar/core/utils/home_content_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stub del PathProvider para devolver un directorio temporal aislado.
class _FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  final Directory temp;

  _FakePathProvider(this.temp);

  @override
  Future<String?> getApplicationDocumentsPath() async => temp.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('home_storage_test');
    PathProviderPlatform.instance = _FakePathProvider(tempDir);
    await HomeContentStorage.clearAll();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('saveConfig/loadConfig round-trip', () async {
    const config = HomeBackgroundConfig(
      type: HomeBackgroundType.carousel,
      mediaIds: ['home_a', 'home_b'],
      intervalSeconds: 4,
    );

    await HomeContentStorage.saveConfig(config);
    final loaded = await HomeContentStorage.loadConfig();

    expect(loaded, isNotNull);
    expect(loaded!.type, HomeBackgroundType.carousel);
    expect(loaded.mediaIds, ['home_a', 'home_b']);
    expect(loaded.intervalSeconds, 4);
  });

  test('loadConfig devuelve null si no hay config guardada', () async {
    expect(await HomeContentStorage.loadConfig(), isNull);
  });

  test('saveMedia guarda archivo y hasMedia lo detecta', () async {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    final file = await HomeContentStorage.saveMedia(
      mediaId: 'home_img',
      bytes: bytes,
      type: HomeBackgroundType.image,
    );

    expect(await file.exists(), isTrue);
    expect(
      await HomeContentStorage.hasMedia('home_img', HomeBackgroundType.image),
      isTrue,
    );
    expect(await HomeContentStorage.mediaBytesFromCache('home_img'), bytes);
  });

  test('hasMedia devuelve false para media inexistente', () async {
    expect(
      await HomeContentStorage.hasMedia('nope', HomeBackgroundType.image),
      isFalse,
    );
  });

  test('deleteMedia elimina archivo', () async {
    await HomeContentStorage.saveMedia(
      mediaId: 'home_img',
      bytes: Uint8List.fromList([9, 9]),
      type: HomeBackgroundType.image,
    );
    await HomeContentStorage.deleteMedia('home_img', HomeBackgroundType.image);
    expect(
      await HomeContentStorage.hasMedia('home_img', HomeBackgroundType.image),
      isFalse,
    );
  });

  test('clearAll limpia config y media', () async {
    const config = HomeBackgroundConfig(
      type: HomeBackgroundType.image,
      mediaIds: ['home_img'],
    );
    await HomeContentStorage.saveConfig(config);
    await HomeContentStorage.saveMedia(
      mediaId: 'home_img',
      bytes: Uint8List.fromList([5]),
      type: HomeBackgroundType.image,
    );

    await HomeContentStorage.clearAll();

    expect(await HomeContentStorage.loadConfig(), isNull);
    expect(
      await HomeContentStorage.hasMedia('home_img', HomeBackgroundType.image),
      isFalse,
    );
  });
}