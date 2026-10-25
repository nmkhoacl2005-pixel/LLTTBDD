namespace AttendanceApi.Models.Dtos;

public class ActivateRequest
{
    public string Code { get; set; } = "";
    public string Password { get; set; } = "";
    public string DeviceId { get; set; } = "";
}
