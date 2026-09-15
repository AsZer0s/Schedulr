package app.schedulr.schedulr.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.Instant
import java.util.TimeZone

class WidgetSnapshotParserTest {
    @Test
    fun parsesExactFlutterSchemaAndSixDigitFractions() {
        val now = Instant.parse("2026-09-14T08:30:00Z").toEpochMilli()
        val snapshot = WidgetSnapshotParser.parseMap(
            snapshotMap(
                generatedAt = "2026-09-14T08:00:00.123456Z",
                today = day(
                    "2026-09-14",
                    1,
                    2,
                    listOf(
                        course("操作系统", "08:00-09:45", ongoing = false),
                        course("英语", null, startPeriod = 3, endPeriod = 3),
                    ),
                ),
            ),
            now,
            TimeZone.getTimeZone("UTC"),
        )

        assertEquals(1, snapshot.schemaVersion)
        assertEquals(WidgetSnapshot.STATE_READY, snapshot.state)
        assertEquals("主课表", snapshot.timetableName)
        assertEquals("2026-2027 第一学期", snapshot.semesterName)
        assertEquals("9月14日 周一", snapshot.dateLabel)
        assertEquals("第2周", snapshot.weekLabel)
        assertEquals(Instant.parse("2026-09-14T08:00:00.123Z").toEpochMilli(), snapshot.generatedAt)
        assertEquals("操作系统", snapshot.next?.name)
        assertTrue(snapshot.next?.ongoing == true)
        assertEquals(2, snapshot.today.size)
        assertEquals("", snapshot.today[1].time)
        assertEquals(3, snapshot.today[1].startPeriod)
    }

    @Test
    fun selectsFutureDayAtDeviceLocalMidnight() {
        val timeZone = TimeZone.getTimeZone("Asia/Shanghai")
        val snapshot = WidgetSnapshotParser.parseMap(
            snapshotMap(
                today = day("2026-09-15", 2, 2, listOf(course("周二课", "08:00-09:00"))),
                tomorrow = day("2026-09-16", 3, 2, listOf(course("周三课", "08:00-09:00"))),
                futureDays = listOf(
                    day("2026-09-17", 4, 2, listOf(course("周四课", "08:00-09:00"))),
                    day("2026-09-18", 5, 2, emptyList()),
                ),
            ),
            Instant.parse("2026-09-16T16:00:00Z").toEpochMilli(),
            timeZone,
        )

        assertEquals("9月17日 周四", snapshot.dateLabel)
        assertEquals(listOf("周四课"), snapshot.today.map { it.name })
        assertEquals("周四课", snapshot.next?.name)
        assertFalse(snapshot.next?.ongoing ?: true)
    }

    @Test
    fun keepsTomorrowAsTomorrowAndFallsBackOnlyToItsFirstCourse() {
        val timeZone = TimeZone.getTimeZone("UTC")
        val snapshot = WidgetSnapshotParser.parseMap(
            snapshotMap(
                today = day(
                    "2026-09-14",
                    1,
                    2,
                    listOf(course("已结束", "08:00-09:00")),
                ),
                tomorrow = day(
                    "2026-09-15",
                    2,
                    2,
                    listOf(
                        course("明天第一节", "08:00-09:00"),
                        course("明天第二节", "10:00-11:00"),
                    ),
                ),
                futureDays = listOf(
                    day("2026-09-16", 3, 2, listOf(course("后天课程", "08:00-09:00"))),
                ),
            ),
            Instant.parse("2026-09-14T12:00:00Z").toEpochMilli(),
            timeZone,
        )

        assertEquals(WidgetNextSource.TOMORROW, snapshot.nextSource)
        assertEquals("2026-09-15", snapshot.nextDate)
        assertEquals("明天第一节", snapshot.next?.name)
        assertEquals(listOf("已结束"), snapshot.today.map { it.name })
        assertEquals(listOf("明天第一节", "明天第二节"), snapshot.tomorrow.map { it.name })
        assertEquals(2, snapshot.tomorrowTeachingWeek)
    }

    @Test
    fun parsesTomorrowTeachingWeekAndKeepsTomorrowEmptyDistinct() {
        val snapshot = WidgetSnapshotParser.parseMap(
            snapshotMap(
                today = day("2026-09-14", 1, 2, emptyList()),
                tomorrow = day("2026-09-15", 2, null, emptyList()),
            ),
            Instant.parse("2026-09-14T12:00:00Z").toEpochMilli(),
            TimeZone.getTimeZone("UTC"),
        )

        assertEquals(WidgetNextSource.NONE, snapshot.nextSource)
        assertEquals("2026-09-15", snapshot.tomorrowDate)
        assertNull(snapshot.tomorrowTeachingWeek)
        assertTrue(snapshot.tomorrow.isEmpty())
    }

    @Test
    fun doesNotSkipTomorrowWhenTomorrowIsToday() {
        val snapshot = WidgetSnapshotParser.parseMap(
            snapshotMap(
                today = day("2026-09-15", 2, 2, listOf(course("昨天", "08:00-09:00"))),
                tomorrow = day("2026-09-16", 3, 2, listOf(course("今天的课表", "08:00-09:00"))),
                futureDays = listOf(
                    day("2026-09-17", 4, 2, listOf(course("后天", "08:00-09:00"))),
                ),
            ),
            Instant.parse("2026-09-16T08:00:00Z").toEpochMilli(),
            TimeZone.getTimeZone("UTC"),
        )

        assertEquals("9月16日 周三", snapshot.dateLabel)
        assertEquals(listOf("今天的课表"), snapshot.today.map { it.name })
        assertEquals("今天的课表", snapshot.next?.name)
        assertEquals(WidgetNextSource.TODAY, snapshot.nextSource)
    }

    @Test
    fun storedOngoingFlagBecomesFalseAfterCourseEnds() {
        val snapshot = WidgetSnapshotParser.parseMap(
            snapshotMap(
                today = day(
                    "2026-09-14",
                    1,
                    2,
                    listOf(
                        course("已结束", "08:00-09:00", ongoing = true),
                        course("下一节", "10:00-11:00"),
                    ),
                ),
                next = course("已结束", "08:00-09:00", ongoing = true),
            ),
            Instant.parse("2026-09-14T09:30:00Z").toEpochMilli(),
            TimeZone.getTimeZone("UTC"),
        )

        assertFalse(snapshot.today.first().ongoing)
        assertEquals("下一节", snapshot.next?.name)
        assertFalse(snapshot.next?.ongoing ?: true)
    }

    @Test
    fun nextCourseTransitionsAtEndBoundary() {
        val root = snapshotMap(
            today = day(
                "2026-09-14",
                1,
                2,
                listOf(
                    course("第一节", "08:00-09:00"),
                    course("第二节", "09:30-10:30"),
                ),
            ),
        )
        val timeZone = TimeZone.getTimeZone("UTC")

        val beforeEnd = WidgetSnapshotParser.parseMap(
            root,
            Instant.parse("2026-09-14T08:59:00Z").toEpochMilli(),
            timeZone,
        )
        val atEnd = WidgetSnapshotParser.parseMap(
            root,
            Instant.parse("2026-09-14T09:00:00Z").toEpochMilli(),
            timeZone,
        )

        assertEquals("第一节", beforeEnd.next?.name)
        assertTrue(beforeEnd.next?.ongoing == true)
        assertEquals("第二节", atEnd.next?.name)
        assertFalse(atEnd.next?.ongoing ?: true)
    }

    @Test
    fun refreshBoundaryUsesCourseStartEndThenMidnight() {
        val timeZone = TimeZone.getTimeZone("UTC")
        val now = Instant.parse("2026-09-14T08:30:00Z").toEpochMilli()
        val snapshot = WidgetSnapshotParser.parseMap(
            snapshotMap(
                today = day(
                    "2026-09-14",
                    1,
                    2,
                    listOf(
                        course("当前", "08:00-09:00"),
                        course("稍后", "10:00-11:00"),
                    ),
                ),
            ),
            now,
            timeZone,
        )

        assertEquals(
            Instant.parse("2026-09-14T09:00:00Z").toEpochMilli(),
            WidgetSnapshotParser.nextRefreshMillis(snapshot, now, timeZone),
        )

        val afterCourses = Instant.parse("2026-09-14T11:30:00Z").toEpochMilli()
        val afterSnapshot = WidgetSnapshotParser.parseMap(snapshotMap(today = day("2026-09-14", 1, 2, emptyList())), afterCourses, timeZone)
        assertEquals(
            Instant.parse("2026-09-15T00:00:00Z").toEpochMilli(),
            WidgetSnapshotParser.nextRefreshMillis(afterSnapshot, afterCourses, timeZone),
        )
    }

    @Test
    fun noTimetableRemainsEmptyButNullWeekOnSelectedDayIsOutsideSemester() {
        val now = Instant.parse("2026-09-15T08:00:00Z").toEpochMilli()
        val noTimetable = WidgetSnapshotParser.parseMap(
            snapshotMap(
                state = "noTimetable",
                timetableName = null,
                semesterName = null,
                today = day("2026-09-15", 2, null, emptyList()),
            ),
            now,
            TimeZone.getTimeZone("UTC"),
        )
        val outside = WidgetSnapshotParser.parseMap(
            snapshotMap(
                state = "ready",
                today = day("2026-09-15", 2, null, emptyList()),
            ),
            now,
            TimeZone.getTimeZone("UTC"),
        )

        assertEquals(WidgetSnapshot.STATE_EMPTY, noTimetable.state)
        assertEquals(WidgetSnapshot.STATE_OUTSIDE, outside.state)
        assertNull(outside.next)
    }

    @Test
    fun missingProjectedDateBecomesStale() {
        val snapshot = WidgetSnapshotParser.parseMap(
            snapshotMap(
                today = day("2026-09-14", 1, 2, emptyList()),
                tomorrow = day("2026-09-15", 2, 2, emptyList()),
            ),
            Instant.parse("2026-09-16T08:00:00Z").toEpochMilli(),
            TimeZone.getTimeZone("UTC"),
        )

        assertEquals(WidgetSnapshot.STATE_STALE, snapshot.state)
        assertTrue(snapshot.today.isEmpty())
    }

    @Test
    fun expiredReadySnapshotBecomesStale() {
        val snapshot = WidgetSnapshotParser.parseMap(
            snapshotMap(
                expiresAt = "2026-09-14T08:59:59.000000Z",
                today = day("2026-09-14", 1, 2, emptyList()),
            ),
            Instant.parse("2026-09-14T09:00:00Z").toEpochMilli(),
            TimeZone.getTimeZone("UTC"),
        )

        assertEquals(WidgetSnapshot.STATE_STALE, snapshot.state)
    }

    @Test
    fun explicitCorruptStateIsSafe() {
        val snapshot = WidgetSnapshotParser.parseMap(mapOf("state" to "corrupt"))
        assertEquals(WidgetSnapshot.STATE_CORRUPT, snapshot.state)
        assertTrue(snapshot.today.isEmpty())
    }

    private fun snapshotMap(
        state: String = "ready",
        generatedAt: String = "2026-09-14T08:00:00.000000Z",
        expiresAt: String = "2026-09-20T23:59:59.000000Z",
        timetableName: String? = "主课表",
        semesterName: String? = "2026-2027 第一学期",
        today: Map<String, Any?> = day("2026-09-14", 1, 2, emptyList()),
        next: Map<String, Any?>? = null,
        tomorrow: Map<String, Any?> = day("2026-09-15", 2, 2, emptyList()),
        futureDays: List<Map<String, Any?>> = emptyList(),
    ): Map<String, Any?> = mapOf(
        "schemaVersion" to 1,
        "state" to state,
        "generatedAt" to generatedAt,
        "expiresAt" to expiresAt,
        "timetableName" to timetableName,
        "semesterName" to semesterName,
        "today" to today,
        "next" to next,
        "tomorrow" to tomorrow,
        "futureDays" to futureDays,
    )

    private fun day(
        date: String,
        weekday: Int,
        teachingWeek: Int?,
        courses: List<Map<String, Any?>>,
    ): Map<String, Any?> = mapOf(
        "date" to date,
        "weekday" to weekday,
        "teachingWeek" to teachingWeek,
        "courses" to courses,
    )

    private fun course(
        name: String,
        time: String?,
        ongoing: Boolean = false,
        startPeriod: Int? = 1,
        endPeriod: Int? = 2,
    ): Map<String, Any?> = mapOf(
        "courseId" to name,
        "sessionId" to "$name-session",
        "courseName" to name,
        "teacher" to "张老师",
        "location" to "13-301",
        "time" to time,
        "startPeriod" to startPeriod,
        "endPeriod" to endPeriod,
        "color" to 0xFF123456,
        "ongoing" to ongoing,
    )
}
