package com.bruxkey.doc_forge

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    private var mediaStore: MediaStorePlugin? = null

    /**
     * Registers the MediaStore bridge alongside the generated plugins.
     *
     * Hosted here rather than published as a plugin package: it exists only to
     * reach `Documents/DocForge`, and every candidate plugin either needs the
     * folder-picker prompt this application deliberately avoids or cannot
     * create and enumerate nested folders — see `design.md` D3.
     */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        mediaStore = MediaStorePlugin(applicationContext).also {
            it.attach(flutterEngine.dartExecutor.binaryMessenger)
        }
    }

    override fun onDestroy() {
        mediaStore?.detach()
        mediaStore = null
        super.onDestroy()
    }
}
