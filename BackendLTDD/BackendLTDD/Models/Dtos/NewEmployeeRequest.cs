namespace AttendanceApi.Models.Dtos;

public class NewEmployeeRequest
{
    public string Code { get; set; } = "";
    public string Name { get; set; } = "";
    public string Password { get; set; } = "";
}
