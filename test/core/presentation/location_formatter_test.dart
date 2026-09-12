import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/core/presentation/location_formatter.dart';

void main() {
  group('compactLocationLabel', () {
    test('extracts numeric building and room labels', () {
      expect(compactLocationLabel('东坝校区 · 东区13-301系统应用实训室1'), '13-301');
      expect(compactLocationLabel('东坝校区 东区14-311公共教室'), '14-311');
      expect(compactLocationLabel('东区14-216第【3】阶梯教室'), '14-216');
      expect(compactLocationLabel('13号楼301教室'), '13-301');
      expect(compactLocationLabel('13楼 0301室'), '13-0301');
    });

    test('keeps or extracts already compact letter locations', () {
      expect(compactLocationLabel('虚构楼 A-101'), 'A-101');
      expect(compactLocationLabel('A-101'), 'A-101');
    });

    test('keeps meaningful named and special venues', () {
      expect(compactLocationLabel('计算机楼 101'), '计算机楼 101');
      expect(compactLocationLabel('实验楼 302'), '实验楼 302');
      expect(compactLocationLabel('操场操场（东区）-04'), '操场操场（东区）-04');
    });

    test('does not guess when location is ambiguous or not a room', () {
      expect(compactLocationLabel('东区13-301、西区14-216'), '东区13-301、西区14-216');
      expect(compactLocationLabel('2026-09-13'), '2026-09-13');
      expect(compactLocationLabel('2026-2027'), '2026-2027');
      expect(compactLocationLabel('课程DEMO-101'), '课程DEMO-101');
      expect(compactLocationLabel('实验室1'), '实验室1');
    });

    test('handles empty values', () {
      expect(compactLocationLabel(null), isNull);
      expect(compactLocationLabel('  '), isNull);
    });
  });
}
