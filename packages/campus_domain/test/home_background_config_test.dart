import 'package:campus_domain/campus_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeBackgroundConfig', () {
    test('toJson/fromJson roundtrip preserva type, mediaIds e interval', () {
      const config = HomeBackgroundConfig(
        type: HomeBackgroundType.carousel,
        mediaIds: ['home_a', 'home_b'],
        intervalSeconds: 7,
      );

      final json = config.toJson();
      expect(json['type'], 'carousel');
      expect(json['mediaIds'], ['home_a', 'home_b']);
      expect(json['intervalSeconds'], 7);

      final parsed = HomeBackgroundConfig.fromJson(json);
      expect(parsed, isNotNull);
      expect(parsed!.type, HomeBackgroundType.carousel);
      expect(parsed.mediaIds, ['home_a', 'home_b']);
      expect(parsed.intervalSeconds, 7);
    });

    test('fromJson devuelve null para JSON inválido o sin media', () {
      expect(HomeBackgroundConfig.fromJson(null), isNull);
      expect(HomeBackgroundConfig.fromJson('nope'), isNull);
      expect(HomeBackgroundConfig.fromJson({'type': 'image'}), isNull);
      expect(
        HomeBackgroundConfig.fromJson({'type': 'unknown', 'mediaIds': ['x']}),
        isNull,
      );
    });

    test('intervalSeconds se normaliza a mínimo 1', () {
      final config = HomeBackgroundConfig.fromJson({
        'type': 'carousel',
        'mediaIds': ['a'],
        'intervalSeconds': 0,
      });
      expect(config!.intervalSeconds, 1);
    });

    test('describe genera una etiqueta legible', () {
      const image = HomeBackgroundConfig(
        type: HomeBackgroundType.image,
        mediaIds: ['a'],
      );
      expect(image.describe(), 'Imagen · 1 media');

      const carousel = HomeBackgroundConfig(
        type: HomeBackgroundType.carousel,
        mediaIds: ['a', 'b'],
        intervalSeconds: 5,
      );
      expect(carousel.describe(), 'Carrusel (5 s) · 2 media');
    });

    test('isEmpty indica falta de media', () {
      expect(
        const HomeBackgroundConfig(
          type: HomeBackgroundType.image,
          mediaIds: [],
        ).isEmpty,
        isTrue,
      );
      expect(
        const HomeBackgroundConfig(
          type: HomeBackgroundType.image,
          mediaIds: ['a'],
        ).isEmpty,
        isFalse,
      );
    });
  });

  group('NavigationConfig', () {
    test('toJson/fromJson roundtrip preserva defaultStartNodeId', () {
      const config = NavigationConfig(defaultStartNodeId: 'P01');
      final json = config.toJson();
      expect(json['defaultStartNodeId'], 'P01');

      final parsed = NavigationConfig.fromJson(json);
      expect(parsed, isNotNull);
      expect(parsed!.defaultStartNodeId, 'P01');
    });

    test('fromJson devuelve null para JSON inválido', () {
      expect(NavigationConfig.fromJson(null), isNull);
      expect(NavigationConfig.fromJson('nope'), isNull);
      expect(NavigationConfig.fromJson({'other': 'x'})?.isEmpty, isTrue);
    });

    test('isEmpty refleja ausencia de inicio por defecto', () {
      expect(const NavigationConfig().isEmpty, isTrue);
      expect(
        const NavigationConfig(defaultStartNodeId: 'P02').isEmpty,
        isFalse,
      );
    });

    test('describe genera una etiqueta legible', () {
      expect(const NavigationConfig().describe(), contains('—'));
      expect(
        const NavigationConfig(defaultStartNodeId: 'P01').describe(),
        'Inicio por defecto: P01',
      );
    });
  });

  group('CampusBundle navigation key', () {
    test('buildData incluye `navigation` solo cuando se provee', () {
      final data = CampusBundle.buildData(campus: _emptyCampus());
      expect(data.containsKey('navigation'), isFalse);

      final withNav = CampusBundle.buildData(
        campus: _emptyCampus(),
        navigation: const NavigationConfig(defaultStartNodeId: 'P01'),
      );
      expect(withNav.containsKey('navigation'), isTrue);
      expect((withNav['navigation']! as Map)['defaultStartNodeId'], 'P01');
    });

    test('parseData recupera navigation junto al home', () {
      final json = CampusBundle.buildJson(
        campus: _emptyCampus(),
        home: const HomeBackgroundConfig(
          type: HomeBackgroundType.video,
          mediaIds: ['vid1'],
        ),
        navigation: const NavigationConfig(defaultStartNodeId: 'P06'),
      );
      final data = CampusBundle.parse(json);
      expect(data.navigation, isNotNull);
      expect(data.navigation!.defaultStartNodeId, 'P06');
      expect(data.home, isNotNull);
      expect(data.home!.type, HomeBackgroundType.video);
    });

    test('describe incluye el inicio por defecto', () {
      final json = CampusBundle.buildJson(
        campus: _emptyCampus(),
        navigation: const NavigationConfig(defaultStartNodeId: 'P01'),
      );
      final summary = CampusBundle.describe(json);
      expect(summary, contains('Inicio por defecto: P01'));
    });
  });
}

/// Campus vacío pero válido para ejercitar el bundle sin depender de datos.
CampusModel _emptyCampus() {
  return const CampusModel(id: 'campus_test', name: 'Test');
}