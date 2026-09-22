package com.josh.tracker;

import java.time.LocalDateTime;

/** Pure policy shared by the Android scheduler and JVM tests. */
public final class ReminderTimes {
    private ReminderTimes() {}
    public static boolean isQuiet(LocalDateTime time, int start, int end) {
        int minute = time.getHour() * 60 + time.getMinute();
        if (start == end) return false;
        return start < end ? minute >= start && minute < end : minute >= start || minute < end;
    }
    public static LocalDateTime afterQuiet(LocalDateTime time, int start, int end) {
        if (!isQuiet(time, start, end)) return time;
        LocalDateTime result = time.toLocalDate().atTime(end / 60, end % 60);
        return result.isAfter(time) ? result : result.plusDays(1);
    }
}
