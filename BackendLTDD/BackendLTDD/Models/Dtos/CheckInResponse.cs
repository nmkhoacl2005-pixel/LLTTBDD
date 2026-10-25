namespace AttendanceApi.Models.Dtos;

public class CheckInResponse
{
    public string Code { get; set; } = "";
    public string Name { get; set; } = "";
    public DateTime Time { get; set; }
    public bool IsCheckIn { get; set; }
    public bool AlreadyDone { get; set; }
    public string Status { get; set; } = "";
}
