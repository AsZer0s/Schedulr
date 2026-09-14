# 隐私设计

Schedulr 首版采用纯本地数据策略，不提供应用账户、云备份或跨设备同步。

## 数据分类

### 本地课程数据库

Drift/SQLite 保存：

- 课表本地别名
- 学期与教学周配置
- 课程和上课安排
- 作息时间
- 数据来源与本地修改标记

### 桌面小组件快照

为了让 Android AppWidget 和 iOS WidgetKit 在应用未打开时展示课程，应用会生成一份本地、只读的展示快照：

- Android 保存于应用私有 SharedPreferences。
- iOS 保存于主应用和 Widget Extension 共用的 App Group UserDefaults。
- 快照只包含当前课表本地别名、课程名、教师、精简地点、上下课时间、教学周及本地课程 ID。
- 不包含课程备注、课程代码、教学班、教务账号、密码、Cookie、Token、学号或导入原始响应。
- 删除全部本地数据时会先清除共享快照并刷新桌面组件，再删除 Drift SQLite 数据。

桌面小组件内容会直接出现在设备主屏幕，可能被旁人、截图或屏幕共享看到。用户添加小组件即表示接受当前课程信息在主屏幕展示。

### 系统安全存储

Android Keystore / iOS Keychain 仅用于必须保留的登录会话材料。安全存储与课程数据库独立清理。

### 请求期凭据

教务账号和密码只在学校 VPN/IAM WebView 页面内由用户输入并直接提交给学校：

- Flutter 代码不读取输入框内容。
- WebView 消息桥只传递白名单课表字段，不传姓名、学号、班级组成或用户对象。
- 不写入 SQLite、偏好设置或应用安全存储。
- 不记录到日志。
- 不进入测试 fixture。
- 不通过分析或崩溃报告上传。

## 用户控制

应用支持保存多份彼此隔离的本地课表。同学课表只保存用户输入的本地别名，不要求或保存学号，也不从 BITC 返回数据提取学生姓名、班级或身份信息。同学本人登录导入前会清理上一账号的 WebView Cookie。

应用提供两个独立入口：

- 清除教务会话：退出教务认证但保留已经导入的课程。
- 删除全部本地数据：删除所有课表别名、学期、课程、安排和作息设置。

## 日志

网络和业务日志必须移除以下字段及其常见别名：

- Authorization
- Cookie / Set-Cookie
- Password
- Token / Access Token / Refresh Token
- Username / Student ID

生产环境不输出完整请求体和教务 HTML。

## 网络安全

- 默认要求 HTTPS。
- 不实现信任所有证书。
- 不全局允许明文 HTTP。
- BITC VPN/IAM 认证在域名受限的应用内 WebView 完成，导航只允许 `bitc.edu.cn` 及其子域。
- 清除教务会话会同时清理 WebView Cookie。
- 真实学校适配器必须说明其访问是否依赖校园网或 VPN。
