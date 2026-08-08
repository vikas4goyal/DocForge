import Flutter
import Metal
import UIKit
import XCTest
@testable import Runner

final class RunnerTests: XCTestCase {
  private var directory: URL!

  override func setUpWithError() throws {
    directory = URL(fileURLWithPath: NSTemporaryDirectory())
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

  private func render(
    _ request: [String: Any],
    processor: DocScanlyImageProcessor = DocScanlyImageProcessor()
  ) throws -> [String: Any] {
    let expectation = expectation(description: "native render")
    var response: [String: Any]?
    processor.render(request) { value in response = value; expectation.fulfill() }
    wait(for: [expectation], timeout: 10)
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
}
