# 正方教务适配器开发说明

## 支持原则

正方在不同学校的部署并非统一公共 API。每个学校必须通过独立的 `ZfSchoolProfile`、认证策略、端点策略和解析器适配，学校判断不得进入 UI 或通用课程领域层。

只有完成真实验证的学校才能列为“已支持”。验证至少包括：

1. 普通登录、CAS 或统一身份认证完整流程。
2. 验证码流程（如有）。
3. 学年、学期参数及课表查询。
4. 普通课表、空课表、单双周和不连续周次。
5. Cookie 失效、重新登录和系统维护错误。
6. UTF-8、GBK/GB2312 等实际响应编码。
7. Android 和 iOS 真机网络行为。

## 安全约束

- 不将真实密码、Cookie、Token、学号、姓名写入仓库、fixture、截图文件名或日志。
- 默认不长期保存密码；优先保存可撤销会话，会话失效后重新登录。
- 不关闭 TLS 证书校验。
- 不全局开放 Android 明文 HTTP 或 iOS ATS。
- 若试点站点只能使用 HTTP，只能配置域名级最小例外并在 UI 中说明风险。
- CI 不得登录真实教务系统。

## Fixture 脱敏

保存响应前必须替换：

- 域名、IP、学校名称和内部路径中的敏感标识。
- 学号、姓名、班级、手机号、邮箱、身份证号。
- 教师姓名和真实教室（使用虚构值）。
- Cookie、Token、CAS Ticket、CSRF、动态隐藏字段。
- 可关联真实账号的课程代码、教学班 ID 和外部 ID。

脱敏后仍需保留页面结构、字段类型、编码特征和周次格式，以便解析测试有效。

## 接入结构

```text
integrations/zfsoft/
├── profiles/       # 学校 URL、系统版本、编码和能力标记
├── auth/           # 账号密码、验证码、CAS 等策略
├── adapters/       # 网络请求编排
├── parsers/        # HTML/JSON 到 DTO
└── fixtures/       # 完全脱敏的测试响应
```

解析流程必须为：原始响应字节 → 按响应头/profile 解码 → DTO → 通用导入模型 → 课程领域模型。

不得直接从 HTML 构建 UI，也不得将 Dio、DOM 或学校字段暴露到 domain 层。

## 北京信息职业技术学院试点

已验证部署特征：

- 认证入口使用 `vpn.bitc.edu.cn/iam/login`。
- 教务主机为 `jwxt.vpn.bitc.edu.cn`。
- 正方版本为 V9。
- 个人课表数据由 `POST /kbcx/xskbcx_cxXsgrkb.html` 返回 JSON。
- 请求参数为 `xnm`、正方学期代码 `xqm`、`kzlx=ck` 和空 `xsdm`。
- App 使用域名受限的 WebView 建立校方会话，密码不进入 Flutter 层。
- WebView 在发送课表给 Flutter 前执行字段白名单，只保留课程解析必需信息，以及 `rqazcList` 中的 `rq`、`xqj`、`zc` 和 primitive `zs`。
- BITC 返回可验证的日期/星期/教学周锚点时，导入可自动定位第一教学周周一；锚点缺失、星期不符或推导冲突时不会猜测或覆盖本地开学日期，并提示用户在学期设置中手动确认。

该适配只覆盖 BITC 当前部署，不应复用为“通用正方 V9”。Android/iOS 真机认证与 Cookie 生命周期仍需最终验收。

## 当前演示适配器

`MockZfTimetableImporter` 只用于本地 UI 与测试：

- 固定演示凭据 `demo / demo`。
- 完全不联网。
- 不持久化凭据或会话。
- 只接受 demo profile。
- 不代表任何真实学校已经受到支持。
