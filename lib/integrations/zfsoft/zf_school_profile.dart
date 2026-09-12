enum ZfAuthStrategy {
  /// Username/password form with no browser or persisted session contract.
  credentialForm,

  /// Credential form that may request a one-time verification code.
  credentialFormWithVerificationCode,

  /// Authentication is completed by the user in a browser-backed session.
  webSession,
}

enum ZfHttpMethod { get, post }

final class ZfTimetableEndpoint {
  const ZfTimetableEndpoint({
    required this.path,
    this.method = ZfHttpMethod.get,
    this.academicYearParameter = 'academicYear',
    this.termParameter = 'term',
    this.fixedParameters = const <String, String>{},
  });

  final String path;
  final ZfHttpMethod method;
  final String academicYearParameter;
  final String termParameter;
  final Map<String, String> fixedParameters;
}

/// Integration-only configuration for a specific Zhengfang deployment.
/// UI code should select a profile by id and must not branch on these fields.
final class ZfSchoolProfile {
  const ZfSchoolProfile({
    required this.id,
    required this.displayName,
    required this.baseUri,
    required this.authStrategy,
    required this.loginPath,
    required this.timetableEndpoint,
    this.isDemo = false,
  });

  final String id;
  final String displayName;
  final Uri baseUri;
  final ZfAuthStrategy authStrategy;
  final String loginPath;
  final ZfTimetableEndpoint timetableEndpoint;

  /// True only for local/mock profiles. A profile existing here does not imply
  /// that a real school is supported.
  final bool isDemo;

  static final bitc = ZfSchoolProfile(
    id: 'bitc-zf-v9',
    displayName: '北京信息职业技术学院（正方 V9）',
    baseUri: Uri.parse('https://jwxt.vpn.bitc.edu.cn'),
    authStrategy: ZfAuthStrategy.webSession,
    loginPath: '/kbcx/xskbcx_cxXskbcxIndex.html?gnmkdm=N2151&layout=default',
    timetableEndpoint: const ZfTimetableEndpoint(
      path: '/kbcx/xskbcx_cxXsgrkb.html',
      method: ZfHttpMethod.post,
      academicYearParameter: 'xnm',
      termParameter: 'xqm',
      fixedParameters: <String, String>{'kzlx': 'ck', 'xsdm': ''},
    ),
  );

  static final demo = ZfSchoolProfile(
    id: 'zfsoft-demo',
    displayName: '正方教务演示数据',
    baseUri: Uri.parse('https://zfsoft-demo.invalid'),
    authStrategy: ZfAuthStrategy.credentialForm,
    loginPath: '/mock/login',
    timetableEndpoint: const ZfTimetableEndpoint(path: '/mock/timetable'),
    isDemo: true,
  );
}
