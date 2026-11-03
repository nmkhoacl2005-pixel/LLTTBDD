namespace AttendanceApi.Models.Dtos;

public class LeaveCreateRequest : DeviceAuthRequest
{
    public DateTime FromDate { get; set; }
    public DateTime ToDate { get; set; }
    public string Type { get; set; } = "";
    public string Reason { get; set; } = "";
}