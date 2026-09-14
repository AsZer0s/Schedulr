package app.schedulr.schedulr.widget

import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/** A deliberately tolerant, display-only model for the Flutter widget snapshot. */
data class WidgetCourse(
    val name: String,
    val time: String = "",
    val location: String = "",
    val teacher: String = "",
    val startPeriod: Int? = null,
    val endPeriod: Int? = null,
    val color: Int? = null,
    val ongoing: Boolean = false,
)

data class WidgetSnapshot(
    val schemaVersion: Int? = null,
    val state: String = STATE_EMPTY,
    val generatedAt: Long? = null,
    val expiresAt: Long? = null,
    val timetableName: String = "",
    val semesterName: String = "",
    val dateLabel: String = "",
    val weekLabel: String = "",
    val next: WidgetCourse? = null,
    val today: List<WidgetCourse> = emptyList(),
) {
    val isCorrupt: Boolean get() = state == STATE_CORRUPT
    val isStale: Boolean get() = state == STATE_STALE

    companion object {
        const val STATE_READY = "ready"
        const val STATE_EMPTY = "empty"
        const val STATE_OUTSIDE = "outsideSemester"
        const val STATE_STALE = "stale"
        const val STATE_CORRUPT = "corrupt"
    }
}

object WidgetSnapshotParser {
    fun parse(
        raw: String?,
        nowMillis: Long = System.currentTimeMillis(),
        timeZone: TimeZone = TimeZone.getDefault(),
    ): WidgetSnapshot {
        if (raw.isNullOrBlank()) return WidgetSnapshot()
        return try {
            parseMap(jsonObjectToMap(JSONObject(raw)), nowMillis, timeZone)
        } catch (_: Exception) {
            WidgetSnapshot(state = WidgetSnapshot.STATE_CORRUPT)
        }
    }

    fun parse(
        root: JSONObject,
        nowMillis: Long = System.currentTimeMillis(),
        timeZone: TimeZone = TimeZone.getDefault(),
    ): WidgetSnapshot = parseMap(jsonObjectToMap(root), nowMillis, timeZone)

    /** Pure map entry point keeps the display parser unit-testable without Android/Robolectric. */
    fun parseMap(
        root: Map<String, Any?>,
        nowMillis: Long = System.currentTimeMillis(),
        timeZone: TimeZone = TimeZone.getDefault(),
    ): WidgetSnapshot {
        val selectedDay = selectDay(root, localDate(nowMillis, timeZone))
        val hasProjectedDays = root["tomorrow"] != null || root["futureDays"] != null
        val selectedDate = selectedDay?.text("date") ?: root.firstText("date", "dateLabel") ?: ""
        val generatedAt = parseTimestamp(root["generatedAt"])
        val expiresAt = parseTimestamp(root["expiresAt"])
        val rawState = root.text("state")?.lowercase(Locale.US)
        val timetableName = root.firstText("timetableName", "title") ?: ""
        val semesterName = root.firstText("semesterName") ?: ""
        val teachingWeek = selectedDay?.nullableInt("teachingWeek")
        val weekday = selectedDay?.number("weekday")?.toInt()

        val state = when {
            rawState in setOf("notimetable", "no_timetable", "empty", "none") -> WidgetSnapshot.STATE_EMPTY
            rawState?.contains("corrupt") == true || rawState?.contains("invalid") == true ||
                rawState == "error" -> WidgetSnapshot.STATE_CORRUPT
            rawState?.contains("stale") == true || rawState?.contains("expired") == true ||
                rawState == "outdated" -> WidgetSnapshot.STATE_STALE
            expiresAt != null && nowMillis >= expiresAt -> WidgetSnapshot.STATE_STALE
            selectedDay == null && hasProjectedDays -> WidgetSnapshot.STATE_STALE
            selectedDay != null && teachingWeek == null -> WidgetSnapshot.STATE_OUTSIDE
            rawState == null && timetableName.isBlank() && semesterName.isBlank() -> WidgetSnapshot.STATE_EMPTY
            else -> WidgetSnapshot.STATE_READY
        }

        val coursesNode = selectedDay?.get("courses")
            ?: if (selectedDay == null) root["todayCourses"] ?: root["courses"] else null
        val courses = coursesFrom(coursesNode, selectedDate, nowMillis, timeZone)
        val next = deriveNext(courses, selectedDate, nowMillis, timeZone)

        return WidgetSnapshot(
            schemaVersion = root.number("schemaVersion")?.toInt()?.takeIf { it > 0 },
            state = state,
            generatedAt = generatedAt,
            expiresAt = expiresAt,
            timetableName = timetableName.ifBlank { semesterName },
            semesterName = semesterName,
            dateLabel = formatDate(selectedDate, weekday),
            weekLabel = teachingWeek?.takeIf { it > 0 }?.let { "第${it}周" } ?: "",
            next = next,
            today = courses,
        )
    }

    /** Returns the next inexact-alarm boundary: a course start/end or local midnight. */
    fun nextRefreshMillis(
        snapshot: WidgetSnapshot,
        nowMillis: Long = System.currentTimeMillis(),
        timeZone: TimeZone = TimeZone.getDefault(),
    ): Long {
        var next = nextLocalMidnight(nowMillis, timeZone)
        val selectedDate = localDate(nowMillis, timeZone)
        for (course in snapshot.today) {
            val range = parseTimeRange(course.time) ?: continue
            val start = localMinuteMillis(selectedDate, range.first, timeZone) ?: continue
            val end = localMinuteMillis(selectedDate, range.second, timeZone) ?: continue
            if (start > nowMillis && start < next) next = start
            if (end > nowMillis && end < next) next = end
        }
        return next
    }

    private fun selectDay(root: Map<String, Any?>, localDate: String): Map<String, Any?>? {
        val exactDays = buildList {
            root["today"].asMap()?.let(::add)
            root["tomorrow"].asMap()?.let(::add)
            val futureDays = root["futureDays"] as? List<*>
            futureDays?.mapNotNullTo(this) { it.asMap() }
        }
        return exactDays.firstOrNull { it.text("date") == localDate }
            // Older snapshots only contained `today`; retain their former display behavior.
            ?: if (root["tomorrow"] == null && root["futureDays"] == null) root["today"].asMap() else null
    }

    private fun coursesFrom(
        node: Any?,
        selectedDate: String,
        nowMillis: Long,
        timeZone: TimeZone,
    ): List<WidgetCourse> = when (node) {
        is List<*> -> node.mapNotNull { courseFrom(it, selectedDate, nowMillis, timeZone) }
        is Map<*, *> -> {
            val map = node.asMap() ?: return emptyList()
            val nested = map["courses"] ?: map["items"] ?: map["classes"]
            if (nested != null) coursesFrom(nested, selectedDate, nowMillis, timeZone)
            else courseFrom(map, selectedDate, nowMillis, timeZone)?.let(::listOf) ?: emptyList()
        }
        else -> emptyList()
    }

    private fun courseFrom(
        node: Any?,
        selectedDate: String,
        nowMillis: Long,
        timeZone: TimeZone,
    ): WidgetCourse? {
        val obj = node.asMap() ?: return null
        val name = obj.firstText("courseName", "name", "title", "subject") ?: return null
        val time = obj.firstText("time", "timeText", "periodText")
            ?: formatLegacyTime(
                obj.firstText("startTime", "start", "from", "begin"),
                obj.firstText("endTime", "end", "to", "finish"),
            )
        return WidgetCourse(
            name = name,
            time = time,
            location = obj.firstText("location", "room", "classroom", "place") ?: "",
            teacher = obj.firstText("teacher", "instructor", "lecturer") ?: "",
            startPeriod = obj.number("startPeriod")?.toInt(),
            endPeriod = obj.number("endPeriod")?.toInt(),
            color = obj.number("color")?.toLong()?.toInt(),
            // Never trust the published `ongoing` bit: it becomes stale while the widget is idle.
            ongoing = isOngoing(selectedDate, time, nowMillis, timeZone),
        )
    }

    private fun deriveNext(
        courses: List<WidgetCourse>,
        selectedDate: String,
        nowMillis: Long,
        timeZone: TimeZone,
    ): WidgetCourse? {
        if (selectedDate != localDate(nowMillis, timeZone)) return null
        val minute = localMinuteOfDay(nowMillis, timeZone)
        var active: WidgetCourse? = null
        var future: WidgetCourse? = null
        var futureStart = Int.MAX_VALUE
        for (course in courses) {
            val range = parseTimeRange(course.time) ?: continue
            if (minute in range.first until range.second) {
                active = active ?: course.copy(ongoing = true)
            } else if (range.first > minute && range.first < futureStart) {
                future = course.copy(ongoing = false)
                futureStart = range.first
            }
        }
        return active ?: future
    }

    private fun formatLegacyTime(start: String?, end: String?): String =
        listOfNotNull(start?.takeIf { it.isNotBlank() }, end?.takeIf { it.isNotBlank() })
            .joinToString("–")

    private fun isOngoing(selectedDate: String, time: String, nowMillis: Long, timeZone: TimeZone): Boolean {
        if (selectedDate != localDate(nowMillis, timeZone)) return false
        val range = parseTimeRange(time) ?: return false
        return localMinuteOfDay(nowMillis, timeZone) in range.first until range.second
    }

    private fun parseTimeRange(time: String): Pair<Int, Int>? {
        val match = TIME_RANGE.find(time.trim()) ?: return null
        val startHour = match.groupValues[1].toIntOrNull() ?: return null
        val startMinute = match.groupValues[2].toIntOrNull() ?: return null
        val endHour = match.groupValues[3].toIntOrNull() ?: return null
        val endMinute = match.groupValues[4].toIntOrNull() ?: return null
        if (startHour !in 0..23 || endHour !in 0..23 || startMinute !in 0..59 || endMinute !in 0..59) return null
        val start = startHour * 60 + startMinute
        val end = endHour * 60 + endMinute
        return if (end > start) start to end else null
    }

    private fun parseTimestamp(value: Any?): Long? {
        if (value is Number) {
            return if (value.toLong() > 10_000_000_000L) value.toLong() else value.toLong() * 1000
        }
        val text = (value as? String)?.trim() ?: return null
        val match = ISO_TIMESTAMP.matchEntire(text) ?: return null
        val fraction = match.groupValues[2]
        val milliseconds = when {
            fraction.isEmpty() -> ""
            else -> ".${fraction.take(3).padEnd(3, '0')}"
        }
        val zone = match.groupValues[3].uppercase(Locale.US)
        val normalized = match.groupValues[1] + milliseconds + zone
        val pattern = if (milliseconds.isEmpty()) "yyyy-MM-dd'T'HH:mm:ssXXX" else "yyyy-MM-dd'T'HH:mm:ss.SSSXXX"
        return try {
            SimpleDateFormat(pattern, Locale.US).apply {
                isLenient = false
                timeZone = TimeZone.getTimeZone("UTC")
            }.parse(normalized)?.time
        } catch (_: Exception) {
            null
        }
    }

    private fun localDate(nowMillis: Long, timeZone: TimeZone): String =
        SimpleDateFormat("yyyy-MM-dd", Locale.US).apply { this.timeZone = timeZone }.format(Date(nowMillis))

    private fun localMinuteOfDay(nowMillis: Long, timeZone: TimeZone): Int {
        val calendar = Calendar.getInstance(timeZone).apply { timeInMillis = nowMillis }
        return calendar.get(Calendar.HOUR_OF_DAY) * 60 + calendar.get(Calendar.MINUTE)
    }

    private fun nextLocalMidnight(nowMillis: Long, timeZone: TimeZone): Long =
        Calendar.getInstance(timeZone).apply {
            timeInMillis = nowMillis
            add(Calendar.DAY_OF_MONTH, 1)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis

    private fun localMinuteMillis(date: String, minuteOfDay: Int, timeZone: TimeZone): Long? {
        val dateMatch = DATE.matchEntire(date) ?: return null
        return Calendar.getInstance(timeZone).apply {
            isLenient = false
            clear()
            set(
                dateMatch.groupValues[1].toInt(),
                dateMatch.groupValues[2].toInt() - 1,
                dateMatch.groupValues[3].toInt(),
                minuteOfDay / 60,
                minuteOfDay % 60,
            )
        }.runCatching { timeInMillis }.getOrNull()
    }

    private fun formatDate(date: String, weekday: Int?): String {
        val match = DATE.find(date)
        val compactDate = match?.let { "${it.groupValues[2].toInt()}月${it.groupValues[3].toInt()}日" } ?: date
        val weekdayLabel = weekday?.takeIf { it in 1..7 }?.let { WEEKDAYS[it - 1] }
        return listOfNotNull(compactDate.takeIf { it.isNotBlank() }, weekdayLabel).joinToString(" ")
    }

    private fun Map<*, *>?.asMap(): Map<String, Any?>? = this?.entries
        ?.filter { it.key is String }
        ?.associate { it.key as String to it.value }

    private fun Any?.asMap(): Map<String, Any?>? = (this as? Map<*, *>)?.asMap()

    private fun Map<String, Any?>.firstText(vararg keys: String): String? = keys
        .asSequence().mapNotNull { text(it) }.firstOrNull { it.isNotBlank() }

    private fun Map<String, Any?>.text(key: String): String? = when (val value = this[key]) {
        is String -> value.trim()
        is Number, is Boolean -> value.toString()
        else -> null
    }

    private fun Map<String, Any?>.number(key: String): Number? = when (val value = this[key]) {
        is Number -> value
        is String -> value.toLongOrNull() ?: value.toDoubleOrNull()
        else -> null
    }

    private fun Map<String, Any?>.nullableInt(key: String): Int? = number(key)?.toInt()

    private fun jsonObjectToMap(objectValue: JSONObject): Map<String, Any?> {
        val result = linkedMapOf<String, Any?>()
        val keys = objectValue.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            result[key] = jsonValue(objectValue.opt(key))
        }
        return result
    }

    private fun jsonValue(value: Any?): Any? = when (value) {
        is JSONObject -> jsonObjectToMap(value)
        is JSONArray -> (0 until value.length()).map { jsonValue(value.opt(it)) }
        JSONObject.NULL -> null
        else -> value
    }

    private val DATE = Regex("^(\\d{4})-(\\d{2})-(\\d{2})$")
    private val TIME_RANGE = Regex("^(\\d{1,2}):(\\d{2})\\s*[-–—]\\s*(\\d{1,2}):(\\d{2})$")
    private val ISO_TIMESTAMP = Regex("^(\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2})(?:\\.(\\d+))?([zZ]|[+-]\\d{2}:\\d{2})$")
    private val WEEKDAYS = listOf("周一", "周二", "周三", "周四", "周五", "周六", "周日")
}
