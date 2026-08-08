import Flutter
import UIKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var iCloudBridge: DocScanlyICloudBridge?
  private var imageProcessingBridge: DocScanlyImageProcessingBridge?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Kept by the application delegate so method/event handlers and scoped
    // document-picker URLs live for exactly as long as the Flutter engine.
    iCloudBridge = DocScanlyICloudBridge(
      messenger: engineBridge.applicationRegistrar.messenger()
    )
    imageProcessingBridge = DocScanlyImageProcessingBridge(
      messenger: engineBridge.applicationRegistrar.messenger()
    )
  }
}

/// Bridges DocScanly's registered iCloud Documents container to Dart.
///
/// Policy stays in Dart use cases. This type only resolves Foundation state,
/// coordinates file access, and maps platform outcomes to stable codes.
final class DocScanlyICloudBridge: NSObject, FlutterStreamHandler,
  UIDocumentPickerDelegate
{
  private static let containerIdentifier = "iCloud.com.bruxkey.docscanly"
  private static let markerName = ".docscanly-library.json"

  private let methods: FlutterMethodChannel
  private let events: FlutterEventChannel
  private var eventSink: FlutterEventSink?
  private var pickerResult: FlutterResult?
  private var scopedURLs: [String: URL] = [:]

  init(messenger: FlutterBinaryMessenger) {
    methods = FlutterMethodChannel(
      name: "com.bruxkey.docscanly/icloud",
      binaryMessenger: messenger
    )
    events = FlutterEventChannel(
      name: "com.bruxkey.docscanly/icloud_identity",
      binaryMessenger: messenger
    )
    super.init()
    methods.setMethodCallHandler(handle)
    events.setStreamHandler(self)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(identityDidChange),
      name: .NSUbiquityIdentityDidChange,
      object: nil
    )
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
    for url in scopedURLs.values { url.stopAccessingSecurityScopedResource() }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "availability": availability(result)
    case "documentRootPath": withDocumentRoot(result) { root in root.path }
    case "readMarker": readMarker(result)
    case "writeMarker": writeMarker(call.arguments, result: result)
    case "deleteMarker": deleteMarker(result)
    case "listItems": listItems(result)
    case "ensureDownloaded": ensureDownloaded(call.arguments, result: result)
    case "pickImportFolder": pickImportFolder(result)
    case "releaseImportFolder": releaseImportFolder(call.arguments, result: result)
    default: result(FlutterMethodNotImplemented)
    }
  }

  private func availability(_ result: @escaping FlutterResult) {
    guard FileManager.default.ubiquityIdentityToken != nil else {
      result("signedOut")
      return
    }
    // Apple documents that container lookup can block, so it never runs on
    // Flutter's platform thread.
    DispatchQueue.global(qos: .userInitiated).async {
      let url = FileManager.default.url(
        forUbiquityContainerIdentifier: Self.containerIdentifier
      )
      DispatchQueue.main.async { result(url == nil ? "unavailable" : "available") }
    }
  }

  private func withDocumentRoot<T>(
    _ result: @escaping FlutterResult,
    operation: @escaping (URL) throws -> T
  ) {
    DispatchQueue.global(qos: .userInitiated).async {
      guard
        let container = FileManager.default.url(
          forUbiquityContainerIdentifier: Self.containerIdentifier
        )
      else {
        DispatchQueue.main.async {
          result(FlutterError(code: "unavailable", message: nil, details: nil))
        }
        return
      }
      let root = container.appendingPathComponent("Documents", isDirectory: true)
      do {
        try FileManager.default.createDirectory(
          at: root,
          withIntermediateDirectories: true
        )
        let value = try operation(root)
        DispatchQueue.main.async { result(value) }
      } catch {
        // Do not return paths or document names through diagnostics.
        DispatchQueue.main.async {
          result(FlutterError(code: "io_error", message: nil, details: nil))
        }
      }
    }
  }

  private func readMarker(_ result: @escaping FlutterResult) {
    withDocumentRoot(result) { root in
      let marker = root.appendingPathComponent(Self.markerName)
      guard FileManager.default.fileExists(atPath: marker.path) else {
        return Optional<[String: Any]>.none
      }
      var coordinationError: NSError?
      var data: Data?
      NSFileCoordinator().coordinate(
        readingItemAt: marker,
        options: [],
        error: &coordinationError
      ) { coordinatedURL in
        data = try? Data(contentsOf: coordinatedURL)
      }
      if let coordinationError { throw coordinationError }
      guard let data else { throw CocoaError(.fileReadUnknown) }
      return try JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
  }

  private func writeMarker(_ arguments: Any?, result: @escaping FlutterResult) {
    guard let values = arguments as? [String: Any] else {
      result(FlutterError(code: "invalid_arguments", message: nil, details: nil))
      return
    }
    withDocumentRoot(result) { root in
      let data = try JSONSerialization.data(withJSONObject: values, options: [.sortedKeys])
      let destination = root.appendingPathComponent(Self.markerName)
      var coordinationError: NSError?
      var writeError: Error?
      NSFileCoordinator().coordinate(
        writingItemAt: destination,
        options: .forReplacing,
        error: &coordinationError
      ) { coordinatedURL in
        do { try data.write(to: coordinatedURL, options: [.atomic]) }
        catch { writeError = error }
      }
      if let coordinationError { throw coordinationError }
      if let writeError { throw writeError }
      return true
    }
  }

  private func deleteMarker(_ result: @escaping FlutterResult) {
    withDocumentRoot(result) { root in
      let marker = root.appendingPathComponent(Self.markerName)
      guard FileManager.default.fileExists(atPath: marker.path) else { return true }
      var coordinationError: NSError?
      var removalError: Error?
      NSFileCoordinator().coordinate(
        writingItemAt: marker,
        options: .forDeleting,
        error: &coordinationError
      ) { coordinatedURL in
        do { try FileManager.default.removeItem(at: coordinatedURL) }
        catch { removalError = error }
      }
      if let coordinationError { throw coordinationError }
      if let removalError { throw removalError }
      return true
    }
  }

  private func listItems(_ result: @escaping FlutterResult) {
    withDocumentRoot(result) { root in
      let keys: [URLResourceKey] = [
        .isDirectoryKey,
        .fileSizeKey,
        .contentModificationDateKey,
        .fileResourceIdentifierKey,
        .ubiquitousItemDownloadingStatusKey,
      ]
      guard let enumerator = FileManager.default.enumerator(
        at: root,
        includingPropertiesForKeys: keys,
        options: [.skipsHiddenFiles]
      ) else { return [] }

      var items: [[String: Any]] = []
      for case let url as URL in enumerator {
        let values = try url.resourceValues(forKeys: Set(keys))
        let relative = String(url.path.dropFirst(root.path.count + 1))
        let isDownloaded = values.ubiquitousItemDownloadingStatus != .notDownloaded
        items.append([
          "relativePath": relative,
          "isDirectory": values.isDirectory ?? false,
          "availability": isDownloaded ? "available" : "remote",
          "resourceIdentifier": values.fileResourceIdentifier.map { String(describing: $0) }
            as Any,
          "sizeBytes": values.fileSize ?? 0,
          "modifiedMilliseconds": values.contentModificationDate.map {
            Int($0.timeIntervalSince1970 * 1000)
          } as Any,
        ])
      }
      return items
    }
  }

  private func ensureDownloaded(_ arguments: Any?, result: @escaping FlutterResult) {
    guard
      let values = arguments as? [String: Any],
      let relative = values["relativePath"] as? String,
      !relative.contains(".."),
      !relative.hasPrefix("/")
    else {
      result(FlutterError(code: "invalid_arguments", message: nil, details: nil))
      return
    }
    withDocumentRoot(result) { root in
      let url = root.appendingPathComponent(relative)
      guard FileManager.default.fileExists(atPath: url.path) else {
        throw CocoaError(.fileNoSuchFile)
      }
      try FileManager.default.startDownloadingUbiquitousItem(at: url)

      // startDownloadingUbiquitousItem only schedules transfer. Returning at
      // that point lets Flutter hand a placeholder URL to PDFium, which looks
      // like a corrupt document. Poll metadata on this background queue until
      // Foundation reports readable bytes; callers receive a retryable stable
      // I/O failure if the device remains offline.
      let deadline = Date().addingTimeInterval(60)
      while Date() < deadline {
        let status = try url.resourceValues(
          forKeys: [.ubiquitousItemDownloadingStatusKey]
        ).ubiquitousItemDownloadingStatus
        if status == .current || status == .downloaded {
          var coordinationError: NSError?
          NSFileCoordinator().coordinate(
            readingItemAt: url,
            options: .withoutChanges,
            error: &coordinationError
          ) { _ in }
          if let coordinationError { throw coordinationError }
          return true
        }
        Thread.sleep(forTimeInterval: 0.2)
      }
      throw CocoaError(.fileReadUnknown)
    }
  }

  private func pickImportFolder(_ result: @escaping FlutterResult) {
    guard pickerResult == nil else {
      result(FlutterError(code: "picker_busy", message: nil, details: nil))
      return
    }
    pickerResult = result
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
    picker.delegate = self
    picker.allowsMultipleSelection = false
    guard let controller = topViewController() else {
      pickerResult = nil
      result(FlutterError(code: "unavailable", message: nil, details: nil))
      return
    }
    controller.present(picker, animated: true)
  }

  func documentPicker(
    _ controller: UIDocumentPickerViewController,
    didPickDocumentsAt urls: [URL]
  ) {
    let accepted = urls.filter { url in
      guard url.startAccessingSecurityScopedResource() else { return false }
      scopedURLs[url.path] = url
      return true
    }
    let callback = pickerResult
    pickerResult = nil
    callback?(accepted.map(\.path))
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    let callback = pickerResult
    pickerResult = nil
    callback?([])
  }

  private func releaseImportFolder(_ arguments: Any?, result: FlutterResult) {
    guard
      let values = arguments as? [String: Any],
      let paths = values["paths"] as? [String]
    else {
      result(FlutterError(code: "invalid_arguments", message: nil, details: nil))
      return
    }
    for path in paths {
      scopedURLs.removeValue(forKey: path)?.stopAccessingSecurityScopedResource()
    }
    result(nil)
  }

  private func topViewController() -> UIViewController? {
    let root = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)?
      .rootViewController
    var current = root
    while let presented = current?.presentedViewController { current = presented }
    return current
  }

  @objc private func identityDidChange() { eventSink?(nil) }

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}
