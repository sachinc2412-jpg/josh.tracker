import com.josh.tracker.ReminderTimes;
import java.time.LocalDateTime;
import java.time.ZoneId;

public class ReminderTimesTest {
    static LocalDateTime at(String s) { return LocalDateTime.parse(s); }
    static void check(boolean value, String name) { if (!value) throw new AssertionError(name); }
    public static void main(String[] args) {
        check(ReminderTimes.isQuiet(at("2026-09-22T22:00"),1320,480), "quiet-start inclusive");
        check(ReminderTimes.isQuiet(at("2026-09-23T07:59"),1320,480), "overnight interval");
        check(!ReminderTimes.isQuiet(at("2026-09-23T08:00"),1320,480), "quiet-end exclusive");
        check(ReminderTimes.afterQuiet(at("2026-09-22T23:30"),1320,480).equals(at("2026-09-23T08:00")), "snooze crosses midnight");
        check(ReminderTimes.afterQuiet(at("2026-09-22T06:30"),1320,480).equals(at("2026-09-22T08:00")), "early-morning snooze");
        check(ReminderTimes.afterQuiet(at("2026-09-22T13:15"),720,840).equals(at("2026-09-22T14:00")), "daytime quiet interval");
        check(!ReminderTimes.isQuiet(at("2026-09-22T13:15"),720,720), "equal endpoints disable quiet hours");
        check(ReminderTimes.afterQuiet(at("2026-09-22T19:15"),1320,480).equals(at("2026-09-22T19:15")), "outside quiet hours unchanged");
        var spring = ReminderTimes.afterQuiet(at("2026-03-29T01:30"),1320,480).atZone(ZoneId.of("Europe/London"));
        check(spring.getHour()==8 && spring.getOffset().getTotalSeconds()==3600, "DST uses local wall clock");
        var autumn = ReminderTimes.afterQuiet(at("2026-10-25T01:30"),1320,480).atZone(ZoneId.of("Europe/London"));
        check(autumn.getHour()==8 && autumn.getOffset().getTotalSeconds()==0, "fall-back uses local wall clock");
        System.out.println("PASS: 10 production reminder-time checks");
    }
}
