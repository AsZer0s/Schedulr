const zfDemoTimetableFixture = '''
{
  "schema": "schedulr-zfsoft-sanitized-v1",
  "courses": [
    {
      "id": "demo-linear-algebra",
      "name": "线性代数（演示）",
      "teacher": "示例教师甲",
      "location": "示例楼 A-101",
      "weekday": 1,
      "periods": [1, 2],
      "weeks": [1, 2, 3, 4, 5, 6, 7, 8]
    },
    {
      "id": "demo-programming",
      "name": "程序设计（演示）",
      "teacher": "示例教师乙",
      "location": "示例实验室 B-202",
      "weekday": 3,
      "periods": [3, 4],
      "weeks": [1, 2, 3, 4, 5, 6, 7, 8],
      "notes": "完全虚构的本地演示数据"
    },
    {
      "id": "demo-physical-education",
      "name": "体育（演示）",
      "teacher": "示例教师丙",
      "location": "示例操场",
      "weekday": 5,
      "periods": [5, 6],
      "weeks": [1, 3, 5, 7]
    }
  ]
}
''';
