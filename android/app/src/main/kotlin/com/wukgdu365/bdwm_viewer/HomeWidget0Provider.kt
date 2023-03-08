package com.wukgdu365.bdwm_viewer

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
// import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.widget.RemoteViews
import android.widget.Toast;
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin

const val LAUNCH_JUMP_ACTION = "com.wukgdu365.bdwm_viewer.action.LAUNCH_JUMP"
const val EXTRA_ITEM = "com.wukgdu365.bdwm_viewer.link"
const val HOME_WIDGET_LAUNCH_ACTION = "es.antonborri.home_widget.action.LAUNCH"

class HomeWidget0Provider : AppWidgetProvider() {
    override fun onReceive(context: Context, intent: Intent) {
        // val mgr: AppWidgetManager = AppWidgetManager.getInstance(context)
        if (intent.action == LAUNCH_JUMP_ACTION) {
            val link = intent.getStringExtra(EXTRA_ITEM)
            if (link == null) { return }

            val intent = Intent(context, MainActivity::class.java)
            intent.data = Uri.parse("bdwmViewer://obvieweropenlink?link=${Uri.encode(link)}")
            intent.action = HOME_WIDGET_LAUNCH_ACTION
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(intent);
        }
        super.onReceive(context, intent)
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val widgetData = HomeWidgetPlugin.getData(context) // SharedPreferences
        val itemStatus = widgetData.getString("_top10status", "更新十大中");
        Toast.makeText(context, itemStatus, Toast.LENGTH_SHORT).show()
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.home_widget0).apply({
                // Open App on Widget Click
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                if (Build.VERSION.SDK_INT >= 31) {
                // if (false) {
                    val builder = RemoteViews.RemoteCollectionItems.Builder()
                    val itemsString = widgetData.getString("_top10string", "");
                    if (!itemsString.isNullOrEmpty()) {
                        val itemKind: Int = 3;
                        val values = itemsString.split("\n".toRegex()).toTypedArray();
                        val dataLength: Int = (values.size-1) / itemKind;
                        for (index in 0 until dataLength) {
                            val title = values[index*itemKind];
                            val link = values[index*itemKind+1];
                            val commentCount = values[index*itemKind+2];
                            val rv = RemoteViews(context.packageName, R.layout.widget_item).apply {
                                setTextViewText(R.id.widget_title, title);
                                setTextViewText(R.id.widget_count, commentCount);
                                val fillInIntent = Intent().apply {
                                    Bundle().also { extras ->
                                        extras.putString(EXTRA_ITEM, link)
                                        putExtras(extras)
                                    }
                                }
                                // fillInIntent.data = Uri.parse("bdwmViewer://obvieweropenlink?link=$link")
                                // fillInIntent.putExtra("_link", fillInIntent.data)
                                // fillInIntent.setData(Uri.parse(fillInIntent.toUri(Intent.URI_INTENT_SCHEME)));
                                setOnClickFillInIntent(R.id.widget_item, fillInIntent);
                            }
                            builder.addItem(index.toLong(), rv);
                        }

                    }
                    val collectionItems = builder.setHasStableIds(true).build()
                    setRemoteAdapter(R.id.list_view, collectionItems)
                    setEmptyView(R.id.list_view, R.id.empty_view)
                } else {
                    appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.list_view)
                    val listIntent = Intent(context, HomeWidget0Service::class.java).apply {
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                        data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
                    }
                    setRemoteAdapter(R.id.list_view, listIntent)
                    setEmptyView(R.id.list_view, R.id.empty_view)
                }

                val intent = Intent(context, HomeWidget0Provider::class.java)
                intent.setAction(LAUNCH_JUMP_ACTION);
                intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId);
                intent.data = Uri.parse(intent.toUri(Intent.URI_INTENT_SCHEME))

                var flags = PendingIntent.FLAG_UPDATE_CURRENT
                if (Build.VERSION.SDK_INT >= 23) {
                    flags = flags or PendingIntent.FLAG_MUTABLE
                }

                var listViewPendingIntent = PendingIntent.getBroadcast(context, 0, intent, flags)
                setPendingIntentTemplate(R.id.list_view, listViewPendingIntent)

                // Pending intent to update counter on button click
                val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(context,
                    Uri.parse("bdwmViewer://obviewerupdatetop10"))
                setOnClickPendingIntent(R.id.bt_update, backgroundIntent)
            });

            appWidgetManager.updateAppWidget(widgetId, views)
        }
        super.onUpdate(context, appWidgetManager, appWidgetIds)
    }
}
