package app.schedulr.schedulr.widget

import android.content.Intent

/** Pure broadcast policy used by the receiver and unit-tested without Android UI tooling. */
object WidgetLifecyclePolicy {
    const val ACTION_REFRESH = "app.schedulr.schedulr.widget.REFRESH"

    fun shouldRefreshAll(action: String?): Boolean = when (action) {
        ACTION_REFRESH,
        Intent.ACTION_BOOT_COMPLETED,
        Intent.ACTION_MY_PACKAGE_REPLACED,
        Intent.ACTION_TIMEZONE_CHANGED,
        Intent.ACTION_TIME_CHANGED,
        Intent.ACTION_DATE_CHANGED,
        -> true
        else -> false
    }
}
