package com.bruxkey.doc_forge

import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileNotFoundException
import java.io.IOException

/**
 * Bridges the user-visible `Documents/DocForge` folder to Dart.
 *
 * Android 10 introduced scoped storage, which forbids writing arbitrary paths
 * into shared `Documents/`. MediaStore is the only route that reaches a folder
 * every file manager can see without a runtime permission or a folder picker,
 * and it is the reason this class exists rather than a `dart:io` path — see
 * `design.md` D3.
 *
 * Below API 29 the legacy direct-path branch is used, because MediaStore's
 * `RELATIVE_PATH` column does not exist there and the filesystem is reachable
 * with the legacy storage permission the manifest declares for those versions.
 *
 * Every method reports failures through the error codes `MediaStoreChannel`
 * on the Dart side knows how to interpret: `storage_full`, `not_found` and
 * `nested_unsupported`.
 */
class MediaStorePlugin(private val context: Context) : MethodChannel.MethodCallHandler {

    private var channel: MethodChannel? = null

    fun attach(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, CHANNEL_NAME).also { it.setMethodCallHandler(this) }
    }

    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "createFolder" -> {
                    createFolder(call.argument<String>("relativePath")!!)
                    result.success(null)
                }
                "deleteFolder" -> {
                    deleteFolder(call.argument<String>("relativePath")!!)
                    result.success(null)
                }
                "renameFolder" -> {
                    renameFolder(
                        call.argument<String>("relativePath")!!,
                        call.argument<String>("newName")!!,
                    )
                    result.success(null)
                }
                "list" -> result.success(
                    list(
                        call.argument<String>("relativePath")!!,
                        call.argument<Boolean>("recursive") ?: false,
                    )
                )
                "listFolders" -> result.success(
                    listFolders(call.argument<String>("relativePath")!!)
                )
                "writeFile" -> {
                    writeFile(
                        call.argument<String>("relativePath")!!,
                        call.argument<String>("displayName")!!,
                        call.argument<String>("sourcePath")!!,
                    )
                    result.success(null)
                }
                "copyToCache" -> {
                    copyToCache(
                        call.argument<String>("relativePath")!!,
                        call.argument<String>("displayName")!!,
                        call.argument<String>("destinationPath")!!,
                    )
                    result.success(null)
                }
                "moveFile" -> {
                    moveFile(
                        call.argument<String>("fromRelativePath")!!,
                        call.argument<String>("fromDisplayName")!!,
                        call.argument<String>("toRelativePath")!!,
                        call.argument<String>("toDisplayName")!!,
                    )
                    result.success(null)
                }
                "deleteFile" -> {
                    deleteFile(
                        call.argument<String>("relativePath")!!,
                        call.argument<String>("displayName")!!,
                    )
                    result.success(null)
                }
                "exists" -> result.success(
                    findId(
                        call.argument<String>("relativePath")!!,
                        call.argument<String>("displayName")!!,
                    ) != null || legacyFile(
                        call.argument<String>("relativePath")!!,
                        call.argument<String>("displayName")!!,
                    ).exists()
                )
                else -> result.notImplemented()
            }
        } catch (error: FileNotFoundException) {
            result.error(ERROR_NOT_FOUND, error.message, null)
        } catch (error: IOException) {
            // ENOSPC surfaces as an IOException whose message names the
            // condition; there is no typed exception for a full volume.
            if (error.message?.contains("space", ignoreCase = true) == true ||
                error.message?.contains("ENOSPC") == true
            ) {
                result.error(ERROR_STORAGE_FULL, error.message, null)
            } else {
                result.error(ERROR_IO, error.message, null)
            }
        } catch (error: UnsupportedOperationException) {
            // Thrown below when an OEM build refuses a nested RELATIVE_PATH.
            result.error(ERROR_NESTED_UNSUPPORTED, error.message, null)
        } catch (error: IllegalArgumentException) {
            result.error(ERROR_NESTED_UNSUPPORTED, error.message, null)
        } catch (error: Exception) {
            result.error(ERROR_IO, error.message, null)
        }
    }

    // ── Folders ──────────────────────────────────────────────────────

    /**
     * Creates a folder by creating the directory on disk.
     *
     * MediaStore has no folder rows: a folder exists exactly when something
     * inside it does, or when the directory itself is present. Creating the
     * directory is what makes an *empty* folder visible in a file manager,
     * which a user who has just tapped "New folder" expects to see.
     */
    private fun createFolder(relativePath: String) {
        val directory = directoryFor(relativePath)
        if (!directory.exists() && !directory.mkdirs()) {
            throw UnsupportedOperationException("cannot create $relativePath")
        }
    }

    private fun deleteFolder(relativePath: String) {
        // Remove the MediaStore rows first so nothing is left indexed pointing
        // at files that are about to disappear.
        for (item in queryItems(relativePath, recursive = true)) {
            val id = item["id"] as Long
            context.contentResolver.delete(itemUri(id), null, null)
        }
        directoryFor(relativePath).deleteRecursively()
    }

    private fun renameFolder(relativePath: String, newName: String) {
        val source = directoryFor(relativePath)
        if (!source.exists()) throw FileNotFoundException(relativePath)

        val destination = File(source.parentFile, newName)
        if (!source.renameTo(destination)) {
            throw IOException("cannot rename $relativePath to $newName")
        }
        // The rows still name the old path; re-point each one so a later query
        // finds the files where they now are.
        val oldPrefix = normalise(relativePath)
        val newPrefix = normalise(
            oldPrefix.trimEnd('/').substringBeforeLast('/') + "/" + newName
        )
        for (item in queryItems(oldPrefix, recursive = true)) {
            val id = item["id"] as Long
            val itemPath = item["relativePath"] as String
            val values = ContentValues().apply {
                put(
                    MediaStore.MediaColumns.RELATIVE_PATH,
                    newPrefix + itemPath.removePrefix(oldPrefix),
                )
            }
            context.contentResolver.update(itemUri(id), values, null, null)
        }
    }

    private fun listFolders(relativePath: String): List<String> {
        val directory = directoryFor(relativePath)
        val onDisk = directory.listFiles()
            ?.filter { it.isDirectory && !it.name.startsWith(".") }
            ?.map { it.name }
            .orEmpty()

        // A folder can also be implied by an indexed file inside it, which is
        // what happens when another application writes into our tree.
        val prefix = normalise(relativePath)
        val implied = queryItems(prefix, recursive = true).mapNotNull { item ->
            val itemPath = item["relativePath"] as String
            itemPath.removePrefix(prefix).trim('/').split('/').firstOrNull()
        }.filter { it.isNotEmpty() }

        return (onDisk + implied).distinct()
    }

    // ── Files ────────────────────────────────────────────────────────

    private fun list(relativePath: String, recursive: Boolean): List<Map<String, Any?>> =
        queryItems(normalise(relativePath), recursive).map { item ->
            mapOf(
                "relativePath" to item["relativePath"],
                "displayName" to item["displayName"],
                "size" to item["size"],
                "modified" to item["modified"],
            )
        }

    private fun writeFile(relativePath: String, displayName: String, sourcePath: String) {
        val source = File(sourcePath)
        if (!source.exists()) throw FileNotFoundException(sourcePath)

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            val destination = legacyFile(relativePath, displayName)
            destination.parentFile?.mkdirs()
            source.copyTo(destination, overwrite = true)
            return
        }

        // Replace rather than accumulate: MediaStore will happily create a
        // second row with the same display name, which would show the user two
        // identical files where they asked for one.
        findId(relativePath, displayName)?.let {
            context.contentResolver.delete(itemUri(it), null, null)
        }

        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
            put(MediaStore.MediaColumns.MIME_TYPE, PDF_MIME_TYPE)
            put(MediaStore.MediaColumns.RELATIVE_PATH, normalise(relativePath))
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }

        val uri = context.contentResolver.insert(collection(), values)
            ?: throw UnsupportedOperationException("insert refused for $relativePath")

        context.contentResolver.openOutputStream(uri)?.use { output ->
            source.inputStream().use { it.copyTo(output) }
        } ?: throw IOException("cannot open $uri for writing")

        // Clearing IS_PENDING is what publishes the row; until then no other
        // application can see the file, so a failed write leaves nothing
        // half-visible in the user's folder.
        context.contentResolver.update(
            uri,
            ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) },
            null,
            null,
        )
    }

    private fun copyToCache(
        relativePath: String,
        displayName: String,
        destinationPath: String,
    ) {
        val destination = File(destinationPath)
        destination.parentFile?.mkdirs()

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            val source = legacyFile(relativePath, displayName)
            if (!source.exists()) throw FileNotFoundException(relativePath + displayName)
            source.copyTo(destination, overwrite = true)
            return
        }

        val id = findId(relativePath, displayName)
            ?: throw FileNotFoundException(relativePath + displayName)

        context.contentResolver.openInputStream(itemUri(id))?.use { input ->
            destination.outputStream().use { input.copyTo(it) }
        } ?: throw FileNotFoundException(relativePath + displayName)
    }

    private fun moveFile(
        fromRelativePath: String,
        fromDisplayName: String,
        toRelativePath: String,
        toDisplayName: String,
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            val source = legacyFile(fromRelativePath, fromDisplayName)
            if (!source.exists()) throw FileNotFoundException(fromDisplayName)
            val destination = legacyFile(toRelativePath, toDisplayName)
            destination.parentFile?.mkdirs()
            if (!source.renameTo(destination)) throw IOException("cannot move")
            return
        }

        val id = findId(fromRelativePath, fromDisplayName)
            ?: throw FileNotFoundException(fromRelativePath + fromDisplayName)

        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, toDisplayName)
            put(MediaStore.MediaColumns.RELATIVE_PATH, normalise(toRelativePath))
        }
        val updated = context.contentResolver.update(itemUri(id), values, null, null)
        if (updated == 0) throw IOException("cannot move $fromDisplayName")
    }

    private fun deleteFile(relativePath: String, displayName: String) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            legacyFile(relativePath, displayName).delete()
            return
        }
        // Already-absent is success: deletion has to be idempotent so a retry
        // after a partial failure can complete.
        findId(relativePath, displayName)?.let {
            context.contentResolver.delete(itemUri(it), null, null)
        }
    }

    // ── Querying ─────────────────────────────────────────────────────

    private fun queryItems(relativePath: String, recursive: Boolean): List<Map<String, Any?>> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return legacyQuery(relativePath, recursive)
        }

        val prefix = normalise(relativePath)
        val selection = if (recursive) {
            "${MediaStore.MediaColumns.RELATIVE_PATH} LIKE ?"
        } else {
            "${MediaStore.MediaColumns.RELATIVE_PATH} = ?"
        }
        val argument = if (recursive) "$prefix%" else prefix

        val projection = arrayOf(
            MediaStore.MediaColumns._ID,
            MediaStore.MediaColumns.DISPLAY_NAME,
            MediaStore.MediaColumns.RELATIVE_PATH,
            MediaStore.MediaColumns.SIZE,
            MediaStore.MediaColumns.DATE_MODIFIED,
        )

        val items = mutableListOf<Map<String, Any?>>()
        context.contentResolver.query(
            collection(),
            projection,
            selection,
            arrayOf(argument),
            null,
        )?.use { cursor ->
            val idColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
            val nameColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME)
            val pathColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.RELATIVE_PATH)
            val sizeColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.SIZE)
            val modifiedColumn =
                cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATE_MODIFIED)

            while (cursor.moveToNext()) {
                items += mapOf(
                    "id" to cursor.getLong(idColumn),
                    "displayName" to cursor.getString(nameColumn),
                    "relativePath" to (cursor.getString(pathColumn) ?: ""),
                    "size" to cursor.getLong(sizeColumn),
                    "modified" to cursor.getLong(modifiedColumn),
                )
            }
        }
        return items
    }

    private fun findId(relativePath: String, displayName: String): Long? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return null

        context.contentResolver.query(
            collection(),
            arrayOf(MediaStore.MediaColumns._ID),
            "${MediaStore.MediaColumns.RELATIVE_PATH} = ? AND " +
                "${MediaStore.MediaColumns.DISPLAY_NAME} = ?",
            arrayOf(normalise(relativePath), displayName),
            null,
        )?.use { cursor ->
            if (cursor.moveToFirst()) return cursor.getLong(0)
        }
        return null
    }

    /**
     * Walks the filesystem directly, for API levels before scoped storage.
     */
    private fun legacyQuery(relativePath: String, recursive: Boolean): List<Map<String, Any?>> {
        val directory = directoryFor(relativePath)
        if (!directory.exists()) return emptyList()

        val files = if (recursive) directory.walkTopDown() else directory.listFiles()?.asSequence()
            ?: emptySequence()

        return files.filter { it.isFile && !it.name.startsWith(".") }.map { file ->
            val parent = file.parentFile?.absolutePath.orEmpty()
            val root = sharedRoot().absolutePath
            mapOf(
                "id" to 0L,
                "displayName" to file.name,
                "relativePath" to (parent.removePrefix(root).trim('/') + "/"),
                "size" to file.length(),
                "modified" to (file.lastModified() / 1000),
            )
        }.toList()
    }

    // ── Paths ────────────────────────────────────────────────────────

    private fun collection(): Uri =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        } else {
            MediaStore.Files.getContentUri("external")
        }

    private fun itemUri(id: Long): Uri = ContentUris.withAppendedId(collection(), id)

    private fun sharedRoot(): File =
        Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS).parentFile
            ?: Environment.getExternalStorageDirectory()

    private fun directoryFor(relativePath: String): File =
        File(sharedRoot(), normalise(relativePath).trimEnd('/'))

    private fun legacyFile(relativePath: String, displayName: String): File =
        File(directoryFor(relativePath), displayName)

    /**
     * Normalises a relative path to MediaStore's expected form.
     *
     * `RELATIVE_PATH` must name the containing folder and must end with a
     * separator; a value that does not is rejected on some builds and silently
     * accepted on others, which would make the same write land in two places.
     */
    private fun normalise(relativePath: String): String {
        val trimmed = relativePath.trim('/')
        return if (trimmed.isEmpty()) "" else "$trimmed/"
    }

    private companion object {
        const val CHANNEL_NAME = "com.bruxkey.doc_forge/media_store"
        const val PDF_MIME_TYPE = "application/pdf"
        const val ERROR_NOT_FOUND = "not_found"
        const val ERROR_STORAGE_FULL = "storage_full"
        const val ERROR_NESTED_UNSUPPORTED = "nested_unsupported"
        const val ERROR_IO = "io_error"
    }
}
