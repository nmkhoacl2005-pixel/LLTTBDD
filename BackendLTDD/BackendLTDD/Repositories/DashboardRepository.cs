using AttendanceApi.Models;
using AttendanceApi.Models.Dtos;
using Microsoft.EntityFrameworkCore;

namespace AttendanceApi.Repositories;

public class DashboardRepository(
    ApplicationDbContext db,
    ISettingRepository settings,
    IEmployeeRepository employees) : IDashboardRepository
{
    public async Task<DashboardDto> GetTodayAsync()
    {
        var now = DateTime.Now;
        var today = now.Date;
        var yesterday = today.AddDays(-1);
        var sch = await settings.GetScheduleAsync();

        var holiday = await db.Holidays.FirstOrDefaultAsync(h => h.Date == today);
        var isWorkday = holiday == null
            && today.DayOfWeek is not (DayOfWeek.Saturday or DayOfWeek.Sunday);
        // Trước giờ vào chuẩn thì chưa ai bị tính là "chưa đến"
        var started = now.Hour * 60 + now.Minute >= sch.CheckInMinutes;

        var emps = await db.Employees.OrderBy(x => x.Id)
            .Select(x => new { x.Code, x.Name }).ToListAsync();
        var scans = await db.Attendances
            .Where(a => a.Time >= yesterday && a.Time < today.AddDays(1)).ToListAsync();
        var leaves = await db.LeaveRequests
            .Where(l => l.Status == "Approved" && l.FromDate <= today && l.ToDate >= today)
            .ToListAsync();

        var rows = new List<DashboardRowDto>();
        foreach (var emp in emps)
        {
            var mine = scans.Where(a => a.Code == emp.Code && a.Time >= today)
                .OrderBy(a => a.Time).ToList();
            if (mine.Count > 0)
            {
                var cin = mine.First().Time;
                DateTime? cout = mine.Count > 1 ? mine.Last().Time : null;
                rows.Add(new DashboardRowDto
                {
                    Code = emp.Code,
                    Name = emp.Name,
                    Status = cout == null ? "Working" : "Done",
                    CheckIn = cin,
                    CheckOut = cout,
                    IsLate = sch.IsLate(cin),
                });
                continue;
            }

            if (!isWorkday) continue;

            var leave = leaves.FirstOrDefault(l => l.Code == emp.Code);
            if (leave != null)
            {
                rows.Add(new DashboardRowDto
                {
                    Code = emp.Code,
                    Name = emp.Name,
                    Status = "Leave",
                    Label = "Nghỉ " + leave.Type.ToLowerInvariant(),
                });
                continue;
            }

            if (started)
                rows.Add(new DashboardRowDto
                {
                    Code = emp.Code,
                    Name = emp.Name,
                    Status = "NotYet",
                    Label = "Chưa đến",
                });
        }

        return new DashboardDto
        {
            Date = today,
            HolidayName = holiday?.Name,
            TotalEmployees = emps.Count,
            PendingLeaves = await db.LeaveRequests.CountAsync(l => l.Status == "Pending"),
            DuplicateDevices = (await employees.GetDuplicateDevicesAsync()).Count,
            // hôm qua chỉ quét đúng 1 lần = quên quét ra
            MissedCheckOutYesterday = emps.Count(emp =>
                scans.Count(a => a.Code == emp.Code && a.Time < today) == 1),
            Rows = rows,
        };
    }
}