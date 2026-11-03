namespace AttendanceApi.Models.Dtos;

public class DashboardDto
{
    public DateTime Date { get; set; }
    public string? HolidayName { get; set; }
    public int TotalEmployees { get; set; }
    public int PendingLeaves { get; set; }
    public int DuplicateDevices { get; set; }
    public int MissedCheckOutYesterday { get; set; }
    public List<DashboardRowDto> Rows { get; set; } = [];
}