package app.schedulr.schedulr.widget

import org.junit.Assert.assertEquals
import org.junit.Test

class WidgetInstanceStoreTest {
    @Test
    fun bindingKeysAreStableAndNamespaced() {
        val store = WidgetInstanceStore::class
        assertEquals("timetable.42", WidgetInstanceStore.bindingKeyForTest(42))
        assertEquals("timetable.57", WidgetInstanceStore.bindingKeyForTest(57))
    }
}
