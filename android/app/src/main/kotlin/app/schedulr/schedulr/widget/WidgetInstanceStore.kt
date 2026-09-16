package app.schedulr.schedulr.widget

import android.content.Context

class WidgetInstanceStore(context: Context) {
    private val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)

    fun readBinding(widgetId: Int): String? = preferences.getString(bindingKey(widgetId), null)

    fun writeBinding(widgetId: Int, timetableId: String) {
        preferences.edit().putString(bindingKey(widgetId), timetableId).apply()
    }

    fun deleteBinding(widgetId: Int) {
        preferences.edit().remove(bindingKey(widgetId)).apply()
    }

    fun restoreBindings(oldIds: IntArray, newIds: IntArray) {
        val editor = preferences.edit()
        oldIds.zip(newIds).forEach { (oldId, newId) ->
            readBinding(oldId)?.let { editor.putString(bindingKey(newId), it) }
            editor.remove(bindingKey(oldId))
        }
        editor.apply()
    }

    internal fun bindingKey(widgetId: Int): String = "$BINDING_PREFIX$widgetId"

    companion object {
        internal const val BINDING_PREFIX = "timetable."
        private const val PREFERENCES = "SchedulrWidgetInstances"

        @JvmStatic
        internal fun bindingKeyForTest(widgetId: Int): String = "$BINDING_PREFIX$widgetId"
    }
}
