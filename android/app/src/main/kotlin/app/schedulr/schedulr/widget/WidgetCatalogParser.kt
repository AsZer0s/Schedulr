package app.schedulr.schedulr.widget

import org.json.JSONArray
import org.json.JSONObject

object WidgetCatalogParser {
    const val CATALOG_KEY = "schedulr.widget.snapshot.v2"

    data class Selection(
        val timetableId: String,
        val timetableName: String,
        val snapshot: WidgetSnapshot?,
    )

    fun select(raw: String?, timetableId: String?): Selection? {
        if (raw.isNullOrBlank()) return null
        return runCatching {
            selectMap(jsonObjectToMap(JSONObject(raw)), timetableId)
        }.getOrNull()
    }

    fun selectMap(root: Map<String, Any?>, timetableId: String?): Selection? {
        val requested = timetableId
            ?: (root["defaultTimetableId"] as? String)?.takeIf { it.isNotBlank() }
            ?: return null
        val entries = root["timetables"] as? List<*> ?: return null
        for (value in entries) {
            val entry = value as? Map<*, *> ?: continue
            val id = entry["timetableId"] as? String ?: continue
            if (id != requested) continue
            val snapshot = (entry["snapshot"] as? Map<*, *>)?.let { rawSnapshot ->
                WidgetSnapshotParser.parseMap(
                    rawSnapshot.entries
                        .filter { it.key is String }
                        .associate { it.key as String to it.value },
                )
            }
            return Selection(
                timetableId = id,
                timetableName = entry["timetableName"] as? String ?: "课表",
                snapshot = snapshot,
            )
        }
        return null
    }

    private fun jsonObjectToMap(value: JSONObject): Map<String, Any?> = buildMap {
        val keys = value.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            put(key, jsonValue(value.opt(key)))
        }
    }

    private fun jsonValue(value: Any?): Any? = when (value) {
        is JSONObject -> jsonObjectToMap(value)
        is JSONArray -> (0 until value.length()).map { jsonValue(value.opt(it)) }
        JSONObject.NULL -> null
        else -> value
    }
}
