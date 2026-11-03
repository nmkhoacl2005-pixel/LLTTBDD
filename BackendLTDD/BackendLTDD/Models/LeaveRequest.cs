using Microsoft.EntityFrameworkCore;

namespace AttendanceApi.Models;

[Index(nameof(Code), nameof(FromDate))]
public class LeaveRequest
{
    public int Id { get; set; }
    public string Code { get; set; } = "";
    public string Name { get; set; } = "";
    public DateTime FromDate { get; set; }
    public DateTime ToDate { get; set; }
    public string Type { get; set; } = "";     // Phép năm | Ốm | Không lương
    public string Reason { get; set; } = "";
    public string Status { get; set; } = "Pending"; // Pending | Approved | Rejected
    public DateTime CreatedAt { get; set; }
}