package com.bruxkey.docscanly

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.io.FileOutputStream
import java.util.UUID

@RunWith(AndroidJUnit4::class)
class ImageProcessingPluginTest {
    private lateinit var context: Context
    private lateinit var root: File
    private lateinit var source: File

    @Before fun setUp() {
        context = ApplicationProvider.getApplicationContext()
        root = File(context.cacheDir, "gpu-tests-${UUID.randomUUID()}").apply { mkdirs() }
        source = File(root, "source.jpg")
        val bitmap = Bitmap.createBitmap(96, 64, Bitmap.Config.ARGB_8888)
        bitmap.eraseColor(Color.WHITE)
        for (x in 12 until 84) for (y in 24 until 29) bitmap.setPixel(x, y, Color.BLACK)
        for (x in 32 until 64) for (y in 36 until 56) bitmap.setPixel(x, y, Color.BLUE)
        FileOutputStream(source).use { bitmap.compress(Bitmap.CompressFormat.JPEG, 94, it) }
        bitmap.recycle()
    }

    @After fun tearDown() { root.deleteRecursively() }

    @Test fun capabilityAndValidationAreVersionedAndContainerScoped() {
        val plugin = ImageProcessingPlugin(context)
        assertEquals(1, plugin.capability()["schemaVersion"])
        assertEquals("android_open_gl", plugin.capability()["backend"])
        expectFailure {
            AndroidRenderRequest.parse(request().toMutableMap().apply { this["schemaVersion"] = 2 }, context)
        }
        expectFailure {
            AndroidRenderRequest.parse(request().toMutableMap().apply { this["sourcePath"] = "/etc/passwd" }, context)
        }
        plugin.detach()
    }

    @Test fun everyFilterAndCombinedAdjustmentsRenderAtomically() {
        val plugin = ImageProcessingPlugin(context)
        for (filter in listOf("original", "autoEnhance", "magicColour", "blackAndWhite", "grayscale")) {
            val values = request(filter).toMutableMap()
            values["destinationPath"] = File(root, "$filter.jpg").path
            val response = plugin.render(AndroidRenderRequest.parse(values, context))
            val result = response["result"] as Map<*, *>
            assertEquals(80, result["outputWidth"])
            assertEquals(60, result["outputHeight"])
            assertTrue(File(result["destinationPath"] as String).isFile)
        }
        assertTrue(root.listFiles()!!.none { it.name.contains(".native-") })
        plugin.detach()
    }

    @Test fun cancellationAndCorruptInputNeverReplacePublishedOutput() {
        val plugin = ImageProcessingPlugin(context)
        val cancelled = AndroidRenderRequest.parse(request(), context)
        plugin.cancelForTest(cancelled.requestId)
        expectFailure { plugin.render(cancelled) }

        val destination = File(root, "output.jpg").apply { writeText("published") }
        val corrupt = File(root, "corrupt.jpg").apply { writeText("not jpeg") }
        val values = request().toMutableMap().apply {
            this["sourcePath"] = corrupt.path
            this["destinationPath"] = destination.path
        }
        expectFailure {
            plugin.render(AndroidRenderRequest.parse(values, context))
        }
        assertEquals("published", destination.readText())
        assertTrue(root.listFiles()!!.none { it.name.contains(".native-") })
        plugin.detach()
    }

    @Test fun oneHundredPreviewsRemainUsableAfterResourceRelease() {
        val plugin = ImageProcessingPlugin(context)
        repeat(100) { index ->
            val values = request().toMutableMap().apply {
                this["requestId"] = "preview-$index"
                this["destinationPath"] = File(root, "preview-$index.jpg").path
            }
            assertNotNull(plugin.render(AndroidRenderRequest.parse(values, context))["result"])
        }
        plugin.releaseResourcesForTest()
        val afterRelease = request().toMutableMap().apply {
            this["requestId"] = "after-release"
            this["destinationPath"] = File(root, "after-release.jpg").path
        }
        assertNotNull(plugin.render(AndroidRenderRequest.parse(afterRelease, context))["result"])
        plugin.detach()
        assertEquals(false, plugin.capability()["isSupported"])
    }

    @Test fun grayscaleBlackWhiteAndTextureLimitMeetStructuralContracts() {
        val plugin = ImageProcessingPlugin(context)
        val grayscale = renderStructural(plugin, "grayscale")
        sample(grayscale).forEach { pixel ->
            assertTrue(kotlin.math.abs(Color.red(pixel) - Color.green(pixel)) <= 4)
            assertTrue(kotlin.math.abs(Color.green(pixel) - Color.blue(pixel)) <= 4)
        }

        val blackWhite = renderStructural(plugin, "blackAndWhite")
        sample(blackWhite).forEach { pixel ->
            val red = Color.red(pixel)
            assertTrue(red <= 16 || red >= 239)
            assertTrue(kotlin.math.abs(red - Color.green(pixel)) <= 4)
            assertTrue(kotlin.math.abs(Color.green(pixel) - Color.blue(pixel)) <= 4)
        }
        grayscale.recycle()
        blackWhite.recycle()
        plugin.detach()

        val limited = ImageProcessingPlugin(context, maximumSurfaceSize = 64)
        assertEquals(64, limited.capability()["maximumTextureSize"])
        try {
            limited.render(AndroidRenderRequest.parse(request(), context))
            fail("an oversized surface must select fallback")
        } catch (failure: NativeFailure) {
            assertEquals("allocation", failure.kind)
        }
        assertTrue(root.listFiles()!!.none { it.name.contains(".native-") })
        limited.detach()
    }

    private fun request(filter: String = "original"): Map<String, Any> = mapOf(
        "schemaVersion" to 1, "colourPipelineVersion" to 1,
        "requestId" to UUID.randomUUID().toString(), "sourcePath" to source.path,
        "destinationPath" to File(root, "output.jpg").path, "scale" to "full_resolution",
        "jpegQuality" to 88, "outputWidth" to 80, "outputHeight" to 60,
        "transform" to mapOf("h00" to 1.2, "h01" to 0.0, "h02" to 0.0,
            "h10" to 0.0, "h11" to 1.066, "h12" to 0.0, "h20" to 0.0, "h21" to 0.0),
        "enhancement" to mapOf("filter" to filter, "brightness" to .1,
            "contrast" to .15, "sharpen" to .4, "shadowRemoval" to true),
    )

    private fun renderStructural(plugin: ImageProcessingPlugin, filter: String): Bitmap {
        val destination = File(root, "structural-$filter.jpg")
        val values = request(filter).toMutableMap().apply {
            this["destinationPath"] = destination.path
            this["outputWidth"] = 96
            this["outputHeight"] = 64
            this["transform"] = mapOf("h00" to 1.0, "h01" to 0.0, "h02" to 0.0,
                "h10" to 0.0, "h11" to 1.0, "h12" to 0.0, "h20" to 0.0, "h21" to 0.0)
            this["enhancement"] = mapOf("filter" to filter, "brightness" to 0.0,
                "contrast" to 0.0, "sharpen" to 0.0, "shadowRemoval" to false)
        }
        assertNotNull(plugin.render(AndroidRenderRequest.parse(values, context))["result"])
        return BitmapFactory.decodeFile(destination.path)
    }

    private fun sample(bitmap: Bitmap): List<Int> {
        val pixels = mutableListOf<Int>()
        val step = maxOf(1, bitmap.width * bitmap.height / 128)
        for (index in 0 until bitmap.width * bitmap.height step step) {
            pixels += bitmap.getPixel(index % bitmap.width, index / bitmap.width)
        }
        return pixels
    }

    private fun expectFailure(block: () -> Unit) {
        try {
            block()
            fail("expected native request to fail")
        } catch (_: Exception) {
            // Expected typed native rejection.
        }
    }
}
