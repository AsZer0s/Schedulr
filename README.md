# Schedulr 课程表

一个使用 Flutter 原生组件构建的 iOS / Android 双端课程表应用。应用采用本地优先设计，课程与学期数据保存在设备上的 SQLite 数据库中。

## 当前状态

MVP 实现以下能力：

- 周课程表与教学周切换
- 单双周及不连续周次
- 课程冲突显示
- 手动新增、编辑和删除课程
- 学期、开学日期与教学周数设置
- 正方教务导入抽象、导入预览及事务提交
- 北京信息职业技术学院 BITC 正方 V9 适配器
- 本地演示正方适配器

> BITC 适配器使用校方 VPN/IAM 网页完成认证，App 不读取或保存学校密码。课表响应包含可验证的校历锚点时可自动定位第一教学周周一；无法验证时保留本地开学日期并提示手动设置。当前已完成协议与解析验证，仍需 Android/iOS 真机完成最终验收。

## 技术栈

- Flutter / Dart
- Riverpod
- go_router
- Drift / SQLite
- Dio / Cookie Jar
- Android Keystore / iOS Keychain 安全存储

## 运行

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

只生成 Android 和 iOS 平台工程。iOS 构建与归档需要 macOS、Xcode 和有效签名环境。

## 验证

```bash
flutter analyze
flutter test
flutter build apk --debug
```

## 数据与隐私

- 课程、学期与设置默认只保存在本设备。
- 应用没有云端账号或同步服务。
- 默认不长期保存教务密码。
- 登录会话与普通课程数据库分离，敏感材料只能进入系统安全存储。
- 日志不得包含密码、Cookie、Token、学号或姓名。
- 删除全部本地数据和清除教务会话是两个独立操作。

详见 [正方适配说明](docs/zfsoft-adapter.md) 和 [隐私设计](docs/privacy.md)。

## 目录

```text
lib/
├── app/                         # 启动、路由、主题和通用应用组件
├── core/                        # 数据库、网络、安全存储、时间与错误
├── features/
│   ├── timetable/               # 课程表领域、仓库和界面
│   ├── course_editor/           # 课程详情和手动编辑
│   ├── semester/                # 学期设置
│   ├── import_timetable/        # 导入领域、预览和提交协调
│   └── settings/                # 隐私与设置
└── integrations/zfsoft/         # 正方学校配置、认证和解析适配器
```

## Tag 自动构建

GitHub Actions 只在推送 Git tag 时运行，普通分支 push 和 pull request 不会触发发布构建：

```bash
git tag v1.0.0
git push origin v1.0.0
```

构建完成后，对应 GitHub Release 会包含：

- `Schedulr-<tag>-android.apk`
- `Schedulr-<tag>-ios-unsigned.ipa`

IPA 由 macOS Runner 使用 `--no-codesign` 构建，需要使用有效的 Apple 开发者证书重新签名后安装。

Android 默认使用 GitHub Runner 的 debug key 签署 Release APK，便于开源 fork 直接构建。若需使用正式签名，请配置以下 Actions Secrets：

- `ANDROID_KEYSTORE_BASE64`：JKS/Keystore 文件的 Base64 内容
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

所有四个值同时存在时，工作流自动改用正式 keystore；密钥文件不会写入仓库。

## 开源协议

本项目使用 [MIT License](LICENSE) 开源。学校名称、教务系统及相关商标归各自权利人所有；本项目与正方软件或北京信息职业技术学院不存在官方隶属或背书关系。

## 正方支持范围

正方教务系统在不同学校可能使用不同版本、CAS/统一认证、验证码、参数、编码和课表页面。项目不会宣称自动支持全部部署。

当前试点学校为北京信息职业技术学院。适配器针对其 VPN/IAM 登录和正方 V9 `xskbcx_cxXsgrkb.html` JSON 接口实现，不代表自动支持其他学校的正方部署。
