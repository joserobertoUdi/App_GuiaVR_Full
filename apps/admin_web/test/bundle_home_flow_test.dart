import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:campus_domain/campus_domain.dart' as campus_domain;
import 'package:admin_web/core/utils/campus_bundle_export.dart';
import 'package:admin_web/core/utils/home_editor_storage.dart';
import 'package:admin_web/core/utils/platform_storage.dart';

/// Valida el flujo de publicación del fondo de inicio:
/// - el bundle generado por el admin incluye `home` y `navigation` (el fix del
///   bug donde se publicaba solo el campus),
/// - la configuración del editor se persiste y restaura para la recarga de
///   página (el bug de "se pierde al recargar"),
/// - el formato del bundle es interpretable por la app móvil (campus_domain).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PlatformStorage.instance.init();
  });

  group('CampusBundleExport.buildBundleWithSettings (lo que se publica)', () {
    test('incluye home y navigation cuando el editor tiene fondo configurado',
        () {
      final homeState = HomeEditorState(
        type: campus_domain.HomeBackgroundType.carousel,
        intervalSeconds: 7,
        media: const [
          HomeEditorMedia(id: 'home_1', name: 'img1', isVideo: false),
          HomeEditorMedia(id: 'home_2', name: 'img2', isVideo: false),
        ],
      );

      final bundle = CampusBundleExport.buildBundleWithSettings(
        homeState: homeState,
        defaultStartNodeId: 'P01',
      );
      final data = campus_domain.CampusBundle.parse(bundle);

      expect(data.version, campus_domain.CampusBundle.version);
      expect(data.campus.nodes, isNotEmpty);
      expect(data.home, isNotNull);
      expect(data.home!.type, campus_domain.HomeBackgroundType.carousel);
      expect(data.home!.intervalSeconds, 7);
      expect(data.home!.mediaIds, ['home_1', 'home_2']);
      expect(data.navigation, isNotNull);
      expect(data.navigation!.defaultStartNodeId, 'P01');

      final summary = campus_domain.CampusBundle.describe(bundle);
      expect(summary, contains('Home:'));
      expect(summary, contains('Carrusel'));
      expect(summary, contains('P01'));
    });

    test('sin fondo ni inicio el bundle solo lleva el campus', () {
      final bundle = CampusBundleExport.buildBundleWithSettings(
        homeState: null,
        defaultStartNodeId: null,
      );
      final data = campus_domain.CampusBundle.parse(bundle);
      expect(data.home, isNull);
      expect(data.navigation, isNull);
      expect(data.campus.nodes, isNotEmpty);
    });
  });

  group('HomeEditorStorage (config del editor sobrevive a la recarga)', () {
    test('round-trip de tipo, intervalo y metadatos de media', () async {
      await HomeEditorStorage.saveState(const HomeEditorState(
        type: campus_domain.HomeBackgroundType.panorama,
        intervalSeconds: 4,
        media: [HomeEditorMedia(id: 'home_x', name: 'pano', isVideo: false)],
      ));

      final loaded = await HomeEditorStorage.loadState();
      expect(loaded, isNotNull);
      expect(loaded!.type, campus_domain.HomeBackgroundType.panorama);
      expect(loaded.intervalSeconds, 4);
      expect(loaded.media.single.id, 'home_x');
      expect(loaded.media.single.isVideo, isFalse);
    });

    test('round-trip de bytes de media', () async {
      final payload =
          Uint8List.fromList(List<int>.generate(128, (i) => i % 251));
      await HomeEditorStorage.saveMediaBytes('home_bytes', payload);

      final loaded = await HomeEditorStorage.loadMediaBytes('home_bytes');
      expect(loaded, isNotNull);
      expect(loaded, equals(payload));
    });

    test('clearState elimina config y bytes', () async {
      await HomeEditorStorage.saveState(const HomeEditorState(
        type: campus_domain.HomeBackgroundType.image,
        intervalSeconds: 5,
        media: [HomeEditorMedia(id: 'home_c', name: 'img', isVideo: false)],
      ));
      await HomeEditorStorage.saveMediaBytes(
        'home_c',
        Uint8List.fromList([1, 2, 3]),
      );

      await HomeEditorStorage.clearState();
      expect(await HomeEditorStorage.loadState(), isNull);
      expect(await HomeEditorStorage.loadMediaBytes('home_c'), isNull);
    });
  });

  group('Contrato del bundle (lo que interpreta la app móvil)', () {
    test('parse rechaza JSON inválido y bundles sin versión', () {
      expect(
        () => campus_domain.CampusBundle.parse('{no es json'),
        throwsFormatException,
      );
      expect(
        () => campus_domain.CampusBundle.parse('{"campus": {}}'),
        throwsFormatException,
      );
    });

    test('HomeBackgroundConfig exige type válido y mediaIds no vacíos', () {
      expect(
        campus_domain.HomeBackgroundConfig.fromJson(
          {'type': 'carousel', 'mediaIds': ['a']},
        ),
        isNotNull,
      );
      expect(
        campus_domain.HomeBackgroundConfig.fromJson(
          {'type': 'carousel', 'mediaIds': []},
        ),
        isNull,
      );
      expect(
        campus_domain.HomeBackgroundConfig.fromJson(
          {'type': 'otro', 'mediaIds': ['a']},
        ),
        isNull,
      );
    });
  });
}