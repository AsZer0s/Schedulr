import Flutter
import UIKit
import XCTest
@testable import Runner

final class RunnerTests: XCTestCase {
  func testActionSheetRequestParsesStableIDsAndDestructiveFlags() throws {
    let request = try NativeDialogRequest.parse(
      method: .showActionSheet,
      arguments: [
        "title": "Choose",
        "message": NSNull(),
        "cancelLabel": "Cancel",
        "actions": [
          ["id": "edit", "label": "Edit", "destructive": false],
          ["id": "delete", "label": "Delete", "destructive": true],
        ],
      ]
    )

    guard case let .actionSheet(title, message, cancelLabel, actions) = request else {
      return XCTFail("Expected an action-sheet request")
    }
    XCTAssertEqual(title, "Choose")
    XCTAssertNil(message)
    XCTAssertEqual(cancelLabel, "Cancel")
    XCTAssertEqual(
      actions,
      [
        NativeDialogAction(id: "edit", label: "Edit", isDestructive: false),
        NativeDialogAction(id: "delete", label: "Delete", isDestructive: true),
      ]
    )
  }

  func testInvalidArgumentsProduceTypedError() {
    XCTAssertThrowsError(
      try NativeDialogRequest.parse(
        method: .showActionSheet,
        arguments: [
          "cancelLabel": "Cancel",
          "actions": [
            ["id": "same", "label": "First"],
            ["id": "same", "label": "Second"],
          ],
        ]
      )
    ) { error in
      guard let requestError = error as? NativeDialogRequestError else {
        return XCTFail("Expected NativeDialogRequestError")
      }
      XCTAssertEqual(requestError.field, "actions[1].id")
      XCTAssertEqual(
        requestError.flutterError(method: "showActionSheet").code,
        NativeDialogErrorCode.invalidArguments.rawValue
      )
    }
  }

  func testConfirmationFactoryUsesDestructiveConfirmAndCancelActions() throws {
    let request = try NativeDialogRequest.parse(
      method: .showConfirmation,
      arguments: [
        "title": "Delete course?",
        "message": "This cannot be undone.",
        "confirmLabel": "Delete",
        "cancelLabel": "Cancel",
        "destructive": true,
      ]
    )

    let prepared = NativeDialogAlertFactory.make(request: request) { _ in }

    XCTAssertEqual(prepared.alert.preferredStyle, .alert)
    XCTAssertEqual(prepared.alert.actions.map(\.title), ["Delete", "Cancel"])
    XCTAssertEqual(prepared.alert.actions.map(\.style), [.destructive, .cancel])
  }

  func testTextInputFactoryConfiguresFieldAndLimitsInitialValue() throws {
    let request = try NativeDialogRequest.parse(
      method: .showTextInput,
      arguments: [
        "title": "Rename",
        "message": NSNull(),
        "initialValue": "abcdef",
        "confirmLabel": "Save",
        "cancelLabel": "Cancel",
        "placeholder": "Name",
        "maxLength": 4,
      ]
    )

    let prepared = NativeDialogAlertFactory.make(request: request) { _ in }
    let textField = try XCTUnwrap(prepared.alert.textFields?.first)

    XCTAssertEqual(textField.text, "abcd")
    XCTAssertEqual(textField.placeholder, "Name")
    XCTAssertTrue(textField.delegate is NativeDialogTextLengthLimiter)
    XCTAssertEqual(prepared.alert.actions.map(\.style), [.default, .cancel])
  }

  func testTextLengthLimiterAcceptsReplacementAtLimitAndRejectsOverflow() {
    let limiter = NativeDialogTextLengthLimiter(maxLength: 4)
    let textField = UITextField()
    textField.text = "abc"

    XCTAssertTrue(
      limiter.textField(
        textField,
        shouldChangeCharactersIn: NSRange(location: 3, length: 0),
        replacementString: "d"
      )
    )
    XCTAssertFalse(
      limiter.textField(
        textField,
        shouldChangeCharactersIn: NSRange(location: 3, length: 0),
        replacementString: "de"
      )
    )
  }

  func testTopViewControllerTraversesNavigationAndTabs() {
    let first = UIViewController()
    let selected = UIViewController()
    let tabs = UITabBarController()
    tabs.viewControllers = [first, selected]
    tabs.selectedViewController = selected
    let navigation = UINavigationController(rootViewController: tabs)

    XCTAssertTrue(NativeDialogPresenter.topViewController(from: navigation) === selected)
  }

  func testPresentationSessionResolvesFlutterResultExactlyOnce() {
    let prepared = NativeDialogPreparedDialog(
      alert: UIAlertController(title: nil, message: nil, preferredStyle: .alert),
      retainedObjects: []
    )
    var values: [Any?] = []
    let session = NativeDialogPresentationSession(
      preparedDialog: prepared,
      result: { values.append($0) },
      owner: nil
    )

    session.complete(.action(id: "chosen"))
    session.complete(.cancelled)
    session.failPresentation()

    XCTAssertEqual(values.count, 1)
    XCTAssertEqual(values.first as? String, "chosen")
  }

  func testAdaptiveDismissalResolvesCancellationExactlyOnce() {
    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    let prepared = NativeDialogPreparedDialog(alert: alert, retainedObjects: [])
    var invocationCount = 0
    var valueWasNil = false
    let session = NativeDialogPresentationSession(
      preparedDialog: prepared,
      result: { value in
        invocationCount += 1
        valueWasNil = value == nil
      },
      owner: nil
    )
    let presentationController = UIPresentationController(
      presentedViewController: alert,
      presenting: UIViewController()
    )

    session.presentationControllerDidDismiss(presentationController)
    session.complete(.cancelled)

    XCTAssertEqual(invocationCount, 1)
    XCTAssertTrue(valueWasNil)
  }

  func testConfirmationCompletionReturnsBooleanTrue() {
    let prepared = NativeDialogPreparedDialog(
      alert: UIAlertController(title: nil, message: nil, preferredStyle: .alert),
      retainedObjects: []
    )
    var value: Any?
    let session = NativeDialogPresentationSession(
      preparedDialog: prepared,
      result: { value = $0 },
      owner: nil
    )

    session.complete(.confirmed)

    XCTAssertEqual(value as? Bool, true)
  }
}
