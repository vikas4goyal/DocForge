import CoreImage
import Flutter
import Metal
import UIKit

private let imageProcessingSchemaVersion = 1
private let colourPipelineVersion = 1

enum NativeImageProcessingError: Error {
  case failure(String, String)
}

struct NativeEnhancementRequest {
  let filter: String
  let brightness: Double
  let contrast: Double
  let sharpen: Double
  let shadowRemoval: Bool
}

struct NativeHomography {
  let values: [Double]
}

struct NativeRenderRequest {
  let requestID: String
  let sourceURL: URL
  let destinationURL: URL
  let preview: Bool
  let maximumPreviewDimension: Int?
  let outputWidth: Int?
  let outputHeight: Int?
  let jpegQuality: Int
  let enhancement: NativeEnhancementRequest
  let homography: NativeHomography?

  static func parse(_ value: Any?, fileManager: FileManager = .default) throws -> Self {
    guard let map = value as? [String: Any], map["schemaVersion"] as? Int == imageProcessingSchemaVersion,
      map["colourPipelineVersion"] as? Int == colourPipelineVersion,
      let requestID = map["requestId"] as? String, !requestID.trimmingCharacters(in: .whitespaces).isEmpty,
      let sourcePath = map["sourcePath"] as? String,
      let destinationPath = map["destinationPath"] as? String,
      let scale = map["scale"] as? String, ["preview", "full_resolution"].contains(scale),
      let quality = map["jpegQuality"] as? Int, (1...100).contains(quality),
      let settings = map["enhancement"] as? [String: Any],
      let filter = settings["filter"] as? String,
      ["original", "autoEnhance", "magicColour", "blackAndWhite", "grayscale"].contains(filter),
      let brightness = (settings["brightness"] as? NSNumber)?.doubleValue,
      let contrast = (settings["contrast"] as? NSNumber)?.doubleValue,
      let sharpen = (settings["sharpen"] as? NSNumber)?.doubleValue,
      let shadowRemoval = settings["shadowRemoval"] as? Bool,
      brightness.isFinite, contrast.isFinite, sharpen.isFinite,
      (-0.35...0.35).contains(brightness), (-0.5...0.5).contains(contrast),
      (0...0.6).contains(sharpen)
    else { throw NativeImageProcessingError.failure("invalid_request", "invalid schema or field") }

    let sourceURL = URL(fileURLWithPath: sourcePath).standardizedFileURL.resolvingSymlinksInPath()
    let destinationURL = URL(fileURLWithPath: destinationPath).standardizedFileURL.resolvingSymlinksInPath()
    guard isApplicationOwned(sourceURL), isApplicationOwned(destinationURL),
      sourceURL != destinationURL, fileManager.fileExists(atPath: sourceURL.path)
    else { throw NativeImageProcessingError.failure("invalid_path", "path rejected") }

    let width = map["outputWidth"] as? Int
    let height = map["outputHeight"] as? Int
    guard (width == nil) == (height == nil), width.map({ $0 > 0 }) ?? true,
      height.map({ $0 > 0 }) ?? true
    else { throw NativeImageProcessingError.failure("invalid_request", "invalid dimensions") }
    let previewDimension = map["maximumPreviewDimension"] as? Int
    guard previewDimension.map({ $0 > 0 }) ?? true else {
      throw NativeImageProcessingError.failure("invalid_request", "invalid preview size")
    }

    var homography: NativeHomography?
    if let transform = map["transform"] as? [String: Any] {
      let keys = ["h00", "h01", "h02", "h10", "h11", "h12", "h20", "h21"]
      let coefficients = keys.compactMap { (transform[$0] as? NSNumber)?.doubleValue }
      guard coefficients.count == 8, coefficients.allSatisfy(\.isFinite), width != nil else {
        throw NativeImageProcessingError.failure("invalid_request", "invalid homography")
      }
      homography = NativeHomography(values: coefficients)
    }

    return Self(
      requestID: requestID, sourceURL: sourceURL, destinationURL: destinationURL,
      preview: scale == "preview", maximumPreviewDimension: previewDimension,
      outputWidth: width, outputHeight: height, jpegQuality: quality,
      enhancement: NativeEnhancementRequest(
        filter: filter, brightness: brightness, contrast: contrast,
        sharpen: sharpen, shadowRemoval: shadowRemoval), homography: homography)
  }

  private static func isApplicationOwned(_ url: URL) -> Bool {
    let roots = [URL(fileURLWithPath: NSHomeDirectory()), URL(fileURLWithPath: NSTemporaryDirectory())]
      .map { $0.standardizedFileURL.resolvingSymlinksInPath().pathComponents }
    return roots.contains { root in Array(url.pathComponents.prefix(root.count)) == root }
  }
}

/// Serial, Metal-backed Core Image renderer. Core Image evaluates its graph in
/// bounded regions of interest, so oversized images are tiled without passing
/// decoded pixel buffers through Flutter or retaining a full intermediate tree.
final class DocScanlyImageProcessor {
  private let queue = DispatchQueue(label: "com.bruxkey.docscanly.image-processing", qos: .userInitiated)
  private let stateLock = NSLock()
  private var cancelled = Set<String>()
  private var disposed = false
  private let device: MTLDevice?
  private var context: CIContext?
  private var cachedSource: (url: URL, modified: Date, image: CIImage)?
  private(set) var maximumTextureSize = 0

  init(
    device: MTLDevice? = MTLCreateSystemDefaultDevice(),
    maximumTextureSize: Int = 16_384
  ) {
    self.device = device
    if let device {
      context = CIContext(mtlDevice: device, options: [.cacheIntermediates: false])
      self.maximumTextureSize = device.maxThreadsPerThreadgroup.width > 0
        ? maximumTextureSize : 0
    }
  }

  var capability: [String: Any] {
    ["schemaVersion": imageProcessingSchemaVersion, "backend": "ios_core_image",
     "isSupported": context != nil, "maximumTextureSize": maximumTextureSize,
     "supportsTiling": context != nil]
  }

  func render(_ arguments: Any?, completion: @escaping ([String: Any]) -> Void) {
    queue.async { [weak self] in
      guard let self else { return }
      let response: [String: Any]
      do { response = try self.perform(NativeRenderRequest.parse(arguments)) }
      catch NativeImageProcessingError.failure(let kind, let detail) {
        response = Self.failure(kind, detail)
      } catch { response = Self.failure("unexpected", "native render failed") }
      DispatchQueue.main.async { completion(response) }
    }
  }

  func cancel(_ requestID: String) { stateLock.withLock { _ = cancelled.insert(requestID) } }

  func dispose() {
    stateLock.withLock {
      disposed = true
      cancelled.removeAll()
      cachedSource = nil
      context?.clearCaches()
      context = nil
    }
  }

  func releaseResources() {
    stateLock.withLock {
      cachedSource = nil
      context?.clearCaches()
    }
  }

  /// Simulates a lost Core Image context for deterministic XCTest coverage.
  func invalidateContextForTesting() {
    stateLock.withLock {
      context?.clearCaches()
      context = nil
    }
  }

  private func perform(_ request: NativeRenderRequest) throws -> [String: Any] {
    let totalStart = DispatchTime.now().uptimeNanoseconds
    try check(request.requestID)
    let context = stateLock.withLock { () -> CIContext? in
      if self.context == nil, !disposed, let device {
        self.context = CIContext(mtlDevice: device, options: [.cacheIntermediates: false])
      }
      return self.context
    }
    guard let context else {
      throw NativeImageProcessingError.failure("unsupported", "Metal unavailable")
    }
    let decodeStart = DispatchTime.now().uptimeNanoseconds
    let sourceValues = try? request.sourceURL.resourceValues(
      forKeys: [.contentModificationDateKey]
    )
    let modified = sourceValues?.contentModificationDate ?? .distantPast
    var image: CIImage
    if let cached = stateLock.withLock({ cachedSource }),
      cached.url == request.sourceURL, cached.modified == modified
    {
      image = cached.image
    } else {
      guard var decoded = CIImage(contentsOf: request.sourceURL, options: [
        .applyOrientationProperty: true,
        .colorSpace: CGColorSpace(name: CGColorSpace.sRGB) as Any,
      ]) else { throw NativeImageProcessingError.failure("corrupt_input", "decode failed") }
      decoded = decoded.transformed(by: CGAffineTransform(
        translationX: -decoded.extent.minX,
        y: -decoded.extent.minY
      ))
      image = decoded
      stateLock.withLock { cachedSource = (request.sourceURL, modified, decoded) }
    }
    let sourceWidth = Int(image.extent.width.rounded())
    let sourceHeight = Int(image.extent.height.rounded())
    let decodeEnd = DispatchTime.now().uptimeNanoseconds
    try check(request.requestID)

    if let transform = request.homography, let width = request.outputWidth, let height = request.outputHeight {
      image = try warp(image, transform: transform, width: width, height: height)
    }
    if request.preview, let maximum = request.maximumPreviewDimension {
      let longest = max(image.extent.width, image.extent.height)
      if longest > CGFloat(maximum) {
        let factor = CGFloat(maximum) / longest
        let targetWidth = max(1, Int((image.extent.width * factor).rounded()))
        let targetHeight = max(1, Int((image.extent.height * factor).rounded()))
        image = image.transformed(by: CGAffineTransform(scaleX: factor, y: factor))
          .cropped(to: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))
      }
    }
    image = image.cropped(to: CGRect(x: 0, y: 0, width: floor(image.extent.width), height: floor(image.extent.height)))
    image = try enhance(image, request.enhancement, context: context)
    try check(request.requestID)
    let transformEnd = DispatchTime.now().uptimeNanoseconds

    let manager = FileManager.default
    try manager.createDirectory(at: request.destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    let temporary = request.destinationURL.deletingLastPathComponent()
      .appendingPathComponent(".\(request.destinationURL.lastPathComponent).native-\(UUID().uuidString).tmp")
    defer { try? manager.removeItem(at: temporary); stateLock.withLock { _ = cancelled.remove(request.requestID) } }
    do {
      try context.writeJPEGRepresentation(
        of: image, to: temporary, colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
        options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: Double(request.jpegQuality) / 100])
      try check(request.requestID)
      if manager.fileExists(atPath: request.destinationURL.path) {
        _ = try manager.replaceItemAt(request.destinationURL, withItemAt: temporary)
      } else { try manager.moveItem(at: temporary, to: request.destinationURL) }
    } catch let error as NativeImageProcessingError { throw error }
      catch { throw NativeImageProcessingError.failure("storage", "output write failed") }
    let encodeEnd = DispatchTime.now().uptimeNanoseconds

    func micros(_ start: UInt64, _ end: UInt64) -> Int { Int((end - start) / 1_000) }
    return ["schemaVersion": imageProcessingSchemaVersion, "result": [
      "destinationPath": request.destinationURL.path, "sourceWidth": sourceWidth,
      "sourceHeight": sourceHeight, "outputWidth": Int(image.extent.width),
      "outputHeight": Int(image.extent.height), "backend": "ios_core_image",
      "timings": ["decodeMicroseconds": micros(decodeStart, decodeEnd),
        "transformMicroseconds": micros(decodeEnd, transformEnd),
        "encodeMicroseconds": micros(transformEnd, encodeEnd),
        "totalMicroseconds": micros(totalStart, encodeEnd)]]]
  }

  private func check(_ requestID: String) throws {
    let stopped = stateLock.withLock { disposed || cancelled.contains(requestID) }
    if stopped { throw NativeImageProcessingError.failure("cancelled", "request cancelled") }
  }

  private func warp(_ input: CIImage, transform: NativeHomography, width: Int, height: Int) throws -> CIImage {
    let h = transform.values
    func point(_ x: Double, _ y: Double) throws -> CIVector {
      let denominator = h[6] * x + h[7] * y + 1
      guard denominator.isFinite, abs(denominator) > 0.000_001 else {
        throw NativeImageProcessingError.failure("invalid_request", "singular homography")
      }
      let sourceX = (h[0] * x + h[1] * y + h[2]) / denominator
      let sourceY = (h[3] * x + h[4] * y + h[5]) / denominator
      guard sourceX.isFinite, sourceY.isFinite else {
        throw NativeImageProcessingError.failure("invalid_request", "invalid homography projection")
      }
      return CIVector(x: sourceX, y: input.extent.height - 1 - sourceY)
    }
    let corrected = input.applyingFilter("CIPerspectiveCorrection", parameters: [
      "inputTopLeft": try point(0, 0),
      "inputTopRight": try point(Double(width - 1), 0),
      "inputBottomRight": try point(Double(width - 1), Double(height - 1)),
      "inputBottomLeft": try point(0, Double(height - 1)),
    ])
    guard corrected.extent.width > 0, corrected.extent.height > 0 else {
      throw NativeImageProcessingError.failure("invalid_request", "empty geometry output")
    }
    let normalized = corrected.transformed(by: CGAffineTransform(
      translationX: -corrected.extent.minX, y: -corrected.extent.minY))
    let scale = CGAffineTransform(
      scaleX: CGFloat(width) / normalized.extent.width,
      y: CGFloat(height) / normalized.extent.height)
    return normalized.transformed(by: scale).cropped(
      to: CGRect(x: 0, y: 0, width: width, height: height))
  }

  private func enhance(_ input: CIImage, _ settings: NativeEnhancementRequest, context: CIContext) throws -> CIImage {
    let radius = max(1, (min(input.extent.width, input.extent.height) * 0.05).rounded())
    let needsBlur = settings.shadowRemoval || settings.sharpen > 0 || settings.filter == "blackAndWhite"
    let blurred = needsBlur ? input.clampedToExtent().applyingFilter("CIBoxBlur", parameters: [kCIInputRadiusKey: radius]).cropped(to: input.extent) : nil
    var output = input
    if settings.shadowRemoval, let blurred {
      let reference = illuminationReference(blurred, context: context)
      output = try colorKernel("""
        kernel vec4 shadow(__sample s, __sample b, float reference) {
          float lum = dot(b.rgb, vec3(0.299, 0.587, 0.114));
          float gain = lum < (1.0/255.0) ? 1.0 : min(reference / lum, 3.0);
          return vec4(clamp(s.rgb * gain, 0.0, 1.0), s.a);
        }
        """, [output, blurred, reference])
    }
    switch settings.filter {
    case "grayscale": output = output.applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: 0])
    case "autoEnhance": output = autoLevels(output, context: context)
    case "magicColour":
      output = autoLevels(output, context: context)
      output = try colorKernel("""
        kernel vec4 magic(__sample s) { float l=dot(s.rgb,vec3(0.299,0.587,0.114)); vec3 c=clamp(l+(s.rgb-l)*1.45,0.0,1.0); return vec4(clamp(0.5+(c-0.5)*1.45,0.0,1.0),s.a); }
        """, [output])
    case "blackAndWhite":
      if let blurred { output = try colorKernel("""
        kernel vec4 bw(__sample s, __sample b) { float l=dot(s.rgb,vec3(0.299,0.587,0.114)); float m=dot(b.rgb,vec3(0.299,0.587,0.114)); float v=l < m-(8.0/255.0) ? 0.0 : 1.0; return vec4(v,v,v,s.a); }
        """, [output, blurred]) }
    default: break
    }
    if settings.brightness != 0 || settings.contrast != 0 {
      let factor = settings.contrast >= 0 ? 1 + settings.contrast * 3 : 1 + settings.contrast
      output = try colorKernel("""
        kernel vec4 adjust(__sample s, float brightness, float contrast) { vec3 c=clamp(0.5+(s.rgb+brightness-0.5)*contrast,0.0,1.0); return vec4(c,s.a); }
        """, [output, settings.brightness, factor])
    }
    if settings.sharpen > 0, let blurred {
      output = try colorKernel("""
        kernel vec4 sharpen(__sample s, __sample b, float amount) { float a=(dot(s.rgb,vec3(0.299,0.587,0.114))-dot(b.rgb,vec3(0.299,0.587,0.114)))*amount*3.0; return vec4(clamp(s.rgb+a,0.0,1.0),s.a); }
        """, [output, blurred, settings.sharpen])
    }
    return output.cropped(to: input.extent)
  }

  private func colorKernel(_ source: String, _ arguments: [Any]) throws -> CIImage {
    guard let kernel = CIColorKernel(source: source), let result = kernel.apply(extent: (arguments[0] as! CIImage).extent, arguments: arguments) else {
      throw NativeImageProcessingError.failure("shader", "colour kernel unavailable")
    }
    return result
  }

  private func autoLevels(_ image: CIImage, context: CIContext) -> CIImage {
    let bounds = channelBounds(image, context: context)
    let scale = CIVector(x: 1 / max(bounds.high.x - bounds.low.x, 1.0 / 255),
      y: 1 / max(bounds.high.y - bounds.low.y, 1.0 / 255),
      z: 1 / max(bounds.high.z - bounds.low.z, 1.0 / 255), w: 1)
    let bias = CIVector(x: -bounds.low.x * scale.x, y: -bounds.low.y * scale.y,
      z: -bounds.low.z * scale.z, w: 0)
    return image.applyingFilter("CIColorMatrix", parameters: ["inputRVector": CIVector(x: scale.x, y: 0, z: 0, w: 0),
      "inputGVector": CIVector(x: 0, y: scale.y, z: 0, w: 0), "inputBVector": CIVector(x: 0, y: 0, z: scale.z, w: 0),
      "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1), "inputBiasVector": bias])
  }

  private func channelBounds(_ image: CIImage, context: CIContext) -> (low: CIVector, high: CIVector) {
    guard let histogram = CIFilter(name: "CIAreaHistogram", parameters: [kCIInputImageKey: image,
      kCIInputExtentKey: CIVector(cgRect: image.extent), "inputCount": 256, "inputScale": 1]),
      let output = histogram.outputImage else { return (CIVector(x: 0, y: 0, z: 0), CIVector(x: 1, y: 1, z: 1)) }
    var data = [Float](repeating: 0, count: 256 * 4)
    context.render(output, toBitmap: &data, rowBytes: 256 * 16, bounds: CGRect(x: 0, y: 0, width: 256, height: 1),
      format: .RGBAf, colorSpace: CGColorSpace(name: CGColorSpace.sRGB))
    func limits(_ channel: Int) -> (CGFloat, CGFloat) {
      let total = stride(from: channel, to: data.count, by: 4).reduce(0.0) { $0 + Double(data[$1]) }
      let clip = total * 0.005
      var sum = 0.0, low = 0, high = 255
      for i in 0..<256 { sum += Double(data[i*4+channel]); if sum > clip { low=i; break } }
      sum = 0
      for i in stride(from: 255, through: 0, by: -1) { sum += Double(data[i*4+channel]); if sum > clip { high=i; break } }
      if high - low < 8 { return (0, 1) }
      return (CGFloat(low)/255, CGFloat(high)/255)
    }
    let r=limits(0), g=limits(1), b=limits(2)
    return (CIVector(x:r.0,y:g.0,z:b.0), CIVector(x:r.1,y:g.1,z:b.1))
  }

  private func illuminationReference(_ image: CIImage, context: CIContext) -> Double {
    guard let histogram = CIFilter(name: "CIAreaHistogram", parameters: [kCIInputImageKey: image,
      kCIInputExtentKey: CIVector(cgRect: image.extent), "inputCount": 256, "inputScale": 1])?.outputImage else { return 1 }
    var data = [Float](repeating: 0, count: 1024)
    let bounds = CGRect(x: 0, y: 0, width: 256, height: 1)
    let colourSpace = CGColorSpace(name: CGColorSpace.sRGB)
    context.render(
      histogram,
      toBitmap: &data,
      rowBytes: 4096,
      bounds: bounds,
      format: .RGBAf,
      colorSpace: colourSpace
    )
    var weights = [Double](repeating: 0, count: 256)
    for index in 0..<256 {
      weights[index] = Double(data[index * 4])
        + Double(data[index * 4 + 1])
        + Double(data[index * 4 + 2])
    }
    let threshold = weights.reduce(0, +) * 0.95
    var sum = 0.0
    for index in 0..<256 {
      sum += weights[index]
      if sum >= threshold { return max(Double(index) / 255, 1.0 / 255) }
    }
    return 1
  }

  private static func failure(_ kind: String, _ detail: String) -> [String: Any] {
    ["schemaVersion": imageProcessingSchemaVersion, "failureKind": kind, "debugDetail": detail]
  }
}

final class DocScanlyImageProcessingBridge {
  private let channel: FlutterMethodChannel
  private let processor: DocScanlyImageProcessor

  init(messenger: FlutterBinaryMessenger, processor: DocScanlyImageProcessor = DocScanlyImageProcessor()) {
    self.processor = processor
    channel = FlutterMethodChannel(name: "com.bruxkey.docscanly/image_processing_v1", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { result(FlutterMethodNotImplemented); return }
      switch call.method {
      case "capability": result(self.processor.capability)
      case "render": self.processor.render(call.arguments, completion: result)
      case "cancel":
        if let map=call.arguments as? [String:Any], let id=map["requestId"] as? String { self.processor.cancel(id) }
        result(nil)
      case "dispose": self.processor.dispose(); self.channel.setMethodCallHandler(nil); result(nil)
      default: result(FlutterMethodNotImplemented)
      }
    }
    NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: .main) { [weak processor] _ in processor?.releaseResources() }
  }

  deinit { channel.setMethodCallHandler(nil); processor.dispose(); NotificationCenter.default.removeObserver(self) }
}

private extension NSLock {
  func withLock<T>(_ body: () -> T) -> T { lock(); defer { unlock() }; return body() }
}
