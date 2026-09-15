package app.schedulr.schedulr.widget

/** Pure display decision used by the Android widget receiver. */
enum class WidgetHeroSource {
    TODAY,
    TOMORROW,
    TOMORROW_EMPTY,
    TOMORROW_OUTSIDE,
    NONE,
}

data class WidgetHero(
    val source: WidgetHeroSource,
    val course: WidgetCourse? = null,
)

object WidgetDisplayStrategy {
    fun hero(snapshot: WidgetSnapshot): WidgetHero = when {
        snapshot.nextSource == WidgetNextSource.TODAY && snapshot.next != null ->
            WidgetHero(WidgetHeroSource.TODAY, snapshot.next)
        snapshot.nextSource == WidgetNextSource.TOMORROW && snapshot.next != null ->
            WidgetHero(WidgetHeroSource.TOMORROW, snapshot.next)
        snapshot.tomorrowTeachingWeek == null ->
            WidgetHero(WidgetHeroSource.TOMORROW_OUTSIDE)
        snapshot.tomorrow.isEmpty() ->
            WidgetHero(WidgetHeroSource.TOMORROW_EMPTY)
        else -> WidgetHero(WidgetHeroSource.NONE)
    }
}
