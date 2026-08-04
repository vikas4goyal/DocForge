package com.bruxkey.docscanly

import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import java.io.File
import java.io.IOException

/** Isolated compatibility edge for the retired Android public folder. */
class LegacyMediaStoreMigration(private val context: Context) {
    private val oldRoot = "Documents/DocForge/"
    private val newRoot = "Documents/DocScanly/"
    private val oldTrash = ".docforge-trash"
    private val newTrash = ".docscanly-trash"

    /** Moves legacy rows without overwriting independently-created payloads. */
    fun run() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            migrateLegacyFilesystem()
            return
        }
        val resolver = context.contentResolver
        val collection = MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val projection = arrayOf(
            MediaStore.MediaColumns._ID,
            MediaStore.MediaColumns.DISPLAY_NAME,
            MediaStore.MediaColumns.RELATIVE_PATH,
        )
        resolver.query(
            collection,
            projection,
            "${MediaStore.MediaColumns.RELATIVE_PATH} LIKE ?",
            arrayOf("$oldRoot%"),
            null,
        )?.use { cursor ->
            val idColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
            val nameColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME)
            val pathColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.RELATIVE_PATH)
            while (cursor.moveToNext()) {
                val id = cursor.getLong(idColumn)
                val name = cursor.getString(nameColumn)
                val oldPath = cursor.getString(pathColumn)
                val suffix = oldPath.removePrefix(oldRoot)
                    .replaceFirst(oldTrash, newTrash)
                val destinationPath = normalise(newRoot + suffix)
                val destinationName = availableName(collection, destinationPath, name)
                val values = ContentValues().apply {
                    put(MediaStore.MediaColumns.RELATIVE_PATH, destinationPath)
                    put(MediaStore.MediaColumns.DISPLAY_NAME, destinationName)
                }
                val updated = resolver.update(
                    ContentUris.withAppendedId(collection, id),
                    values,
                    null,
                    null,
                )
                if (updated != 1) throw IOException("legacy MediaStore move failed")
            }
        }
        File(sharedRoot(), oldRoot.trimEnd('/')).deleteRecursively()
    }

    private fun availableName(collection: android.net.Uri, path: String, requested: String): String {
        if (!exists(collection, path, requested)) return requested
        val dot = requested.lastIndexOf('.')
        val stem = if (dot > 0) requested.substring(0, dot) else requested
        val extension = if (dot > 0) requested.substring(dot) else ""
        var sequence = 1
        while (exists(collection, path, "$stem (legacy $sequence)$extension")) sequence++
        return "$stem (legacy $sequence)$extension"
    }

    private fun exists(collection: android.net.Uri, path: String, name: String): Boolean =
        context.contentResolver.query(
            collection,
            arrayOf(MediaStore.MediaColumns._ID),
            "${MediaStore.MediaColumns.RELATIVE_PATH} = ? AND " +
                "${MediaStore.MediaColumns.DISPLAY_NAME} = ?",
            arrayOf(path, name),
            null,
        )?.use { it.moveToFirst() } ?: false

    private fun migrateLegacyFilesystem() {
        val source = File(sharedRoot(), oldRoot.trimEnd('/'))
        if (!source.exists()) return
        val destination = File(sharedRoot(), newRoot.trimEnd('/'))
        source.walkTopDown().forEach { entity ->
            val raw = entity.relativeTo(source).path
            if (raw.isEmpty()) return@forEach
            val relative = raw.replaceFirst(oldTrash, newTrash)
            var target = File(destination, relative)
            if (entity.isDirectory) {
                target.mkdirs()
            } else {
                target.parentFile?.mkdirs()
                if (target.exists() && !sameBytes(entity, target)) {
                    target = collisionTarget(target)
                }
                if (!target.exists()) entity.copyTo(target)
                if (!sameBytes(entity, target)) throw IOException("legacy copy verification failed")
            }
        }
        source.deleteRecursively()
    }

    private fun collisionTarget(target: File): File {
        val stem = target.nameWithoutExtension
        val extension = target.extension.let { if (it.isEmpty()) "" else ".$it" }
        var sequence = 1
        while (true) {
            val candidate = File(target.parentFile, "$stem (legacy $sequence)$extension")
            if (!candidate.exists()) return candidate
            sequence++
        }
    }

    private fun sameBytes(first: File, second: File): Boolean =
        first.length() == second.length() &&
            first.inputStream().buffered().use { one ->
                second.inputStream().buffered().use { two ->
                    while (true) {
                        val a = one.read()
                        val b = two.read()
                        if (a != b) return false
                        if (a == -1) return true
                    }
                    @Suppress("UNREACHABLE_CODE")
                    false
                }
            }

    private fun sharedRoot(): File =
        Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS).parentFile
            ?: Environment.getExternalStorageDirectory()

    private fun normalise(path: String): String = path.trim('/') + "/"
}
