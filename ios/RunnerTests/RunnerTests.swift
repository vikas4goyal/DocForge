import Flutter
import Metal
import UIKit
import XCTest
@testable import Runner

final class RunnerTests: XCTestCase {
  private var directory: URL!

  override func setUpWithError() throws {
    // Resolved first: on a device the temporary directory is reported under
    // /private/var, and the processor's ownership check compares against the
    // resolved /var form that the app's own paths use.
    directory = URL(fileURLWithPath: NSTemporaryDirectory()).resolvingSymlinksInPath()
      .appendingPathComponent("docscanly-native-tests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  }

  override func tearDownWithError() throws {
    try? FileManager.default.removeItem(at: directory)
  }

  func testCapabilityUsesVersionedMetalBackend() throws {
    let capability = DocScanlyImageProcessor().capability
    XCTAssertEqual(capability["schemaVersion"] as? Int, 1)
    XCTAssertEqual(capability["backend"] as? String, "ios_core_image")
    XCTAssertEqual(capability["isSupported"] as? Bool, MTLCreateSystemDefaultDevice() != nil)
    XCTAssertGreaterThanOrEqual(capability["maximumTextureSize"] as? Int ?? -1, 0)
  }

  func testRejectsSchemaAndPathsOutsideApplicationContainer() throws {
    var request = validRequest(source: try fixture())
    request["schemaVersion"] = 2
    XCTAssertThrowsError(try NativeRenderRequest.parse(request))

    request = validRequest(source: try fixture())
    request["sourcePath"] = "/etc/passwd"
    XCTAssertThrowsError(try NativeRenderRequest.parse(request))
  }

  func testOriginalRenderIsAtomicAndHasExpectedDimensions() throws {
    let source = try fixture(width: 320, height: 180)
    let response = try render(validRequest(source: source))
    let result = try XCTUnwrap(response["result"] as? [String: Any])
    XCTAssertEqual(result["sourceWidth"] as? Int, 320)
    XCTAssertEqual(result["sourceHeight"] as? Int, 180)
    XCTAssertEqual(result["outputWidth"] as? Int, 320)
    XCTAssertEqual(result["outputHeight"] as? Int, 180)
    XCTAssertEqual(result["backend"] as? String, "ios_core_image")
    XCTAssertTrue(FileManager.default.fileExists(atPath: result["destinationPath"] as! String))
    XCTAssertTrue(try temporaryOutputs().isEmpty)
  }

  func testPreviewScalingAndIdentityHomography() throws {
    let source = try fixture(width: 320, height: 180)
    var request = validRequest(source: source)
    request["scale"] = "preview"
    request["maximumPreviewDimension"] = 100
    var response = try render(request)
    var result = try XCTUnwrap(response["result"] as? [String: Any])
    XCTAssertEqual(result["outputWidth"] as? Int, 100)
    XCTAssertEqual(result["outputHeight"] as? Int, 56)

    request = validRequest(source: source)
    request["outputWidth"] = 80
    request["outputHeight"] = 60
    request["transform"] = ["h00": 4.0, "h01": 0.0, "h02": 0.0,
      "h10": 0.0, "h11": 3.0, "h12": 0.0, "h20": 0.0, "h21": 0.0]
    response = try render(request)
    result = try XCTUnwrap(response["result"] as? [String: Any])
    XCTAssertEqual(result["outputWidth"] as? Int, 80)
    XCTAssertEqual(result["outputHeight"] as? Int, 60)
  }

  func testEveryFilterAndCombinedBlurConsumersProduceJpeg() throws {
    let source = try fixture(width: 96, height: 64)
    for filter in ["original", "autoEnhance", "magicColour", "blackAndWhite", "grayscale"] {
      var request = validRequest(source: source)
      request["destinationPath"] = directory.appendingPathComponent("\(filter).jpg").path
      request["enhancement"] = ["filter": filter, "brightness": 0.1,
        "contrast": 0.15, "sharpen": 0.4, "shadowRemoval": true]
      let response = try render(request)
      XCTAssertNotNil(response["result"], "filter \(filter) failed: \(response)")
      let data = try Data(contentsOf: URL(fileURLWithPath: request["destinationPath"] as! String))
      XCTAssertEqual(data.prefix(2), Data([0xff, 0xd8]))
    }
  }

  /// The preview and the saved page are the same render at different sizes, so
  /// they must look the same. Shadow removal used to read its brightness
  /// histogram back through a colour-managed render, which returned empty bins:
  /// the target brightness collapsed and the saved page came out dark, while
  /// the downscaled preview happened to escape it.
  func testShadowRemovalPreviewMatchesFullResolution() throws {
    let source = try shadowedPageFixture()
    for filter in ["original", "autoEnhance", "magicColour"] {
      let preview = try meanColour(of: renderEnhanced(source, filter: filter, preview: true))
      let full = try meanColour(of: renderEnhanced(source, filter: filter, preview: false))
      for channel in 0..<3 {
        XCTAssertEqual(preview[channel], full[channel], accuracy: 10,
          "\(filter) channel \(channel): preview \(preview) full \(full)")
      }
    }
  }

  /// Shadow removal evens out the light on the paper; it must not darken it.
  func testShadowRemovalLiftsShadowedPaperTowardsTheLitPaper() throws {
    let source = try shadowedPageFixture()
    let output = try pixels(at: renderEnhanced(source, filter: "original", preview: false))
    // Blank paper deep in the shadow (top left) and in full light (bottom right).
    let shadowed = output.meanColour(in: CGRect(x: 0.02, y: 0.02, width: 0.06, height: 0.06))
    let lit = output.meanColour(in: CGRect(x: 0.9, y: 0.9, width: 0.06, height: 0.06))
    XCTAssertGreaterThan(lit[0], 200, "lit paper went dark: \(lit)")
    XCTAssertEqual(shadowed[0], lit[0], accuracy: 30, "shadow \(shadowed) lit \(lit)")
  }

  func testGrayscaleAndBlackWhiteMeetStructuralPixelContracts() throws {
    let source = try fixture(width: 96, height: 64)
    var request = validRequest(source: source)
    request["destinationPath"] = directory.appendingPathComponent("gray.jpg").path
    request["enhancement"] = ["filter": "grayscale", "brightness": 0.0,
      "contrast": 0.0, "sharpen": 0.0, "shadowRemoval": false]
    XCTAssertNotNil(try render(request)["result"])
    let gray = try pixels(at: URL(fileURLWithPath: request["destinationPath"] as! String))
    for pixel in gray.strideSample {
      XCTAssertLessThanOrEqual(abs(Int(pixel.r) - Int(pixel.g)), 3)
      XCTAssertLessThanOrEqual(abs(Int(pixel.g) - Int(pixel.b)), 3)
    }

    request["destinationPath"] = directory.appendingPathComponent("bw.jpg").path
    request["enhancement"] = ["filter": "blackAndWhite", "brightness": 0.0,
      "contrast": 0.0, "sharpen": 0.0, "shadowRemoval": false]
    XCTAssertNotNil(try render(request)["result"])
    let blackWhite = try pixels(at: URL(fileURLWithPath: request["destinationPath"] as! String))
    for pixel in blackWhite.strideSample {
      XCTAssertTrue(pixel.r <= 12 || pixel.r >= 243)
      XCTAssertLessThanOrEqual(abs(Int(pixel.r) - Int(pixel.g)), 3)
      XCTAssertLessThanOrEqual(abs(Int(pixel.g) - Int(pixel.b)), 3)
    }
  }

  func testContextRecreationAndSimulatedOversizeTiling() throws {
    let source = try fixture(width: 512, height: 384)
    let processor = DocScanlyImageProcessor(maximumTextureSize: 64)
    processor.invalidateContextForTesting()
    var request = validRequest(source: source)
    request["destinationPath"] = directory.appendingPathComponent("tiled.jpg").path

    let response = try render(request, processor: processor)
    let result = try XCTUnwrap(response["result"] as? [String: Any])
    XCTAssertEqual(result["outputWidth"] as? Int, 512)
    XCTAssertEqual(result["outputHeight"] as? Int, 384)
    XCTAssertTrue(try temporaryOutputs().isEmpty)
    let output = try pixels(at: URL(fileURLWithPath: result["destinationPath"] as! String))
    XCTAssertEqual(output.width, 512)
    XCTAssertEqual(output.height, 384)
  }

  func testCancellationAndCorruptInputPreservePublishedDestination() throws {
    let source = try fixture()
    let processor = DocScanlyImageProcessor()
    var request = validRequest(source: source)
    processor.cancel(request["requestId"] as! String)
    var response = try render(request, processor: processor)
    XCTAssertEqual(response["failureKind"] as? String, "cancelled")

    let corrupt = directory.appendingPathComponent("corrupt.jpg")
    try Data("not an image".utf8).write(to: corrupt)
    let destination = directory.appendingPathComponent("preserved.jpg")
    let original = Data("published".utf8)
    try original.write(to: destination)
    request = validRequest(source: corrupt)
    request["destinationPath"] = destination.path
    response = try render(request)
    XCTAssertEqual(response["failureKind"] as? String, "corrupt_input")
    XCTAssertEqual(try Data(contentsOf: destination), original)
    XCTAssertTrue(try temporaryOutputs().isEmpty)
  }

  func testRepeatedPreviewsReleaseTemporaryResources() throws {
    let source = try fixture(width: 64, height: 64)
    let processor = DocScanlyImageProcessor()
    for index in 0..<100 {
      var request = validRequest(source: source)
      request["requestId"] = "repeat-\(index)"
      request["destinationPath"] = directory.appendingPathComponent("repeat-\(index).jpg").path
      XCTAssertNotNil(try render(request, processor: processor)["result"])
    }
    processor.releaseResources()
    XCTAssertTrue(try temporaryOutputs().isEmpty)
  }

  private func validRequest(source: URL) -> [String: Any] {
    ["schemaVersion": 1, "colourPipelineVersion": 1,
     "requestId": UUID().uuidString, "sourcePath": source.path,
     "destinationPath": directory.appendingPathComponent("output.jpg").path,
     "scale": "full_resolution", "jpegQuality": 88,
     "enhancement": ["filter": "original", "brightness": 0.0,
       "contrast": 0.0, "sharpen": 0.0, "shadowRemoval": false]]
  }

  private func fixture(width: Int = 160, height: Int = 100) throws -> URL {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let renderer = UIGraphicsImageRenderer(
      size: CGSize(width: width, height: height),
      format: format
    )
    let image = renderer.image { context in
      UIColor.white.setFill(); context.cgContext.fill(CGRect(x: 0, y: 0, width: width, height: height))
      UIColor.black.setFill(); context.cgContext.fill(CGRect(x: width / 8, y: height / 3, width: width * 3 / 4, height: 5))
      UIColor.systemBlue.setFill(); context.cgContext.fill(CGRect(x: width / 3, y: height / 2, width: width / 3, height: height / 4))
    }
    let url = directory.appendingPathComponent("fixture-\(width)x\(height).jpg")
    try XCTUnwrap(image.jpegData(compressionQuality: 0.94)).write(to: url)
    return url
  }

  /// A camera-sized photo of paper with coloured print and a soft shadow across
  /// one corner — the case where the preview and the saved page diverged.
  private func shadowedPageFixture(width: Int = 3024, height: Int = 4032) throws -> URL {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
    let image = renderer.image { context in
      let cg = context.cgContext
      UIColor(white: 0.92, alpha: 1).setFill()
      cg.fill(CGRect(x: 0, y: 0, width: width, height: height))
      let inks: [UIColor] = [.black, UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1),
        UIColor(red: 0.1, green: 0.5, blue: 0.2, alpha: 1)]
      for line in 0..<36 {
        inks[line % inks.count].setFill()
        cg.fill(CGRect(x: Double(width) * 0.12, y: Double(height) * (0.12 + Double(line) * 0.02),
          width: Double(width) * 0.66, height: Double(height) * 0.006))
      }
      let shadow = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
        colors: [UIColor(white: 0, alpha: 0.4).cgColor, UIColor(white: 0, alpha: 0).cgColor] as CFArray,
        locations: [0, 1])!
      cg.drawLinearGradient(shadow, start: .zero,
        end: CGPoint(x: Double(width) * 0.6, y: Double(height) * 0.6), options: [])
    }
    let url = directory.appendingPathComponent("shadowed-\(width)x\(height).jpg")
    try XCTUnwrap(image.jpegData(compressionQuality: 0.92)).write(to: url)
    return url
  }

  private func renderEnhanced(_ source: URL, filter: String, preview: Bool) throws -> URL {
    var request = validRequest(source: source)
    let destination = directory.appendingPathComponent("\(filter)-\(preview ? "preview" : "full").jpg")
    request["destinationPath"] = destination.path
    if preview {
      request["scale"] = "preview"
      request["maximumPreviewDimension"] = 1080
    }
    request["enhancement"] = ["filter": filter, "brightness": 0.0,
      "contrast": 0.0, "sharpen": 0.0, "shadowRemoval": true]
    let response = try render(request, timeout: 60)
    XCTAssertNotNil(response["result"], "\(filter) failed: \(response)")
    return destination
  }

  private func meanColour(of url: URL) throws -> [Double] {
    try pixels(at: url).meanColour(in: CGRect(x: 0, y: 0, width: 1, height: 1))
  }

  private func render(
    _ request: [String: Any],
    processor: DocScanlyImageProcessor = DocScanlyImageProcessor(),
    timeout: TimeInterval = 10
  ) throws -> [String: Any] {
    let expectation = expectation(description: "native render")
    var response: [String: Any]?
    processor.render(request) { value in response = value; expectation.fulfill() }
    wait(for: [expectation], timeout: timeout)
    return try XCTUnwrap(response)
  }

  private func temporaryOutputs() throws -> [URL] {
    try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
      .filter { $0.lastPathComponent.contains(".native-") }
  }

  private func pixels(at url: URL) throws -> PixelBuffer {
    let image = try XCTUnwrap(UIImage(contentsOfFile: url.path)?.cgImage)
    var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
    let context = try XCTUnwrap(CGContext(
      data: &bytes, width: image.width, height: image.height,
      bitsPerComponent: 8, bytesPerRow: image.width * 4,
      space: CGColorSpace(name: CGColorSpace.sRGB)!,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ))
    context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    return PixelBuffer(width: image.width, height: image.height, bytes: bytes)
  }
}

private struct PixelBuffer {
  let width: Int
  let height: Int
  let bytes: [UInt8]

  var strideSample: [(r: UInt8, g: UInt8, b: UInt8)] {
    stride(from: 0, to: width * height, by: max(1, width * height / 128)).map {
      let offset = $0 * 4
      return (bytes[offset], bytes[offset + 1], bytes[offset + 2])
    }
  }

  /// Mean sRGB colour, 0–255, over [region] given as fractions of the image.
  func meanColour(in region: CGRect) -> [Double] {
    let left = Int(region.minX * Double(width)), right = max(left + 1, Int(region.maxX * Double(width)))
    let top = Int(region.minY * Double(height)), bottom = max(top + 1, Int(region.maxY * Double(height)))
    var sums = [0.0, 0.0, 0.0]
    var count = 0.0
    for y in stride(from: top, to: bottom, by: 4) {
      for x in stride(from: left, to: right, by: 4) {
        let offset = (y * width + x) * 4
        for channel in 0..<3 { sums[channel] += Double(bytes[offset + channel]) }
        count += 1
      }
    }
    return sums.map { $0 / max(count, 1) }
  }
}
