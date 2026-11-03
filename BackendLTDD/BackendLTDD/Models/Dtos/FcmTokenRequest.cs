namespace AttendanceApi.Models.Dtos;

public class FcmTokenRequest : DeviceAuthRequest
{
    public string FcmToken { get; set; } = "";
}