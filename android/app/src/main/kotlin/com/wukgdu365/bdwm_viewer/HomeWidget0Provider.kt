package com.wukgdu365.bdwm_viewer

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class HomeWidget0Provider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.home_widget0).apply({
                // Open App on Widget Click
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                val itemsString = widgetData.getString("_top10string", "");
                if (itemsString!=null) {
                    if (!itemsString.isEmpty()) {
                        val values = itemsString.split("\n".toRegex()).toTypedArray();
                        if (values.size > 20) {
                            setTextViewText(R.id.top10_1, values[0]);
                            setTextViewText(R.id.top10_2, values[2]);
                            setTextViewText(R.id.top10_3, values[4]);
                            setTextViewText(R.id.top10_4, values[6]);
                            setTextViewText(R.id.top10_5, values[8]);
                            setTextViewText(R.id.top10_6, values[10]);
                            setTextViewText(R.id.top10_7, values[12]);
                            setTextViewText(R.id.top10_8, values[14]);
                            setTextViewText(R.id.top10_9, values[16]);
                            setTextViewText(R.id.top10_10, values[18]);
                        }
                    }
                }

                // Pending intent to update counter on button click
                val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(context,
                        Uri.parse("bdwmViewer://obviewerupdatetop10"))
                setOnClickPendingIntent(R.id.bt_update, backgroundIntent)
            });

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}