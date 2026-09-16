package app.schedulr.schedulr.widget

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.widget.ArrayAdapter
import android.widget.ListView
import android.widget.Toast
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject

class SchedulrWidgetConfigureActivity : Activity() {
    private var appWidgetId: Int = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)
        appWidgetId = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        )
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        val entries = catalogEntries()
        if (entries.isEmpty()) {
            Toast.makeText(this, "请先在 Schedulr 中创建课表", Toast.LENGTH_LONG).show()
            finish()
            return
        }

        val labels = entries.map { "${it.name} · ${it.semesterName}" }.toTypedArray()
        val list = ListView(this).apply {
            adapter = ArrayAdapter(
                this@SchedulrWidgetConfigureActivity,
                android.R.layout.simple_list_item_single_choice,
                labels,
            )
            choiceMode = ListView.CHOICE_MODE_SINGLE
            val current = WidgetInstanceStore(this@SchedulrWidgetConfigureActivity)
                .readBinding(appWidgetId)
            val selected = entries.indexOfFirst { it.id == current }
            if (selected >= 0) setItemChecked(selected, true)
            setOnItemClickListener { _, _, position, _ -> finishWith(entries[position].id) }
        }
        setContentView(list)
        title = "选择课表"
    }

    private fun finishWith(timetableId: String) {
        WidgetInstanceStore(this).writeBinding(appWidgetId, timetableId)
        sendBroadcast(
            Intent(this, SchedulrWidgetReceiver::class.java)
                .setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
                .putExtra(
                    AppWidgetManager.EXTRA_APPWIDGET_IDS,
                    intArrayOf(appWidgetId),
                ),
        )
        val result = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        setResult(RESULT_OK, result)
        finish()
    }

    private fun catalogEntries(): List<CatalogEntry> {
        val raw = HomeWidgetPlugin.getData(this)
            .getString(WidgetCatalogParser.CATALOG_KEY, null) ?: return emptyList()
        return runCatching {
            val array = JSONObject(raw).optJSONArray("timetables") ?: JSONArray()
            (0 until array.length()).mapNotNull { index ->
                val entry = array.optJSONObject(index) ?: return@mapNotNull null
                val id = entry.optString("timetableId")
                if (id.isBlank()) return@mapNotNull null
                CatalogEntry(
                    id = id,
                    name = entry.optString("timetableName", "课表"),
                    semesterName = entry.optString("semesterName", ""),
                )
            }
        }.getOrDefault(emptyList())
    }

    private data class CatalogEntry(
        val id: String,
        val name: String,
        val semesterName: String,
    )
}
