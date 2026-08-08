package com.bruxkey.docscanly

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.ColorSpace
import android.graphics.HardwareRenderer
import android.graphics.ImageFormat
import android.graphics.Matrix
import android.graphics.PixelFormat
import android.graphics.RenderEffect
import android.graphics.RenderNode
import android.graphics.RuntimeShader
import android.hardware.HardwareBuffer
import android.media.ExifInterface
import android.media.ImageReader
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteOrder
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

private const val SCHEMA_VERSION = 1
private const val COLOUR_PIPELINE_VERSION = 1

internal data class AndroidEnhancement(
    val filter: String,
    val brightness: Float,
    val contrast: Float,
    val sharpen: Float,
    val shadowRemoval: Boolean,
)

internal data class AndroidRenderRequest(
    val requestId: String,
    val source: File,
    val destination: File,
    val preview: Boolean,
    val previewMaximum: Int?,
    val outputWidth: Int?,
    val outputHeight: Int?,
    val homography: FloatArray?,
    val quality: Int,
    val enhancement: AndroidEnhancement,
) {
    companion object {
        fun parse(arguments: Any?, context: Context): AndroidRenderRequest {
            val map = arguments as? Map<*, *> ?: invalid("request is not a map")
            if (map["schemaVersion"] != SCHEMA_VERSION || map["colourPipelineVersion"] != COLOUR_PIPELINE_VERSION) invalid("unsupported schema")
            val requestId = map.string("requestId").also { if (it.isBlank()) invalid("empty request id") }
            val source = ownedFile(map.string("sourcePath"), context)
            val destination = ownedFile(map.string("destinationPath"), context)
            if (!source.isFile || source.canonicalFile == destination.canonicalFile) invalidPath()
            val scale = map.string("scale").also { if (it !in setOf("preview", "full_resolution")) invalid("invalid scale") }
            val quality = map.int("jpegQuality").also { if (it !in 1..100) invalid("invalid quality") }
            val settings = map["enhancement"] as? Map<*, *> ?: invalid("missing enhancement")
            val filter = settings.string("filter").also {
                if (it !in setOf("original", "autoEnhance", "magicColour", "blackAndWhite", "grayscale")) invalid("invalid filter")
            }
            val brightness = settings.float("brightness")
            val contrast = settings.float("contrast")
            val sharpen = settings.float("sharpen")
            if (
                !brightness.isFinite() || brightness !in -0.35f..0.35f ||
                !contrast.isFinite() || contrast !in -0.5f..0.5f ||
                !sharpen.isFinite() || sharpen !in 0f..0.6f
            ) invalid("invalid adjustment")
            val shadow = settings["shadowRemoval"] as? Boolean ?: invalid("missing shadow removal")
            val width = (map["outputWidth"] as? Number)?.toInt()
            val height = (map["outputHeight"] as? Number)?.toInt()
            if ((width == null) != (height == null) || width?.let { it <= 0 } == true || height?.let { it <= 0 } == true) invalid("invalid output dimensions")
            val previewMaximum = (map["maximumPreviewDimension"] as? Number)?.toInt()
            if (previewMaximum?.let { it <= 0 } == true) invalid("invalid preview maximum")
            val transform = (map["transform"] as? Map<*, *>)?.let { values ->
                val keys = listOf("h00", "h01", "h02", "h10", "h11", "h12", "h20", "h21")
                FloatArray(9).also { matrix ->
                    keys.forEachIndexed { index, key -> matrix[index] = values.float(key) }
                    matrix[8] = 1f
                    if (matrix.any { !it.isFinite() } || width == null) invalid("invalid homography")
                }
            }
            return AndroidRenderRequest(requestId, source, destination, scale == "preview", previewMaximum,
                width, height, transform, quality, AndroidEnhancement(filter, brightness, contrast, sharpen, shadow))
        }

        private fun ownedFile(path: String, context: Context): File {
            val file = File(path).canonicalFile
            val roots = listOfNotNull(context.filesDir, context.cacheDir, context.noBackupFilesDir,
                context.externalCacheDir, File(context.applicationInfo.dataDir)).map { it.canonicalFile.path + File.separator }
            if (roots.none { file.path.startsWith(it) }) invalidPath()
            return file
        }
    }
}

internal class NativeFailure(val kind: String, message: String) : Exception(message)
private fun invalid(detail: String): Nothing = throw NativeFailure("invalid_request", detail)
private fun invalidPath(): Nothing = throw NativeFailure("invalid_path", "path rejected")
private fun Map<*, *>.string(key: String) = this[key] as? String ?: invalid("missing $key")
private fun Map<*, *>.int(key: String) = (this[key] as? Number)?.toInt() ?: invalid("missing $key")
private fun Map<*, *>.float(key: String) = (this[key] as? Number)?.toFloat() ?: invalid("missing $key")

/** Versioned native file-to-file image channel backed by Android's GPU renderer. */
class ImageProcessingPlugin(
    private val context: Context,
    private val maximumSurfaceSize: Int = 16384,
) : MethodChannel.MethodCallHandler {
    private val worker = HandlerThread("docscanly-image-gpu").apply { start() }
    private val handler = Handler(worker.looper)
    private val main = Handler(Looper.getMainLooper())
    private val cancelled = ConcurrentHashMap.newKeySet<String>()
    private var channel: MethodChannel? = null
    private var cachedSource: Triple<String, Long, Bitmap>? = null
    @Volatile private var disposed = false

    fun attach(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, "com.bruxkey.docscanly/image_processing_v1").also { it.setMethodCallHandler(this) }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "capability" -> result.success(capability())
            "cancel" -> { (call.arguments as? Map<*, *>)?.get("requestId")?.toString()?.let(cancelled::add); result.success(null) }
            "dispose" -> { detach(); result.success(null) }
            "render" -> handler.post {
                val response = try { render(AndroidRenderRequest.parse(call.arguments, context)) }
                catch (failure: NativeFailure) { failure(failure.kind, failure.message ?: "native failure") }
                catch (_: OutOfMemoryError) { failure("allocation", "native allocation failed") }
                catch (error: Throwable) {
                    val reason = error.message?.replace(Regex("/[^ ]+"), "<path>")?.take(240).orEmpty()
                    failure("unexpected", "native render failed: ${error.javaClass.simpleName} $reason")
                }
                main.post { result.success(response) }
            }
            else -> result.notImplemented()
        }
    }

    internal fun capability(): Map<String, Any> {
        val supported = Build.VERSION.SDK_INT >= 33 && !disposed
        return mapOf("schemaVersion" to SCHEMA_VERSION, "backend" to "android_open_gl",
            "isSupported" to supported, "maximumTextureSize" to if (supported) maximumSurfaceSize else 0,
            "supportsTiling" to false)
    }

    internal fun render(request: AndroidRenderRequest): Map<String, Any> {
        checkCancelled(request.requestId)
        if (Build.VERSION.SDK_INT < 33 || disposed) throw NativeFailure("unsupported", "GPU renderer unavailable")
        val totalStart = System.nanoTime()
        val decodeStart = System.nanoTime()
        val modified = request.source.lastModified()
        val cached = cachedSource
        val bitmap = if (cached != null && cached.first == request.source.path && cached.second == modified && !cached.third.isRecycled) {
            cached.third
        } else {
            val decoded = BitmapFactory.decodeFile(request.source.path) ?: throw NativeFailure("corrupt_input", "decode failed")
            val oriented = orient(decoded, request.source)
            cachedSource?.third?.takeUnless { it.isRecycled }?.recycle()
            cachedSource = Triple(request.source.path, modified, oriented)
            oriented
        }
        val sourceWidth = bitmap.width
        val sourceHeight = bitmap.height
        val decodeEnd = System.nanoTime()
        var width = request.outputWidth ?: sourceWidth
        var height = request.outputHeight ?: sourceHeight
        if (request.preview && request.previewMaximum != null && max(width, height) > request.previewMaximum) {
            val scale = request.previewMaximum.toFloat() / max(width, height)
            width = max(1, (width * scale).roundToInt()); height = max(1, (height * scale).roundToInt())
        }
        if (width > maximumSurfaceSize || height > maximumSurfaceSize) throw NativeFailure("allocation", "texture limit exceeded")
        checkCancelled(request.requestId)
        val output = gpuRender(bitmap, width, height, request)
        val transformEnd = System.nanoTime()
        checkCancelled(request.requestId)
        request.destination.parentFile?.mkdirs()
        val temporary = File(request.destination.parentFile, ".${request.destination.name}.native-${UUID.randomUUID()}.tmp")
        try {
            FileOutputStream(temporary).use { stream ->
                if (!output.compress(Bitmap.CompressFormat.JPEG, request.quality, stream)) throw NativeFailure("codec", "JPEG encode failed")
                stream.fd.sync()
            }
            checkCancelled(request.requestId)
            if (!temporary.renameTo(request.destination)) {
                temporary.copyTo(request.destination, overwrite = true); temporary.delete()
            }
        } catch (failure: NativeFailure) { throw failure }
        catch (_: Throwable) { throw NativeFailure("storage", "output write failed") }
        finally { output.recycle(); temporary.delete(); cancelled.remove(request.requestId) }
        val encodeEnd = System.nanoTime()
        fun micros(start: Long, end: Long) = ((end - start) / 1000).toInt()
        return mapOf("schemaVersion" to SCHEMA_VERSION, "result" to mapOf(
            "destinationPath" to request.destination.path, "sourceWidth" to sourceWidth, "sourceHeight" to sourceHeight,
            "outputWidth" to width, "outputHeight" to height, "backend" to "android_open_gl",
            "timings" to mapOf("decodeMicroseconds" to micros(decodeStart, decodeEnd),
                "transformMicroseconds" to micros(decodeEnd, transformEnd), "encodeMicroseconds" to micros(transformEnd, encodeEnd),
                "totalMicroseconds" to micros(totalStart, encodeEnd))))
    }

    private fun gpuRender(source: Bitmap, width: Int, height: Int, request: AndroidRenderRequest): Bitmap {
        val reader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2,
            HardwareBuffer.USAGE_GPU_COLOR_OUTPUT or HardwareBuffer.USAGE_CPU_READ_RARELY)
        val renderer = HardwareRenderer()
        val node = RenderNode("docscanly-image").apply { setPosition(0, 0, width, height) }
        val canvas = node.beginRecording(width, height)
        canvas.drawColor(android.graphics.Color.WHITE)
        val matrix = geometryMatrix(source.width, source.height, width, height, request)
        canvas.drawBitmap(source, matrix, null)
        node.endRecording()
        val shader = RuntimeShader(ENHANCEMENT_SHADER)
        shader.setFloatUniform("size", width.toFloat(), height.toFloat())
        shader.setFloatUniform("brightness", request.enhancement.brightness)
        shader.setFloatUniform("contrast", if (request.enhancement.contrast >= 0) 1 + request.enhancement.contrast * 3 else 1 + request.enhancement.contrast)
        shader.setFloatUniform("sharpen", request.enhancement.sharpen)
        shader.setFloatUniform("shadow", if (request.enhancement.shadowRemoval) 1f else 0f)
        shader.setFloatUniform("filter", when (request.enhancement.filter) { "grayscale" -> 1f; "autoEnhance" -> 2f; "magicColour" -> 3f; "blackAndWhite" -> 4f; else -> 0f })
        shader.setFloatUniform("radius", min(16f, max(1f, min(width, height) * .05f)))
        node.setRenderEffect(RenderEffect.createRuntimeShaderEffect(shader, "content"))
        renderer.setSurface(reader.surface); renderer.setContentRoot(node)
        val status = renderer.createRenderRequest().setWaitForPresent(true).syncAndDraw()
        if (status != HardwareRenderer.SYNC_OK) { renderer.destroy(); reader.close(); throw NativeFailure("context_lost", "GPU draw failed") }
        val image = reader.acquireLatestImage() ?: run { renderer.destroy(); reader.close(); throw NativeFailure("context_lost", "GPU output missing") }
        val plane = image.planes[0]
        val buffer = plane.buffer.order(ByteOrder.nativeOrder())
        val rowPixels = plane.rowStride / plane.pixelStride
        val padded = Bitmap.createBitmap(rowPixels, height, Bitmap.Config.ARGB_8888)
        padded.copyPixelsFromBuffer(buffer)
        val cropped = Bitmap.createBitmap(padded, 0, 0, width, height)
        val flipped = Bitmap.createBitmap(cropped, 0, 0, width, height, Matrix().apply { postScale(1f, -1f, width / 2f, height / 2f) }, true)
        if (cropped !== padded) cropped.recycle(); padded.recycle(); image.close(); renderer.destroy(); reader.close()
        return flipped
    }

    private fun geometryMatrix(sourceWidth: Int, sourceHeight: Int, width: Int, height: Int, request: AndroidRenderRequest): Matrix {
        val homography = request.homography
        if (homography == null) return Matrix().apply { setScale(width.toFloat() / sourceWidth, height.toFloat() / sourceHeight) }
        val outputToSource = Matrix().apply { setValues(homography) }
        val sourceToFullOutput = Matrix().also { if (!outputToSource.invert(it)) invalid("singular homography") }
        val previewScale = Matrix().apply {
            setScale(width.toFloat() / request.outputWidth!!, height.toFloat() / request.outputHeight!!)
        }
        return Matrix().apply { setConcat(previewScale, sourceToFullOutput) }
    }

    private fun orient(bitmap: Bitmap, file: File): Bitmap {
        if (Build.VERSION.SDK_INT < 24) return bitmap
        val orientation = try { ExifInterface(file.path).getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL) } catch (_: Throwable) { return bitmap }
        val degrees = when (orientation) { ExifInterface.ORIENTATION_ROTATE_90 -> 90f; ExifInterface.ORIENTATION_ROTATE_180 -> 180f; ExifInterface.ORIENTATION_ROTATE_270 -> 270f; else -> 0f }
        if (degrees == 0f) return bitmap
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, Matrix().apply { postRotate(degrees) }, true).also { bitmap.recycle() }
    }

    private fun checkCancelled(id: String) { if (disposed || cancelled.contains(id)) throw NativeFailure("cancelled", "request cancelled") }
    internal fun cancelForTest(id: String) { cancelled.add(id) }
    fun releaseResources() = handler.post {
        releaseCachedSource()
    }
    internal fun releaseResourcesForTest() {
        releaseCachedSource()
    }
    private fun releaseCachedSource() {
        cachedSource?.third?.takeUnless { it.isRecycled }?.recycle()
        cachedSource = null
    }
    fun detach() {
        disposed = true
        channel?.setMethodCallHandler(null)
        channel = null
        cancelled.clear()
        releaseResources()
        worker.quitSafely()
    }
    private fun failure(kind: String, detail: String) = mapOf("schemaVersion" to SCHEMA_VERSION, "failureKind" to kind, "debugDetail" to detail)

    companion object {
        private const val ENHANCEMENT_SHADER = """
            uniform shader content; uniform float2 size; uniform float brightness; uniform float contrast;
            uniform float sharpen; uniform float shadow; uniform float filter; uniform float radius;
            half4 main(float2 p) {
              half4 s=content.eval(p); half3 weights=half3(.299,.587,.114);
              half mean=dot(s.rgb,weights);
              mean+=dot(content.eval(clamp(p+float2(radius,0),float2(0),size-1)).rgb,weights);
              mean+=dot(content.eval(clamp(p+float2(-radius,0),float2(0),size-1)).rgb,weights);
              mean+=dot(content.eval(clamp(p+float2(0,radius),float2(0),size-1)).rgb,weights);
              mean+=dot(content.eval(clamp(p+float2(0,-radius),float2(0),size-1)).rgb,weights);
              mean+=dot(content.eval(clamp(p+float2(radius,radius),float2(0),size-1)).rgb,weights);
              mean+=dot(content.eval(clamp(p+float2(-radius,radius),float2(0),size-1)).rgb,weights);
              mean+=dot(content.eval(clamp(p+float2(radius,-radius),float2(0),size-1)).rgb,weights);
              mean+=dot(content.eval(clamp(p+float2(-radius,-radius),float2(0),size-1)).rgb,weights);
              mean/=9.0; half lum=dot(s.rgb,weights); half3 c=s.rgb;
              if(shadow>.5) c=clamp(c*min(1.0/max(float(mean),1.0/255.0),3.0),0.0,1.0);
              if(filter>.5 && filter<1.5) c=half3(lum); else if(filter>1.5&&filter<2.5) c=clamp((c-.03)*1.08,0.0,1.0);
              else if(filter>2.5&&filter<3.5) { c=clamp(lum+(c-lum)*1.45,0.0,1.0); c=clamp(.5+(c-.5)*1.45,0.0,1.0); }
              else if(filter>3.5) { half v=lum<mean-(8.0/255.0)?0.0:1.0; c=half3(v); }
              c=clamp(.5+(c+half(brightness)-.5)*half(contrast),0.0,1.0);
              c=clamp(c+(lum-mean)*half(sharpen*3.0),0.0,1.0); return half4(c,s.a);
            }
        """
    }
}
