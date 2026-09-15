package app.schedulr.schedulr.widget

import java.io.File
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class WidgetRemoteViewsLayoutTest {
    @Test
    fun layoutsUseOnlyRemoteViewsSafeWidgets() {
        val root = File("src/main/res/layout")
        val layouts = listOf("schedulr_widget_compact.xml", "schedulr_widget_medium.xml")
        layouts.forEach { name ->
            val text = File(root, name).readText()
            assertFalse("$name must not contain generic View", Regex("<View(?:\\s|>)").containsMatchIn(text))
            assertFalse(
                "$name must not contain custom widgets",
                Regex("<\\s*[A-Za-z_][A-Za-z0-9_]*\\.[A-Za-z0-9_.]+").containsMatchIn(text),
            )
            assertTrue("$name must use a FrameLayout root", text.contains("<FrameLayout"))
        }
    }
}
