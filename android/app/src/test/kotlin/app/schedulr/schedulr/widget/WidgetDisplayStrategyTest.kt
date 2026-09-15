package app.schedulr.schedulr.widget

import org.junit.Assert.assertEquals
import org.junit.Test

class WidgetDisplayStrategyTest {
    @Test
    fun todayCourseKeepsOriginalNowPlayingOrNextCopySource() {
        val ongoing = WidgetCourse(name = "正在上的课", ongoing = true)
        val snapshot = WidgetSnapshot(
            state = WidgetSnapshot.STATE_READY,
            next = ongoing,
            nextSource = WidgetNextSource.TODAY,
            today = listOf(ongoing),
            tomorrowTeachingWeek = 3,
        )

        val hero = WidgetDisplayStrategy.hero(snapshot)

        assertEquals(WidgetHeroSource.TODAY, hero.source)
        assertEquals("正在上的课", hero.course?.name)
    }

    @Test
    fun tomorrowCourseUsesTomorrowFirstLessonSource() {
        val first = WidgetCourse(name = "明天第一节")
        val snapshot = WidgetSnapshot(
            state = WidgetSnapshot.STATE_READY,
            next = first,
            nextSource = WidgetNextSource.TOMORROW,
            tomorrow = listOf(first, WidgetCourse(name = "明天第二节")),
            tomorrowTeachingWeek = 4,
        )

        assertEquals(WidgetHeroSource.TOMORROW, WidgetDisplayStrategy.hero(snapshot).source)
    }

    @Test
    fun tomorrowEmptyAndOutsideTeachingWeekHaveSeparateMessages() {
        val empty = WidgetSnapshot(
            state = WidgetSnapshot.STATE_READY,
            tomorrowTeachingWeek = 4,
            tomorrow = emptyList(),
        )
        val outside = WidgetSnapshot(
            state = WidgetSnapshot.STATE_READY,
            tomorrowTeachingWeek = null,
            tomorrow = emptyList(),
        )

        assertEquals(WidgetHeroSource.TOMORROW_EMPTY, WidgetDisplayStrategy.hero(empty).source)
        assertEquals(WidgetHeroSource.TOMORROW_OUTSIDE, WidgetDisplayStrategy.hero(outside).source)
    }
}
