package app.schedulr.schedulr.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.text.TextUtils
import android.view.View
import android.widget.RemoteViews
import app.schedulr.schedulr.MainActivity
import app.schedulr.schedulr.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin

class SchedulrWidgetReceiver : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        renderAll(context, appWidgetManager, appWidgetIds)
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_REFRESH) {
            val manager = AppWidgetManager.getInstance(context)
            val widgetIds = manager.getAppWidgetIds(ComponentName(context, SchedulrWidgetReceiver::class.java))
            if (widgetIds.isEmpty()) {
                cancelRefresh(context)
            } else {
                renderAll(context, manager, widgetIds)
            }
            return
        }
        super.onReceive(context, intent)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        val snapshot = render(context, appWidgetManager, appWidgetId, newOptions)
        scheduleRefresh(context, WidgetSnapshotParser.nextRefreshMillis(snapshot))
    }

    override fun onDisabled(context: Context) {
        cancelRefresh(context)
        super.onDisabled(context)
    }

    private fun renderAll(
        context: Context,
        manager: AppWidgetManager,
        widgetIds: IntArray,
    ) {
        var refreshAt: Long? = null
        widgetIds.forEach { widgetId ->
            val snapshot = render(context, manager, widgetId, null)
            val candidate = WidgetSnapshotParser.nextRefreshMillis(snapshot)
            refreshAt = refreshAt?.let { minOf(it, candidate) } ?: candidate
        }
        refreshAt?.let { scheduleRefresh(context, it) } ?: cancelRefresh(context)
    }

    private fun render(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
        options: Bundle?,
    ): WidgetSnapshot {
        val resolvedOptions = options ?: manager.getAppWidgetOptions(widgetId)
        val compact = isCompact(resolvedOptions)
        val snapshot = try {
            WidgetSnapshotParser.parse(
                HomeWidgetPlugin.getData(context).getString(SNAPSHOT_KEY, null),
            )
        } catch (_: Exception) {
            WidgetSnapshot(state = WidgetSnapshot.STATE_CORRUPT)
        }
        val views = RemoteViews(
            context.packageName,
            if (compact) R.layout.schedulr_widget_compact else R.layout.schedulr_widget_medium,
        )
        views.setOnClickPendingIntent(R.id.widget_container, openAppPendingIntent(context))
        bindSnapshot(views, snapshot, compact)
        manager.updateAppWidget(widgetId, views)
        return snapshot
    }

    private fun bindSnapshot(views: RemoteViews, snapshot: WidgetSnapshot, compact: Boolean) {
        views.setTextViewText(R.id.widget_timetable_name, snapshot.timetableName.ifBlank { "Schedulr" })
        views.setTextViewText(
            R.id.widget_date,
            listOf(snapshot.dateLabel, snapshot.weekLabel).filter { it.isNotBlank() }.joinToString(" · ")
                .ifBlank { "课表概览" },
        )

        when {
            snapshot.isCorrupt -> {
                views.setTextViewText(R.id.widget_next_label, "暂时无法读取")
                views.setTextViewText(R.id.widget_next_name, "课表数据格式有误")
                views.setTextViewText(R.id.widget_next_detail, "打开应用后刷新")
                hideRows(views)
            }
            snapshot.state == WidgetSnapshot.STATE_OUTSIDE -> {
                views.setTextViewText(R.id.widget_next_label, "当前不在教学周")
                views.setTextViewText(R.id.widget_next_name, "查看学期设置")
                views.setTextViewText(R.id.widget_next_detail, "点击打开 Schedulr")
                hideRows(views)
            }
            snapshot.isStale -> {
                views.setTextViewText(R.id.widget_next_label, "数据已过期")
                views.setTextViewText(R.id.widget_next_name, "请打开应用更新课表")
                views.setTextViewText(R.id.widget_next_detail, "")
                hideRows(views)
            }
            snapshot.state == WidgetSnapshot.STATE_EMPTY -> {
                views.setTextViewText(R.id.widget_next_label, "暂无课表")
                views.setTextViewText(R.id.widget_next_name, "先导入一份课表吧")
                views.setTextViewText(R.id.widget_next_detail, "点击打开 Schedulr")
                hideRows(views)
            }
            else -> {
                val next = snapshot.next
                views.setTextViewText(R.id.widget_next_label, if (next?.ongoing == true) "正在上课" else "下一节")
                views.setTextViewText(R.id.widget_next_name, next?.name ?: "今天没有更多课程")
                views.setTextViewText(
                    R.id.widget_next_detail,
                    next?.let { detail(it, compact) } ?: "享受今天的空闲时间",
                )
                bindRows(views, snapshot.today, compact)
            }
        }
    }

    private fun bindRows(views: RemoteViews, courses: List<WidgetCourse>, compact: Boolean) {
        val rows = listOf(
            Triple(R.id.widget_course_1, R.id.widget_course_name_1, R.id.widget_course_detail_1),
            Triple(R.id.widget_course_2, R.id.widget_course_name_2, R.id.widget_course_detail_2),
            Triple(R.id.widget_course_3, R.id.widget_course_name_3, R.id.widget_course_detail_3),
        )
        rows.forEachIndexed { index, ids ->
            val visible = index < courses.size && (!compact || index < 2)
            views.setViewVisibility(ids.first, if (visible) View.VISIBLE else View.GONE)
            if (visible) {
                val course = courses[index]
                views.setTextViewText(ids.second, course.name)
                views.setTextViewText(ids.third, detail(course, compact))
            }
        }
    }

    private fun hideRows(views: RemoteViews) {
        listOf(R.id.widget_course_1, R.id.widget_course_2, R.id.widget_course_3)
            .forEach { views.setViewVisibility(it, View.GONE) }
    }

    private fun detail(course: WidgetCourse, compact: Boolean): String {
        val time = course.time.ifBlank {
            when {
                course.startPeriod != null && course.endPeriod != null ->
                    if (course.startPeriod == course.endPeriod) "第${course.startPeriod}节" else "第${course.startPeriod}–${course.endPeriod}节"
                course.startPeriod != null -> "第${course.startPeriod}节"
                else -> ""
            }
        }
        val location = course.location.trim().takeIf { it.isNotBlank() }?.let {
            val limit = if (compact) 14 else 28
            TextUtils.ellipsize(
                it,
                android.text.TextPaint().apply { textSize = 14f },
                limit.toFloat(),
                TextUtils.TruncateAt.END,
            ).toString()
        }
        return listOf(time, location, course.teacher.takeIf { it.isNotBlank() })
            .filterNotNull().filter { it.isNotBlank() }.joinToString(" · ").ifBlank { "时间待定" }
    }

    private fun openAppPendingIntent(context: Context): PendingIntent =
        HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("schedulr://home?homeWidget"),
        )

    private fun isCompact(options: Bundle): Boolean {
        val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        return (width > 0 && (width < 250 || height < 140)) ||
            (width == 0 && height == 0)
    }

    companion object {
        const val SNAPSHOT_KEY = "schedulr.widget.snapshot.v1"
        internal const val ACTION_REFRESH = "app.schedulr.schedulr.widget.REFRESH"
        private const val REFRESH_REQUEST_CODE = 1042

        private fun refreshPendingIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
            context,
            REFRESH_REQUEST_CODE,
            Intent(context, SchedulrWidgetReceiver::class.java).setAction(ACTION_REFRESH),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        private fun scheduleRefresh(context: Context, triggerAtMillis: Long) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarmManager.cancel(refreshPendingIntent(context))
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC,
                triggerAtMillis,
                refreshPendingIntent(context),
            )
        }

        private fun cancelRefresh(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val pendingIntent = refreshPendingIntent(context)
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
        }
    }
}
