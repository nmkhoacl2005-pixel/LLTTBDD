namespace AttendanceApi.Models.Dtos;

/// Tóm tắt 1 ngày công
public class DayDto
{
    public DateTime Date { get; set; }
    public DateTime CheckIn { get; set; }
    public DateTime? CheckOut { get; set; }
    public bool IsLate { get; set; }
    public bool IsEarlyLeave { get; set; }
}
