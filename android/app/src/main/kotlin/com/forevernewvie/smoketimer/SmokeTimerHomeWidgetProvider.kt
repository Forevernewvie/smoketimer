package com.forevernewvie.smoketimer

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class SmokeTimerHomeWidgetProvider : HomeWidgetProvider() {
    /// Updates every active widget instance from the shared HomeWidget payload.
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.smoke_timer_home_widget).apply {
                setTextViewText(
                    R.id.widget_primary_value,
                    widgetData.getString(KEY_PRIMARY_VALUE, DEFAULT_PRIMARY_VALUE),
                )
                setTextViewText(
                    R.id.widget_status_title,
                    widgetData.getString(KEY_STATUS_TITLE, DEFAULT_STATUS_TITLE),
                )
                setTextViewText(
                    R.id.widget_next_alert_label,
                    widgetData.getString(KEY_NEXT_ALERT_LABEL, DEFAULT_NEXT_ALERT_LABEL),
                )
                setTextViewText(
                    R.id.widget_next_alert_value,
                    widgetData.getString(KEY_NEXT_ALERT_VALUE, DEFAULT_NEXT_ALERT_VALUE),
                )
                setTextViewText(
                    R.id.widget_today_count,
                    widgetData.getString(KEY_TODAY_COUNT_LABEL, DEFAULT_TODAY_COUNT_LABEL),
                )
                setTextViewText(
                    R.id.widget_today_spend,
                    widgetData.getString(KEY_TODAY_SPEND_LABEL, DEFAULT_TODAY_SPEND_LABEL),
                )
                setOnClickPendingIntent(R.id.widget_root, createLaunchIntent(context, widgetId))
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    /// Creates a safe launch intent that opens the app when the widget is tapped.
    private fun createLaunchIntent(context: Context, widgetId: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(EXTRA_WIDGET_ORIGIN, true)
        }
        return PendingIntent.getActivity(
            context,
            widgetId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    companion object {
        private const val KEY_PRIMARY_VALUE = "primary_value"
        private const val KEY_STATUS_TITLE = "status_title"
        private const val KEY_NEXT_ALERT_LABEL = "next_alert_label"
        private const val KEY_NEXT_ALERT_VALUE = "next_alert_value"
        private const val KEY_TODAY_COUNT_LABEL = "today_count_label"
        private const val KEY_TODAY_SPEND_LABEL = "today_spend_label"

        private const val DEFAULT_PRIMARY_VALUE = "첫 기록 전"
        private const val DEFAULT_STATUS_TITLE = "기록을 남기면 타이머가 시작돼요"
        private const val DEFAULT_NEXT_ALERT_LABEL = "다음 알림"
        private const val DEFAULT_NEXT_ALERT_VALUE = "첫 기록 후 시작"
        private const val DEFAULT_TODAY_COUNT_LABEL = "오늘 0개비"
        private const val DEFAULT_TODAY_SPEND_LABEL = "가격 설정 필요"

        private const val EXTRA_WIDGET_ORIGIN = "opened_from_home_widget"
    }
}
