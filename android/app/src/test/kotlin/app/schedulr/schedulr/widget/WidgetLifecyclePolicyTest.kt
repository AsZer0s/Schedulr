package app.schedulr.schedulr.widget

import android.appwidget.AppWidgetManager
import android.content.Intent
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class WidgetLifecyclePolicyTest {
    @Test
    fun refreshesForLocalAndSystemLifecycleEvents() {
        listOf(
            WidgetLifecyclePolicy.ACTION_REFRESH,
            AppWidgetManager.ACTION_APPWIDGET_UPDATE,
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_DATE_CHANGED,
        ).forEach { action ->
            if (action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
                assertFalse(WidgetLifecyclePolicy.shouldRefreshAll(action))
            } else {
                assertTrue(WidgetLifecyclePolicy.shouldRefreshAll(action))
            }
        }
    }

    @Test
    fun ignoresUnrelatedBroadcasts() {
        assertFalse(WidgetLifecyclePolicy.shouldRefreshAll(null))
        assertFalse(WidgetLifecyclePolicy.shouldRefreshAll(Intent.ACTION_SCREEN_ON))
        assertFalse(WidgetLifecyclePolicy.shouldRefreshAll("app.schedulr.UNRELATED"))
    }
}
