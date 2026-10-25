namespace AttendanceApi.Models.Dtos;

public class EmployeeDto
{
    public string Code { get; set; } = "";
    public string Name { get; set; } = "";
    /// true = đã liên kết điện thoại
    public bool Bound { get; set; }
}
