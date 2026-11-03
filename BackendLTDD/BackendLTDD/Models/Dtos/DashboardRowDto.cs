namespace AttendanceApi.Models.Dtos;

public class DashboardRowDto
{
    public string Code { get; set; } = "";
    public string Name { get; set; } = "";
    public string Status { get; set; } = ""; // Working | Done | Leave | NotYet
    public string Label { get; set; } = "";
    public DateTime? CheckIn { get; set; }
    public DateTime? CheckOut { get; set; }
    public bool IsLate { get; set; }
}