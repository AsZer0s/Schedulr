import Flutter
import UIKit

/// App-owned bridge for UIKit's system `UIAlertController`.
///
/// Channel contract: `app.schedulr/native_dialogs`
///
/// Supported typed methods:
/// - `showActionSheet`: `{title?, message?, cancelLabel, actions: [{id, label, destructive}]}`
///   returns the selected stable action ID (`String`) or `null` on cancellation.
/// - `showConfirmation`: `{title?, message?, confirmLabel, cancelLabel, destructive}`
///   returns `true` when confirmed or `null` on cancellation.
/// - `showTextInput`: `{title?, message?, initialValue?, confirmLabel, cancelLabel,
///   placeholder?, maxLength?}` returns the entered `String` or `null` on cancellation.
///
/// `maxLength` is enforced by the native text field, while semantic validation and any
/// re-prompt behavior remain in Dart. The bridge deliberately uses the system alert
/// controller so current iOS styling, including iOS 26 Liquid Glass, is automatic.
final class NativeDialogPlugin: NSObject, FlutterPlugin {
  static let channelName = "app.schedulr/native_dialogs"
  private static let pluginKey = "SchedulrNativeDialogPlugin"

  private var activePresentation: NativeDialogPresentationSession?

  /// Registration entry point for Flutter's implicit engine registry and messenger.
  static func register(with registry: FlutterPluginRegistry) {
    register(with: registry.registrar(forPlugin: pluginKey))
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    let instance = NativeDialogPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let work = { [weak self] in
      guard let self else {
        result(
          FlutterError(
            code: NativeDialogErrorCode.presentationUnavailable.rawValue,
            message: "The native dialog bridge is unavailable.",
            details: ["method": call.method]
          )
        )
        return
      }
      self.handleOnMainThread(call, result: result)
    }

    if Thread.isMainThread {
      work()
    } else {
      DispatchQueue.main.async(execute: work)
    }
  }

  private func handleOnMainThread(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    dispatchPrecondition(condition: .onQueue(.main))

    guard let method = NativeDialogMethod(rawValue: call.method) else {
      result(FlutterMethodNotImplemented)
      return
    }

    let request: NativeDialogRequest
    do {
      request = try NativeDialogRequest.parse(method: method, arguments: call.arguments)
    } catch let error as NativeDialogRequestError {
      result(error.flutterError(method: call.method))
      return
    } catch {
      result(
        FlutterError(
          code: NativeDialogErrorCode.invalidArguments.rawValue,
          message: "The dialog arguments could not be decoded.",
          details: ["method": call.method]
        )
      )
      return
    }

    guard activePresentation == nil else {
      result(
        FlutterError(
          code: NativeDialogErrorCode.presentationInProgress.rawValue,
          message: "Another native dialog is already being presented.",
          details: ["method": call.method]
        )
      )
      return
    }

    guard let presenter = NativeDialogPresenter.topViewControllerInActiveScene() else {
      result(
        FlutterError(
          code: NativeDialogErrorCode.presentationUnavailable.rawValue,
          message: "No visible view controller exists in an active UIWindowScene.",
          details: ["method": call.method]
        )
      )
      return
    }

    let relay = NativeDialogCompletionRelay()
    let prepared = NativeDialogAlertFactory.make(request: request) { completion in
      relay.complete(completion)
    }
    let session = NativeDialogPresentationSession(
      preparedDialog: prepared,
      result: result,
      owner: self
    )
    relay.session = session
    activePresentation = session

    if request.method == .showActionSheet, let popover = prepared.alert.popoverPresentationController {
      popover.sourceView = presenter.view
      popover.sourceRect = CGRect(
        x: presenter.view.bounds.midX,
        y: presenter.view.bounds.midY,
        width: 1,
        height: 1
      )
      popover.permittedArrowDirections = []
    }

    presenter.present(prepared.alert, animated: true) { [weak self, weak session] in
      guard let self, let session else { return }
      guard session.alert.presentingViewController != nil || session.alert.viewIfLoaded?.window != nil else {
        session.failPresentation()
        self.presentationSessionDidEnd(session)
        return
      }
      session.alert.presentationController?.delegate = session
      self.monitor(session)
    }
    prepared.alert.presentationController?.delegate = session
  }

  private func monitor(_ session: NativeDialogPresentationSession) {
    guard activePresentation === session else { return }

    if session.isPresentedOrTransitioning {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self, weak session] in
        guard let self, let session else { return }
        self.monitor(session)
      }
      return
    }

    // Covers UIKit dismissal paths which do not invoke an action handler or adaptive
    // presentation delegate callback. The session itself guarantees exactly-once result delivery.
    session.complete(.cancelled)
    presentationSessionDidEnd(session)
  }

  fileprivate func presentationSessionDidEnd(_ session: NativeDialogPresentationSession) {
    if activePresentation === session {
      activePresentation = nil
    }
  }
}

enum NativeDialogErrorCode: String {
  case invalidArguments = "invalid_arguments"
  case presentationInProgress = "presentation_in_progress"
  case presentationUnavailable = "presentation_unavailable"
  case presentationFailed = "presentation_failed"
}

enum NativeDialogMethod: String, Equatable {
  case showActionSheet
  case showConfirmation
  case showTextInput
}

struct NativeDialogAction: Equatable {
  let id: String
  let label: String
  let isDestructive: Bool
}

enum NativeDialogRequest: Equatable {
  case actionSheet(title: String?, message: String?, cancelLabel: String, actions: [NativeDialogAction])
  case confirmation(title: String?, message: String?, confirmLabel: String, cancelLabel: String, destructive: Bool)
  case textInput(
    title: String?,
    message: String?,
    initialValue: String?,
    confirmLabel: String,
    cancelLabel: String,
    placeholder: String?,
    maxLength: Int?
  )

  var method: NativeDialogMethod {
    switch self {
    case .actionSheet: return .showActionSheet
    case .confirmation: return .showConfirmation
    case .textInput: return .showTextInput
    }
  }

  static func parse(method: NativeDialogMethod, arguments: Any?) throws -> NativeDialogRequest {
    let decoder = try NativeDialogArguments(arguments)
    let title = try decoder.optionalString("title")
    let message = try decoder.optionalString("message")
    let cancelLabel = try decoder.requiredNonEmptyString("cancelLabel")

    switch method {
    case .showActionSheet:
      let actions = try decoder.actions("actions")
      guard !actions.isEmpty else {
        throw NativeDialogRequestError(field: "actions", reason: "must contain at least one action")
      }
      return .actionSheet(title: title, message: message, cancelLabel: cancelLabel, actions: actions)

    case .showConfirmation:
      return .confirmation(
        title: title,
        message: message,
        confirmLabel: try decoder.requiredNonEmptyString("confirmLabel"),
        cancelLabel: cancelLabel,
        destructive: try decoder.optionalBoolean("destructive") ?? false
      )

    case .showTextInput:
      let maxLength = try decoder.optionalInteger("maxLength")
      if let maxLength, maxLength < 0 {
        throw NativeDialogRequestError(field: "maxLength", reason: "must be non-negative")
      }
      return .textInput(
        title: title,
        message: message,
        initialValue: try decoder.optionalString("initialValue"),
        confirmLabel: try decoder.requiredNonEmptyString("confirmLabel"),
        cancelLabel: cancelLabel,
        placeholder: try decoder.optionalString("placeholder"),
        maxLength: maxLength
      )
    }
  }
}

struct NativeDialogRequestError: Error, Equatable {
  let field: String
  let reason: String

  func flutterError(method: String) -> FlutterError {
    FlutterError(
      code: NativeDialogErrorCode.invalidArguments.rawValue,
      message: "Invalid native dialog arguments: \(field) \(reason).",
      details: ["method": method, "field": field, "reason": reason]
    )
  }
}

private struct NativeDialogArguments {
  private let values: [String: Any]

  init(_ arguments: Any?) throws {
    guard let values = arguments as? [String: Any] else {
      throw NativeDialogRequestError(field: "arguments", reason: "must be a map")
    }
    self.values = values
  }

  func optionalString(_ key: String) throws -> String? {
    guard let value = values[key], !(value is NSNull) else { return nil }
    guard let string = value as? String else {
      throw NativeDialogRequestError(field: key, reason: "must be a string or null")
    }
    return string
  }

  func requiredNonEmptyString(_ key: String) throws -> String {
    guard let string = try optionalString(key), !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw NativeDialogRequestError(field: key, reason: "must be a non-empty string")
    }
    return string
  }

  func optionalInteger(_ key: String) throws -> Int? {
    guard let value = values[key], !(value is NSNull) else { return nil }
    guard !(value is Bool), let integer = value as? Int else {
      throw NativeDialogRequestError(field: key, reason: "must be an integer or null")
    }
    return integer
  }

  func optionalBoolean(_ key: String) throws -> Bool? {
    guard let value = values[key], !(value is NSNull) else { return nil }
    guard let boolean = value as? Bool else {
      throw NativeDialogRequestError(field: key, reason: "must be a boolean or null")
    }
    return boolean
  }

  func actions(_ key: String) throws -> [NativeDialogAction] {
    guard let rawActions = values[key] as? [Any] else {
      throw NativeDialogRequestError(field: key, reason: "must be an array")
    }

    var seenIDs = Set<String>()
    return try rawActions.enumerated().map { index, rawAction in
      guard let action = rawAction as? [String: Any] else {
        throw NativeDialogRequestError(field: "actions[\(index)]", reason: "must be a map")
      }
      let actionDecoder = try NativeDialogArguments(action)
      let id = try actionDecoder.requiredNonEmptyString("id")
      guard seenIDs.insert(id).inserted else {
        throw NativeDialogRequestError(field: "actions[\(index)].id", reason: "must be unique")
      }
      return NativeDialogAction(
        id: id,
        label: try actionDecoder.requiredNonEmptyString("label"),
        isDestructive: try actionDecoder.optionalBoolean("destructive") ?? false
      )
    }
  }
}

enum NativeDialogCompletion: Equatable {
  case action(id: String)
  case confirmed
  case text(String)
  case cancelled
}

struct NativeDialogPreparedDialog {
  let alert: UIAlertController
  let retainedObjects: [AnyObject]
}

enum NativeDialogAlertFactory {
  static func make(
    request: NativeDialogRequest,
    completion: @escaping (NativeDialogCompletion) -> Void
  ) -> NativeDialogPreparedDialog {
    let style: UIAlertController.Style = request.method == .showActionSheet ? .actionSheet : .alert
    let alert: UIAlertController
    var retainedObjects: [AnyObject] = []

    switch request {
    case let .actionSheet(title, message, cancelLabel, actions):
      alert = UIAlertController(title: title, message: message, preferredStyle: style)
      actions.forEach { action in
        alert.addAction(
          UIAlertAction(
            title: action.label,
            style: action.isDestructive ? .destructive : .default
          ) { _ in
            completion(.action(id: action.id))
          }
        )
      }
      alert.addAction(UIAlertAction(title: cancelLabel, style: .cancel) { _ in completion(.cancelled) })

    case let .confirmation(title, message, confirmLabel, cancelLabel, destructive):
      alert = UIAlertController(title: title, message: message, preferredStyle: style)
      alert.addAction(
        UIAlertAction(title: confirmLabel, style: destructive ? .destructive : .default) { _ in
          completion(.confirmed)
        }
      )
      alert.addAction(UIAlertAction(title: cancelLabel, style: .cancel) { _ in completion(.cancelled) })

    case let .textInput(title, message, initialValue, confirmLabel, cancelLabel, placeholder, maxLength):
      alert = UIAlertController(title: title, message: message, preferredStyle: style)
      let limiter = NativeDialogTextLengthLimiter(maxLength: maxLength)
      retainedObjects.append(limiter)
      alert.addTextField { textField in
        textField.placeholder = placeholder
        textField.text = limiter.limited(initialValue ?? "")
        textField.clearButtonMode = .whileEditing
        textField.delegate = limiter
      }
      alert.addAction(UIAlertAction(title: confirmLabel, style: .default) { [weak alert] _ in
        completion(.text(alert?.textFields?.first?.text ?? ""))
      })
      alert.addAction(UIAlertAction(title: cancelLabel, style: .cancel) { _ in completion(.cancelled) })
    }

    return NativeDialogPreparedDialog(alert: alert, retainedObjects: retainedObjects)
  }
}

final class NativeDialogTextLengthLimiter: NSObject, UITextFieldDelegate {
  let maxLength: Int?

  init(maxLength: Int?) {
    self.maxLength = maxLength
  }

  func limited(_ value: String) -> String {
    guard let maxLength, value.count > maxLength else { return value }
    return String(value.prefix(maxLength))
  }

  func textField(
    _ textField: UITextField,
    shouldChangeCharactersIn range: NSRange,
    replacementString string: String
  ) -> Bool {
    guard let maxLength else { return true }
    guard textField.markedTextRange == nil else { return true }
    guard let current = textField.text, let swiftRange = Range(range, in: current) else { return false }
    return current.replacingCharacters(in: swiftRange, with: string).count <= maxLength
  }
}

enum NativeDialogPresenter {
  static func topViewControllerInActiveScene(application: UIApplication = .shared) -> UIViewController? {
    let activeScenes = application.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .filter { $0.activationState == .foregroundActive }

    let window = activeScenes
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)
      ?? activeScenes.flatMap(\.windows).first(where: { !$0.isHidden && $0.alpha > 0 && $0.windowLevel == .normal })

    guard let root = window?.rootViewController else { return nil }
    return topViewController(from: root)
  }

  static func topViewController(from controller: UIViewController) -> UIViewController {
    if let presented = controller.presentedViewController, !presented.isBeingDismissed {
      return topViewController(from: presented)
    }
    if let navigation = controller as? UINavigationController, let visible = navigation.visibleViewController {
      return topViewController(from: visible)
    }
    if let tab = controller as? UITabBarController, let selected = tab.selectedViewController {
      return topViewController(from: selected)
    }
    if let split = controller as? UISplitViewController,
       let visible = split.viewControllers.reversed().first(where: { $0.viewIfLoaded?.window != nil })
        ?? split.viewControllers.last {
      return topViewController(from: visible)
    }
    return controller
  }
}

private final class NativeDialogCompletionRelay {
  weak var session: NativeDialogPresentationSession?

  func complete(_ completion: NativeDialogCompletion) {
    session?.complete(completion)
  }
}

final class NativeDialogPresentationSession: NSObject, UIAdaptivePresentationControllerDelegate {
  let alert: UIAlertController
  private let retainedObjects: [AnyObject]
  private var result: FlutterResult?
  private weak var owner: NativeDialogPlugin?

  init(
    preparedDialog: NativeDialogPreparedDialog,
    result: @escaping FlutterResult,
    owner: NativeDialogPlugin?
  ) {
    alert = preparedDialog.alert
    retainedObjects = preparedDialog.retainedObjects
    self.result = result
    self.owner = owner
  }

  var isPresentedOrTransitioning: Bool {
    alert.presentingViewController != nil
      || alert.viewIfLoaded?.window != nil
      || alert.isBeingPresented
      || alert.isBeingDismissed
  }

  func complete(_ completion: NativeDialogCompletion) {
    guard let result else { return }
    self.result = nil

    switch completion {
    case let .action(id): result(id)
    case .confirmed: result(true)
    case let .text(text): result(text)
    case .cancelled: result(nil)
    }
  }

  func failPresentation() {
    guard let result else { return }
    self.result = nil
    result(
      FlutterError(
        code: NativeDialogErrorCode.presentationFailed.rawValue,
        message: "UIKit did not present the native dialog.",
        details: nil
      )
    )
  }

  func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    complete(.cancelled)
    owner?.presentationSessionDidEnd(self)
  }
}
