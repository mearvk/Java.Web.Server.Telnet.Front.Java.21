package modules.Defined.source.protocol;

import java.time.*;
import java.time.format.DateTimeFormatter;

/**
 * ConnectionHoursManager — Controls when the backend accepts direct connections.
 *
 * The backend telnet server (port 49221) accepts connections only during defined hours.
 * Connections outside hours are rejected with a message.
 *
 * The web server (port 8080 /defined) may access its normal operations independently
 * and is always accessible regardless of hours.
 *
 * The AI server (port 49220) also operates independently for scheduled scans.
 *
 * Default hours:
 *   Weekdays (MON-FRI): 06:00 - 23:00 EST
 *   Weekends (SAT-SUN): 08:00 - 20:00 EST
 *
 * @author MEARVK LLC — Max Rupplin
 * @date July 2026
 */
public class ConnectionHoursManager
{
    private boolean enabled = true;
    private ZoneId timezone = ZoneId.of("America/New_York");

    // Weekday hours
    private LocalTime weekdayStart = LocalTime.of(6, 0);
    private LocalTime weekdayEnd = LocalTime.of(23, 0);

    // Weekend hours
    private LocalTime weekendStart = LocalTime.of(8, 0);
    private LocalTime weekendEnd = LocalTime.of(20, 0);

    private String outsideHoursMessage =
        "Defined™ backend is closed outside operating hours. Try again during business hours EST.";

    // Web server and AI server are independent — always accessible
    private boolean webServerIndependent = true;
    private boolean aiServerIndependent = true;

    public ConnectionHoursManager() {}

    /**
     * Check if the backend should accept direct connections right now.
     * Returns true if within operating hours.
     */
    public boolean isAcceptingConnections()
    {
        if (!enabled) return true; // if disabled, always accept

        LocalDateTime now = LocalDateTime.now(timezone);
        DayOfWeek day = now.getDayOfWeek();
        LocalTime time = now.toLocalTime();

        if (day == DayOfWeek.SATURDAY || day == DayOfWeek.SUNDAY)
        {
            return !time.isBefore(weekendStart) && time.isBefore(weekendEnd);
        }
        else
        {
            return !time.isBefore(weekdayStart) && time.isBefore(weekdayEnd);
        }
    }

    /**
     * Check if a specific port is always accessible (web server, AI server).
     */
    public boolean isAlwaysAccessible(int port)
    {
        if (port == 8080 && webServerIndependent) return true;
        if (port == 49220 && aiServerIndependent) return true;
        return false;
    }

    /**
     * Get the next window open time.
     */
    public String getNextOpenTime()
    {
        LocalDateTime now = LocalDateTime.now(timezone);
        DayOfWeek day = now.getDayOfWeek();
        LocalTime time = now.toLocalTime();

        LocalTime start;
        if (day == DayOfWeek.SATURDAY || day == DayOfWeek.SUNDAY)
        {
            start = weekendStart;
        }
        else
        {
            start = weekdayStart;
        }

        if (time.isBefore(start))
        {
            return start.format(DateTimeFormatter.ofPattern("HH:mm")) + " EST (today)";
        }
        else
        {
            // Next day
            DayOfWeek tomorrow = day.plus(1);
            LocalTime nextStart = (tomorrow == DayOfWeek.SATURDAY || tomorrow == DayOfWeek.SUNDAY)
                ? weekendStart : weekdayStart;
            return nextStart.format(DateTimeFormatter.ofPattern("HH:mm")) + " EST (tomorrow)";
        }
    }

    /**
     * Get current status for display.
     */
    public String getStatus()
    {
        if (!enabled) return "Connection hours: DISABLED (always open)";

        boolean accepting = isAcceptingConnections();
        LocalDateTime now = LocalDateTime.now(timezone);
        return String.format("Connection hours: %s | Now: %s EST | %s",
            accepting ? "OPEN" : "CLOSED",
            now.format(DateTimeFormatter.ofPattern("HH:mm")),
            accepting ? "Accepting connections" : "Next: " + getNextOpenTime());
    }

    public String getOutsideHoursMessage() { return outsideHoursMessage; }
    public void setOutsideHoursMessage(String msg) { this.outsideHoursMessage = msg; }
    public void setEnabled(boolean e) { this.enabled = e; }
    public boolean isEnabled() { return enabled; }
    public void setTimezone(ZoneId tz) { this.timezone = tz; }
    public void setWeekdayHours(LocalTime start, LocalTime end) { this.weekdayStart = start; this.weekdayEnd = end; }
    public void setWeekendHours(LocalTime start, LocalTime end) { this.weekendStart = start; this.weekendEnd = end; }
    public void setWebServerIndependent(boolean v) { this.webServerIndependent = v; }
    public void setAiServerIndependent(boolean v) { this.aiServerIndependent = v; }
}
