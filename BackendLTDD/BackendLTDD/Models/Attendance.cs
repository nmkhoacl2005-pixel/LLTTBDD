using Microsoft.EntityFrameworkCore;

namespace AttendanceApi.Models;

[Index(nameof(Code), nameof(Time))]
public class Attendance
{
    public int Id { get; set; }
    public string Code { get; set; } = "";
    public string Name { get; set; } = "";
    public DateTime Time { get; set; }
    public bool IsCheckIn { get; set; }
}
