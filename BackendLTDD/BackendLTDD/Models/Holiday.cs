using Microsoft.EntityFrameworkCore;

namespace AttendanceApi.Models;

[Index(nameof(Date), IsUnique = true)]
public class Holiday
{
    public int Id { get; set; }
    public DateTime Date { get; set; }
    public string Name { get; set; } = "";
}