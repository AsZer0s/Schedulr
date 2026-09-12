# 正方解析 Fixture 脱敏约定

本目录仅包含完全虚构、不可回溯到真实账号的脱敏响应。`bitc_v9_timetable_sanitized.json` 保留了 BITC 正方 V9 已验证的 `kbList` / `sjkList` 字段结构、同教学班多安排、单双周、不连续周次，以及虚构的 `rqazcList` / `zs` 校历锚点，仅用于自动化测试；其中学生、教师、教室、课程、代码、内部 ID 和日期组合均为虚构值。

`MockZfTimetableImporter` 仍只读取代码内的虚构 JSON 演示数据，不联网。BITC 适配器使用调用方持有的已认证 Web 会话获取 payload，不接收或保存用户名、密码、Cookie、Token。

若后续为解析器增加 fixture，提交前必须：

- 删除域名、IP、学校名称、学号、姓名、班级、教师真实姓名和教室真实编号；
- 删除 Cookie、Token、Session ID、验证码、隐藏表单值及请求头；
- 将课程名、教师、地点替换为明确的虚构值，保持的仅是解析所需结构；
- 为 ID 使用 `demo-*` 或随机不可回溯值；
- 人工检查原始 HTML/JSON 中的注释、脚本变量和元数据；
- 不提交原始抓包或原始响应，即使测试未直接引用。

脱敏 fixture 可以是 `schedulr-zfsoft-sanitized-v1` 演示结构，或已支持学校适配器所需的脱敏原始字段结构。真实学校适配器需独立实现 `ZfTimetableParser`，并在 integration/repository 组装层选择，学校差异不得进入 UI。
