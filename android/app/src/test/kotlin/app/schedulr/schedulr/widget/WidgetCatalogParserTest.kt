package app.schedulr.schedulr.widget

import org.junit.Assert.assertEquals
import org.junit.Test

class WidgetCatalogParserTest {
    @Test
    fun selectsRequestedEntryByStableId() {
        val catalog = mapOf<String, Any?>(
            "schemaVersion" to 2,
            "defaultTimetableId" to "a",
            "timetables" to listOf(
                mapOf("timetableId" to "a", "timetableName" to "本人课表"),
                mapOf("timetableId" to "b", "timetableName" to "同学课表"),
            ),
        )

        assertEquals("同学课表", WidgetCatalogParser.selectMap(catalog, "b")?.timetableName)
        assertEquals("本人课表", WidgetCatalogParser.selectMap(catalog, "a")?.timetableName)
    }
}
