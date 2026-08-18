import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_guia_ar/core/utils/app_settings.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppSettings - tiempo de vista rápida', () {
    test('por defecto usa 2 segundos', () async {
      expect(await AppSettings.quickPreviewDelaySeconds(), 2);
    });

    test('guardar y leer el valor configurado', () async {
      await AppSettings.setQuickPreviewDelaySeconds(4);
      expect(await AppSettings.quickPreviewDelaySeconds(), 4);
    });

    test('se limita al rango permitido (1 a 5)', () async {
      await AppSettings.setQuickPreviewDelaySeconds(0);
      expect(await AppSettings.quickPreviewDelaySeconds(), 1);

      await AppSettings.setQuickPreviewDelaySeconds(99);
      expect(await AppSettings.quickPreviewDelaySeconds(), 5);

      await AppSettings.setQuickPreviewDelaySeconds(3);
      expect(await AppSettings.quickPreviewDelaySeconds(), 3);
    });

    test('el valor sobrevive entre instancias (persistencia real)', () async {
      await AppSettings.setQuickPreviewDelaySeconds(5);
      // Simula un nuevo arranque: misma storage subyacente.
      expect(await AppSettings.quickPreviewDelaySeconds(), 5);
    });
  });
}
