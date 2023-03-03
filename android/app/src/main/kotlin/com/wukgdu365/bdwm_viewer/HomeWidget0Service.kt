package com.wukgdu365.bdwm_viewer

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
// import android.net.Uri
import android.os.Bundle
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin

class WidgetItem constructor(
    val title: String = "",
    val link: String = "",
    val count: String = "",
) {

}

class HomeWidget0Service : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return HomeWidget0Factory(this.applicationContext, intent)
    }
}

class HomeWidget0Factory(
    private val context: Context,
    intent: Intent
) : RemoteViewsService.RemoteViewsFactory {

    private var widgetItems: List<WidgetItem> = emptyList()
    private val appWidgetId: Int = intent.getIntExtra(
        AppWidgetManager.EXTRA_APPWIDGET_ID,
        AppWidgetManager.INVALID_APPWIDGET_ID
    )

    override fun onCreate() {
        updateData()
    }

    override fun getViewAt(position: Int): RemoteViews {
        // Construct a remote views item based on the widget item XML file
        // and set the text based on the position.
        return RemoteViews(context.packageName, R.layout.widget_item).apply {
            setTextViewText(R.id.widget_title, widgetItems[position].title);
            setTextViewText(R.id.widget_count, widgetItems[position].count);
            val fillInIntent = Intent().apply {
                Bundle().also { extras ->
                    extras.putString(EXTRA_ITEM, widgetItems[position].link)
                    putExtras(extras)
                }
            }
            // fillInIntent.setAction(LAUNCH_JUMP_ACTION)
            setOnClickFillInIntent(R.id.widget_item, fillInIntent)
        }
    }
    override fun getLoadingView(): RemoteViews? {
        return null
    }

    override fun getViewTypeCount(): Int {
        return 1
    }

    override fun getItemId(position: Int): Long {
        return widgetItems[position].hashCode().toLong()
    }

    override fun hasStableIds(): Boolean {
        return true
    }
    override fun onDestroy() {

    }

    fun updateData() {
        val widgetData = HomeWidgetPlugin.getData(context)
        val itemsString = widgetData.getString("_top10string", "");
        var tmpList = mutableListOf<WidgetItem>();
        if (!itemsString.isNullOrEmpty()) {
            val itemKind: Int = 3;
            val values = itemsString.split("\n".toRegex()).toTypedArray()
            val dataLength: Int = (values.size-1) / itemKind
            for (index in 0 until dataLength) {
                val title = values[index*itemKind]
                val link = values[index*itemKind+1]
                val commentCount = values[index*itemKind+2]
                tmpList.add(WidgetItem(title, link, commentCount))
            }
        }
        widgetItems = tmpList
    }

    override fun onDataSetChanged() {
        updateData()
    }

    override fun getCount(): Int {
        return widgetItems.size
    }
}
