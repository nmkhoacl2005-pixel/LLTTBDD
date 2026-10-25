namespace AttendanceApi.Models.Dtos;

public class DuplicateDeviceDto
{
    public string DeviceId { get; set; } = "";
    public List<AccountDto> Accounts { get; set; } = new();
}

public class AccountDto
{
    public string Code { get; set; } = "";
    public string Name { get; set; } = "";
}
