namespace AttendanceApi.Models.Dtos;

public class ReportRequest
{
    public string Code { get; set; } = "";
    public string Token { get; set; } = "";
    public string DeviceId { get; set; } = "";
    public int Year { get; set; }
    public int Month { get; set; }
}
