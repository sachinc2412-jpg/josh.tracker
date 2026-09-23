package com.josh.tracker

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Color
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import java.time.LocalDate

/** Glanceable local snapshot. Opens Flutter to log; never edits account data in a receiver. */
class JoshWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        render(context,manager,ids)
    }
    companion object {
        fun refreshAll(c: Context) {
            val manager=AppWidgetManager.getInstance(c)
            render(c,manager,manager.getAppWidgetIds(ComponentName(c,JoshWidgetProvider::class.java)))
        }
        private fun open(c: Context,id: String): PendingIntent {
            val intent=Intent(c,MainActivity::class.java).setAction("OPEN_HABIT")
                .setData(Uri.parse("josh://widget/${Uri.encode(id)}")).putExtra("habit",id)
                .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            return PendingIntent.getActivity(c,0,intent,PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        }
        private fun render(c: Context,manager: AppWidgetManager,ids: IntArray) {
            if(ids.isEmpty())return
            val snapshot=ReminderEngine.snapshot(c)
            val signedIn=!snapshot.isNull("user") && snapshot.optString("user").isNotEmpty()
            val s=ReminderEngine.state(c)
            val p=s.optJSONObject("prefs")
            val today=LocalDate.now()
            val habits=if(signedIn)ReminderEngine.habits(s)else emptyList()
            val left=habits.filter{ReminderEngine.due(s,it,today)}
            val completed=habits.count{ReminderEngine.eligible(s,it,today) && ReminderEngine.done(s,it,today)}
            val count=left.size+completed
            val visible=habits.filter{ReminderEngine.eligible(s,it,today) && (ReminderEngine.due(s,it,today)||ReminderEngine.done(s,it,today))}
            val progress=if(visible.isEmpty())0 else (visible.sumOf{h ->
                val entry=s.optJSONObject("log")?.optJSONObject(today.toString())?.optJSONObject(h.optString("id"))
                val target=if(h.optString("kind")=="quantity")h.optDouble("target",1.0)else 1.0
                if(target<=0)0.0 else ((entry?.optDouble("value",0.0)?:0.0)/target).coerceIn(0.0,1.0)
            }/visible.size*100).toInt()
            val light=p?.optString("theme")=="light" || (p?.optString("theme")=="system" && (c.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) != Configuration.UI_MODE_NIGHT_YES)
            val foreground=Color.parseColor(if(light)"#19191C" else "#FFFFFF")
            val secondary=Color.parseColor(if(light)"#626269" else "#AAAAAF")
            val accent=Color.parseColor(when(p?.optString("accent")){"teal"->if(light)"#18786B" else "#66C9B5";"violet"->if(light)"#6850BF" else "#B09CFF";"rose"->if(light)"#AD4268" else "#F28EAE";else->if(light)"#0067CC" else "#0A84FF"})
            val v=RemoteViews(c.packageName,R.layout.josh_widget)
            v.setInt(R.id.widget_root,"setBackgroundResource",if(light)R.drawable.widget_light else R.drawable.widget_dark)
            v.setTextColor(R.id.widget_title,foreground)
            v.setTextColor(R.id.widget_summary,secondary)
            v.setTextColor(R.id.widget_footer,secondary)
            v.setTextViewText(R.id.widget_title,if(signedIn)"${p?.optString("name","Joshua") ?: "Joshua"}’s day" else "Josh Tracker")
            val rest=signedIn && ReminderEngine.rest(s,today)
            v.setTextViewText(R.id.widget_summary,when{!signedIn->"Open the app to sign in";rest->"A planned day of rest";count==0->"Room to breathe";else->"$completed of $count habits complete"})
            v.setProgressBar(R.id.widget_progress,100,progress,false)
            val rows=intArrayOf(R.id.widget_habit_1,R.id.widget_habit_2,R.id.widget_habit_3)
            for(i in rows.indices) {
                val h=left.getOrNull(i)
                v.setViewVisibility(rows[i],if(h==null)View.GONE else View.VISIBLE)
                if(h!=null){v.setTextViewText(rows[i],"○  ${h.optString("name")}");v.setTextColor(rows[i],accent);v.setOnClickPendingIntent(rows[i],open(c,h.optString("id")))}
            }
            v.setTextViewText(R.id.widget_footer,if(left.size>3)"+${left.size-3} more · Open tracker" else "Open tracker · updates after app sync")
            v.setOnClickPendingIntent(R.id.widget_root,open(c,"__dashboard"))
            v.setOnClickPendingIntent(R.id.widget_footer,open(c,"__dashboard"))
            for(id in ids)manager.updateAppWidget(id,v)
        }
    }
}
