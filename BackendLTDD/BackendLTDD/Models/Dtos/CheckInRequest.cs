namespace AttendanceApi.Models.Dtos;

public class CheckInRequest
{
    public string Code { get; set; } = "";
    public string Token { get; set; } = "";
    public string DeviceId { get; set; } = "";
}
