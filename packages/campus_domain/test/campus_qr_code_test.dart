import 'package:campus_domain/campus_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CampusQrCode.encode', () {
    test('codifica zona con id y nombre', () {
      final out = CampusQrCode.encode(
        const CampusQrReference(
          type: CampusQrEntityType.zone,
          id: 'z_aulas_p1',
          name: 'Aulas P1',
        ),
      );
      expect(out, '* Z:z_aulas_p1|Aulas P1 *');
    });

    test('codifica nodo', () {
      final out = CampusQrCode.encode(
        const CampusQrReference(
          type: CampusQrEntityType.node,
          id: 'P01',
          name: 'Entrada Principal',
        ),
      );
      expect(out, '* N:P01|Entrada Principal *');
    });

    test('codifica edificio y piso', () {
      expect(
        CampusQrCode.encode(
          const CampusQrReference(
            type: CampusQrEntityType.building,
            id: 'edificio_A',
            name: 'Edificio A',
          ),
        ),
        '* B:edificio_A|Edificio A *',
      );
      expect(
        CampusQrCode.encode(
          const CampusQrReference(
            type: CampusQrEntityType.floor,
            id: 'piso_1',
            name: 'Piso 1',
          ),
        ),
        '* F:piso_1|Piso 1 *',
      );
    });
  });

  group('CampusQrCode.parse', () {
    test('decodifica la zona completa', () {
      final ref = CampusQrCode.parse('* Z:z_aulas_p1|Aulas P1 *');
      expect(ref, isNotNull);
      expect(ref!.type, CampusQrEntityType.zone);
      expect(ref.id, 'z_aulas_p1');
      expect(ref.name, 'Aulas P1');
    });

    test('redondea encode -> parse', () {
      final original = const CampusQrReference(
        type: CampusQrEntityType.node,
        id: 'P01',
        name: 'Entrada Principal',
      );
      expect(CampusQrCode.parse(CampusQrCode.encode(original)), original);
    });

    test('tolera espacios extra alrededor', () {
      final ref = CampusQrCode.parse('  * B:edificio_A|Edificio A *  ');
      expect(ref!.type, CampusQrEntityType.building);
      expect(ref.id, 'edificio_A');
    });

    test('acepta nombres con espacio sin asteriscos', () {
      final ref = CampusQrCode.parse('B:edificio_A|Edificio A');
      expect(ref!.type, CampusQrEntityType.building);
      expect(ref.name, 'Edificio A');
    });

    test('compatibilidad NODE:xxx', () {
      final ref = CampusQrCode.parse('NODE:P01');
      expect(ref!.type, CampusQrEntityType.node);
      expect(ref.id, 'P01');
    });

    test('compatibilidad ID plano', () {
      final ref = CampusQrCode.parse('P01');
      expect(ref!.type, CampusQrEntityType.node);
      expect(ref.id, 'P01');
    });

    test('compatibilidad URL con ?node=', () {
      final ref = CampusQrCode.parse('https://campus.app/qr?node=P_AULA_101');
      expect(ref!.type, CampusQrEntityType.node);
      expect(ref.id, 'P_AULA_101');
    });

    test('rechaza basura', () {
      expect(CampusQrCode.parse(''), isNull);
      expect(CampusQrCode.parse('   '), isNull);
      expect(CampusQrCode.parse('hola mundo'), isNull);
    });

    test('prefijo inválido', () {
      expect(CampusQrCode.parse('* X:algo|nombre *'), isNull);
    });
  });
}