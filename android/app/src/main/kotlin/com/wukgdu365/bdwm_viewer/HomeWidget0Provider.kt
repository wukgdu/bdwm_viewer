package com.wukgdu365.bdwm_viewer

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

const val HOME_WIDGET_LAUNCH_ACTION = "es.antonborri.home_widget.action.LAUNCH"

class HomeWidget0Provider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.home_widget0).apply({
                // Open App on Widget Click
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                val builder = RemoteViews.RemoteCollectionItems.Builder()
                val itemsString = widgetData.getString("_top10string", "");
                if (!itemsString.isNullOrEmpty()) {
                    val values = itemsString.split("\n".toRegex()).toTypedArray();
                    val dataLength: Int = (values.size-1) / 2;
                    for (index in 0 until dataLength) {
                        val title = values[index*2];
                        val link = values[index*2+1];
                        val rv = RemoteViews(context.packageName, R.layout.widget_item).apply {
                            setTextViewText(R.id.widget_item, title);
                            val intent = Intent()
                            intent.data = Uri.parse("bdwmViewer://obvieweropenlink?link=$link")
                            intent.setData(Uri.parse(intent.toUri(Intent.URI_INTENT_SCHEME)));
                            setOnClickFillInIntent(R.id.widget_item, intent);
                            // setOnClickPendingIntent(R.id.widget_item, pendingIntentWithData)
                        }

                        builder.addItem(index.toLong(), rv);
                    }

                    val intent = Intent(context, MainActivity::class.java)
                    intent.action = HOME_WIDGET_LAUNCH_ACTION

                    var flags = PendingIntent.FLAG_UPDATE_CURRENT
                    if (Build.VERSION.SDK_INT >= 23) {
                        flags = flags or PendingIntent.FLAG_IMMUTABLE
                    }

                    var listViewPendingIntent = PendingIntent.getActivity(context, 0, intent, flags)
                    setPendingIntentTemplate(R.id.list_view, listViewPendingIntent)
                }
                val collectionItems = builder.setHasStableIds(true).build()
                setRemoteAdapter(R.id.list_view, collectionItems)
                setEmptyView(R.id.list_view, R.id.empty_view)

                // Pending intent to update counter on button click
                val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(context,
                    Uri.parse("bdwmViewer://obviewerupdatetop10"))
                setOnClickPendingIntent(R.id.bt_update, backgroundIntent)
            });

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}