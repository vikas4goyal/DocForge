package com.bruxkey.docscanly

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    private var mediaStore: MediaStorePlugin? = null
    private var imageProcessing: ImageProcessingPlugin? = null

    /**
     * Registers the MediaStore bridge alongside the generated plugins.
     *
     * Hosted here rather than published as a plugin package: it exists only to
     * reach `Documents/DocScanly`, and every candidate plugin either needs the
     * folder-picker prompt this application deliberately avoids or cannot
     * create and enumerate nested folders — see `design.md` D3.
     */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        mediaStore = MediaStorePlugin(applicationContext).also {
            it.attach(flutterEngine.dartExecutor.binaryMessenger)
        }
        imageProcessing = ImageProcessingPlugin(applicationContext).also {
            it.attach(flutterEngine.dartExecutor.binaryMessenger)
        }
    }

    override fun onDestroy() {
        mediaStore?.detach()
        mediaStore = null
        imageProcessing?.detach()
        imageProcessing = null
        super.onDestroy()
    }

    override fun onTrimMemory(level: Int) {
        imageProcessing?.releaseResources()
        super.onTrimMemory(level)
    }
}
