using AttendanceApi.Models;
using AttendanceApi.Models.Dtos;
using Microsoft.EntityFrameworkCore;

namespace AttendanceApi.Repositories;

public class LeaveRepository(ApplicationDbContext db) : ILeaveRepository
{
    private static readonly string[] Types = ["Phép năm", "Ốm", "Không lương"];

    private static LeaveDto ToDto(LeaveRequest l) => new()
    {
        Id = l.Id,
        Code = l.Code,
        Name = l.Name,
        FromDate = l.FromDate,
        ToDate = l.ToDate,
        Type = l.Type,
        Reason = l.Reason,
        Status = l.Status,
        CreatedAt = l.CreatedAt,
    };

    public async Task<(LeaveDto? Result, string? Error)> CreateAsync(
        Employee emp, DateTime from, DateTime to, string type, string reason)
    {
        from = from.Date;
        to = to.Date;
        if (to < from) return (null, "Ngày kết thúc phải từ ngày bắt đầu trở đi");
        if (from < DateTime.Today) return (null, "Không thể xin nghỉ cho ngày đã qua");
        if (!Types.Contains(type)) return (null, "Loại nghỉ không hợp lệ");

        var overlap = await db.LeaveRequests.AnyAsync(l =>
            l.Code == emp.Code && l.Status != "Rejected" && l.FromDate <= to && l.ToDate >= from);
        if (overlap) return (null, "Đã có đơn nghỉ trùng ngày này");

        var l = new LeaveRequest
        {
            Code = emp.Code,
            Name = emp.Name,
            FromDate = from,
            ToDate = to,
            Type = type,
            Reason = reason.Trim(),
            Status = "Pending",
            CreatedAt = DateTime.Now,
        };
        db.LeaveRequests.Add(l);
        await db.SaveChangesAsync();
        return (ToDto(l), null);
    }

    public async Task<List<LeaveDto>> GetAsync(string? status, string? code)
    {
        var q = db.LeaveRequests.AsQueryable();
        if (!string.IsNullOrEmpty(status)) q = q.Where(l => l.Status == status);
        if (!string.IsNullOrEmpty(code)) q = q.Where(l => l.Code == code);
        var rows = await q.OrderByDescending(l => l.CreatedAt).ToListAsync();
        return rows.Select(ToDto).ToList();
    }

    public async Task<string?> SetStatusAsync(int id, string status)
    {
        var l = await db.LeaveRequests.FindAsync(id);
        if (l == null) return "Không tìm thấy đơn";
        if (l.Status != "Pending") return "Đơn đã được xử lý";
        l.Status = status;
        await db.SaveChangesAsync();
        return null;
    }

    public async Task<LeaveDto?> GetByIdAsync(int id)
    {
        var l = await db.LeaveRequests.FindAsync(id);
        return l == null ? null : ToDto(l);
    }
}