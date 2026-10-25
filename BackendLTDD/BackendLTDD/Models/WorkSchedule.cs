namespace AttendanceApi.Models;

/// Giờ làm việc chuẩn (tính bằng phút trong ngày). Vừa là model request/response của /settings/schedule.
public class WorkSchedule
{
    public int CheckInMinutes { get; set; } = 8 * 60;
    public int CheckOutMinutes { get; set; } = 17 * 60;

    private static int MinutesOf(DateTime t) => t.Hour * 60 + t.Minute;

    public bool IsLate(DateTime t) => MinutesOf(t) > CheckInMinutes;
    public bool IsEarlyLeave(DateTime t) => MinutesOf(t) < CheckOutMinutes;

    public string StatusOf(DateTime t, bool isCheckIn) =>
        isCheckIn
            ? (IsLate(t) ? "Đi trễ" : "Đúng giờ")
            : (IsEarlyLeave(t) ? "Về sớm" : "Ra đúng giờ");
}
