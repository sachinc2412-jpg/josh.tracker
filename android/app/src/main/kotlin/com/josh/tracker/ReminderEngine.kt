package com.josh.tracker

import android.Manifest
import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.temporal.TemporalAdjusters

object ReminderEngine {
    private const val CHANNEL = "josh_habits_v2"
    private const val SUMMARY = "__summary"
    private fun prefs(c: Context) = c.getSharedPreferences("josh_reminders_v2", Context.MODE_PRIVATE)
    fun snapshot(c: Context) = JSONObject(prefs(c).getString("snapshot", "{}") ?: "{}")
    fun state(c: Context) = snapshot(c).optJSONObject("state") ?: JSONObject()
    private fun settings(c: Context) = state(c).optJSONObject("prefs") ?: JSONObject()
    private fun enabled(c: Context): Boolean = !snapshot(c).isNull("user") && snapshot(c).optString("user").isNotEmpty() && settings(c).optBoolean("reminders")
    fun habits(s: JSONObject): List<JSONObject> {
        val map = s.optJSONObject("habits") ?: return emptyList()
        return map.keys().asSequence().mapNotNull { map.optJSONObject(it) }.filter { it.isNull("archived") }.toList()
    }
    fun allowed(c: Context): Boolean {
        if (Build.VERSION.SDK_INT >= 33 && c.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) return false
        val manager = c.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= 24 && !manager.areNotificationsEnabled()) return false
        if (Build.VERSION.SDK_INT >= 26 && manager.getNotificationChannel(CHANNEL)?.importance == NotificationManager.IMPORTANCE_NONE) return false
        return true
    }
    fun createChannel(c: Context) {
        if (Build.VERSION.SDK_INT >= 26) {
            val channel = NotificationChannel(CHANNEL, "Habit reminders", NotificationManager.IMPORTANCE_DEFAULT)
            channel.description = "Gentle prompts for unfinished habits and your daily check-in"
            (c.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).createNotificationChannel(channel)
        }
    }
    fun configure(c: Context, raw: String) {
        val next = JSONObject(raw)
        val previous = state(c)
        val oldUser = snapshot(c).optString("user")
        val newUser = next.optString("user")
        if (!prefs(c).edit().putString("snapshot", raw).commit()) error("Could not save reminders")
        if (oldUser != newUser || !enabled(c)) {
            prefs(c).edit().remove("snoozes").apply()
            (c.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).cancelAll()
        }
        val manager = c.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val latest = state(c)
        val current = habits(latest)
        for (h in habits(previous)) {
            val replacement = current.firstOrNull { it.optString("id") == h.optString("id") }
            if (replacement == null || !due(latest,replacement,LocalDate.now())) manager.cancel(h.optString("id"),1)
        }
        manager.cancel(SUMMARY,1)
        reschedule(c)
    }
    private fun pending(c: Context, key: String, action: String = "ALARM", millis: Long = 0): PendingIntent {
        val intent = Intent(c, ReminderReceiver::class.java).setAction(action)
            .setData(Uri.parse("josh://reminder/${Uri.encode(key)}"))
            .putExtra("key", key).putExtra("scheduled", millis)
        return PendingIntent.getBroadcast(c, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }
    private fun quiet(time: LocalDateTime, p: JSONObject): Boolean =
        ReminderTimes.isQuiet(time, p.optInt("quietStart",1320), p.optInt("quietEnd",480))
    private fun afterQuiet(time: LocalDateTime, p: JSONObject): LocalDateTime =
        ReminderTimes.afterQuiet(time, p.optInt("quietStart",1320), p.optInt("quietEnd",480))
    fun done(s: JSONObject, h: JSONObject, day: LocalDate): Boolean {
        val entry=s.optJSONObject("log")?.optJSONObject(day.toString())?.optJSONObject(h.optString("id")) ?: return false
        val target=entry.optDouble("target",if(h.optString("kind")=="quantity")h.optDouble("target",1.0)else 1.0)
        return entry.optDouble("value",0.0)>=target && target>0
    }
    private fun weekDone(s: JSONObject,h: JSONObject,day: LocalDate): Int {
        var d=day.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
        var count=0
        while(!d.isAfter(day)){ if(eligible(s,h,d) && done(s,h,d))count++; d=d.plusDays(1) }
        return count
    }
    fun rest(s: JSONObject,day: LocalDate): Boolean {
        val override=s.optJSONObject("restDays")?.optJSONObject(day.toString())
        if(override?.has("rest")==true)return override.optBoolean("rest")
        val p=s.optJSONObject("prefs") ?: JSONObject()
        val versions=p.optJSONArray("restVersions") ?: JSONArray()
        var days=JSONArray()
        if(versions.length()==0 && day.toString()>=p.optString("restFrom","1970-01-01")) days=p.optJSONArray("restWeekdays") ?: JSONArray()
        for(i in 0 until versions.length()) {
            val v=versions.getJSONObject(i)
            if(day.toString()>=v.optString("from"))days=v.optJSONArray("days") ?: JSONArray()
        }
        return (0 until days.length()).any{days.optInt(it)==day.dayOfWeek.value}
    }
    private fun on(h: JSONObject,day: LocalDate): JSONObject {
        val result=JSONObject(h.toString())
        val versions=h.optJSONArray("versions") ?: JSONArray()
        for(i in 0 until versions.length()) {
            val v=versions.getJSONObject(i)
            if(day.toString()>=v.optString("from")) {
                for(key in v.keys()) {
                    if(key!="pauses" && key!="archived" && key!="id")result.put(key,v.get(key))
                }
            }
        }
        return result
    }
    fun eligible(s: JSONObject,h: JSONObject,day: LocalDate): Boolean {
        val current=on(h,day)
        if(!h.isNull("archived") && day.toString()>=h.optString("archived"))return false
        if(day.toString()<h.optString("created","1970-01-01") || rest(s,day))return false
        val pauses=h.optJSONArray("pauses") ?: JSONArray()
        for(i in 0 until pauses.length()) {
            val p=pauses.getJSONObject(i)
            if(day.toString()>=p.optString("start") && day.toString()<=p.optString("end"))return false
        }
        if(current.optString("kind")=="weekly")return true
        val days=current.optJSONArray("weekdays") ?: JSONArray("[1,2,3,4,5,6,7]")
        return (0 until days.length()).any{days.optInt(it)==day.dayOfWeek.value}
    }
    private fun target(s: JSONObject,h: JSONObject,day: LocalDate): Int {
        val start=day.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
        return minOf(h.optInt("weeklyTarget",4),(0L..6L).count{eligible(s,h,start.plusDays(it))})
    }
    fun due(s: JSONObject,h: JSONObject,day: LocalDate): Boolean =
        eligible(s,h,day) && !done(s,h,day) && (h.optString("kind")!="weekly" || weekDone(s,h,day)<target(s,h,day))
    private fun schedule(c: Context,key: String,time: LocalDateTime) {
        val millis=time.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli()
        val am=c.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP,millis,pending(c,key,millis=millis))
    }
    fun reschedule(c: Context, force: Boolean = false) {
        createChannel(c)
        JoshWidgetProvider.refreshAll(c)
        val am=c.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val old=JSONArray(prefs(c).getString("scheduledKeys","[]") ?: "[]")
        val previousTimes=JSONObject(prefs(c).getString("alarmTimes","{}") ?: "{}")
        val nextTimes=JSONObject()
        val keys=JSONArray()
        fun millis(time: LocalDateTime) = time.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli()
        fun keepOrSchedule(key: String,time: LocalDateTime) {
            val whenMs=millis(time)
            nextTimes.put(key,whenMs); keys.put(key)
            if(force || previousTimes.optLong(key,-1)!=whenMs) schedule(c,key,time)
        }
        fun stillPending(key: String,time: LocalDateTime,now: LocalDateTime): Boolean =
            time.toLocalDate()==now.toLocalDate() && previousTimes.optLong(key,-1)==millis(time)
        if(enabled(c)) {
            val s=state(c); val p=settings(c); val now=LocalDateTime.now()
            val list=habits(s)
            for(h in list) {
                val id=h.optString("id")
                if(!due(s,h,now.toLocalDate())) (c.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).cancel(id,1)
                if(!h.optBoolean("remind"))continue
                val minutes=h.optInt("reminder",1080).coerceIn(0,1439)
                for(offset in 0L..8L) {
                    val day=now.toLocalDate().plusDays(offset)
                    // Habit notifications inside quiet hours are skipped, never shifted to the next day with stale text.
                    val time=day.atTime(minutes/60,minutes%60)
                    if((time.isAfter(now) || stillPending(id,time,now)) && !quiet(time,p) && due(s,h,day)) {
                        keepOrSchedule(id,time); break
                    }
                }
            }
            if(list.any{due(s,it,now.toLocalDate())}.not()) (c.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).cancel(SUMMARY,1)
            val summary=p.optInt("summaryTime",1200).coerceIn(0,1439)
            for(offset in 0L..8L) {
                val t=now.toLocalDate().plusDays(offset).atTime(summary/60,summary%60)
                if((t.isAfter(now) || stillPending(SUMMARY,t,now)) && !quiet(t,p)) {keepOrSchedule(SUMMARY,t);break}
            }
            val snoozes=JSONObject(prefs(c).getString("snoozes","{}") ?: "{}")
            val ids=snoozes.keys().asSequence().toList()
            for(id in ids) {
                val key="snooze:$id"
                val h=list.firstOrNull{it.optString("id")==id}
                val t=LocalDateTime.ofInstant(java.time.Instant.ofEpochMilli(snoozes.optLong(id)),ZoneId.systemDefault())
                if(h!=null && (t.isAfter(now) || stillPending(key,t,now)) && due(s,h,t.toLocalDate())) {
                    keepOrSchedule(key,afterQuiet(t,p))
                }else snoozes.remove(id)
            }
            prefs(c).edit().putString("snoozes",snoozes.toString()).apply()
        }
        for(i in 0 until old.length()) {
            val key=old.getString(i)
            if(!nextTimes.has(key)) am.cancel(pending(c,key))
        }
        prefs(c).edit().putString("scheduledKeys",keys.toString()).putString("alarmTimes",nextTimes.toString()).apply()
    }
    fun snooze(c: Context,id: String): Boolean {
        if(!enabled(c)||!allowed(c))return false
        val s=state(c)
        val h=habits(s).firstOrNull{it.optString("id")==id} ?: return false
        if(!due(s,h,LocalDate.now()))return false
        val t=afterQuiet(LocalDateTime.now().plusMinutes(30),settings(c))
        val snoozes=JSONObject(prefs(c).getString("snoozes","{}") ?: "{}")
        snoozes.put(id,t.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli())
        prefs(c).edit().putString("snoozes",snoozes.toString()).apply()
        (c.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).cancel(id,1)
        reschedule(c)
        return true
    }
    fun fire(c: Context,key: String,scheduled: Long) {
        val alarmTimes=JSONObject(prefs(c).getString("alarmTimes","{}") ?: "{}")
        if (alarmTimes.optLong(key,-1) != scheduled) return // obsolete alarm after a settings change
        alarmTimes.remove(key)
        prefs(c).edit().putString("alarmTimes",alarmTimes.toString()).apply()
        val now=LocalDateTime.now()
        val date=java.time.Instant.ofEpochMilli(scheduled).atZone(ZoneId.systemDefault()).toLocalDate()
        if(enabled(c) && allowed(c) && !quiet(now,settings(c)) && date==now.toLocalDate()) {
            val s=state(c)
            val name=settings(c).optString("name","Joshua")
            if(key==SUMMARY) {
                val left=habits(s).filter{due(s,it,now.toLocalDate())}
                if(left.isNotEmpty())notify(c,SUMMARY,"A small moment for you, $name","${left.size} habits left: ${left.take(3).joinToString(", "){it.optString("name")}}. One step is enough.",false)
            }else {
                val id=key.removePrefix("snooze:")
                val h=habits(s).firstOrNull{it.optString("id")==id}
                if(h!=null && due(s,h,now.toLocalDate())) {
                    val entry=s.optJSONObject("log")?.optJSONObject(date.toString())?.optJSONObject(id)
                    val text=when(h.optString("kind")) {
                        "quantity" -> {
                            val remaining=(h.optDouble("target",1.0)-(entry?.optDouble("value",0.0)?:0.0)).coerceAtLeast(0.0)
                            "${format(remaining)} ${h.optString("unit","minutes")} left today. Make a little space for yourself."
                        }
                        "weekly" -> "${weekDone(s,h,date)} of ${target(s,h,date)} days this week. Ready for your next check-in?"
                        else -> "Still on your list today. One small step, at your own pace."
                    }
                    val body=if(settings(c).optString("tone")=="direct")"Still due today. Open your tracker to log progress." else text
                    notify(c,id,h.optString("name"),body,true)
                }
                if(key.startsWith("snooze:")) {
                    val sn=JSONObject(prefs(c).getString("snoozes","{}") ?: "{}")
                    sn.remove(id);prefs(c).edit().putString("snoozes",sn.toString()).apply()
                }
            }
        }
        reschedule(c)
    }
    private fun format(v: Double) = if(v%1.0==0.0)v.toInt().toString()else String.format(java.util.Locale.US,"%.1f",v)
    @Suppress("DEPRECATION")
    fun notify(c: Context,id: String,title: String,body: String,canSnooze: Boolean) {
        if(!allowed(c))return
        createChannel(c)
        val intent=Intent(c,MainActivity::class.java).setAction("OPEN_HABIT").setData(Uri.parse("josh://open/${Uri.encode(id)}"))
            .putExtra("habit",id).addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val open=PendingIntent.getActivity(c,0,intent,PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder=if(Build.VERSION.SDK_INT>=26)Notification.Builder(c,CHANNEL)else Notification.Builder(c)
        builder.setSmallIcon(R.drawable.ic_notification).setContentTitle(title).setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body)).setContentIntent(open).setAutoCancel(true)
            .setVisibility(Notification.VISIBILITY_PRIVATE).setCategory(Notification.CATEGORY_REMINDER)
        if(canSnooze)builder.addAction(Notification.Action.Builder(Icon.createWithResource(c,R.drawable.ic_notification),"Snooze 30 min",pending(c,id,"SNOOZE")).build())
        (c.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).notify(id,1,builder.build())
    }
}

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context,intent: Intent) {
        try {
            val id=intent.getStringExtra("key") ?: return
            if(intent.action=="SNOOZE")ReminderEngine.snooze(context,id)
            else ReminderEngine.fire(context,id,intent.getLongExtra("scheduled",System.currentTimeMillis()))
        }catch(e: Exception){Log.w("JoshReminders","Reminder could not be handled",e)}
    }
}
class ReminderBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context,intent: Intent) {
        try {ReminderEngine.reschedule(context, true)}catch(e: Exception){Log.w("JoshReminders","Could not restore reminders",e)}
    }
}
