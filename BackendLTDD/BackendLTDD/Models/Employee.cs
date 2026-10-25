using Microsoft.EntityFrameworkCore;

namespace AttendanceApi.Models;

[Index(nameof(Code), IsUnique = true)]
public class Employee
{
    public int Id { get; set; }
    public string Code { get; set; } = "";
    public string Name { get; set; } = "";
    public string? PassHash { get; set; }
    public string? TokenHash { get; set; }
    public string? DeviceId { get; set; }
}
