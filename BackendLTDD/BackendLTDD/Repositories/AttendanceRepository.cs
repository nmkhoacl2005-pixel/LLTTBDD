using AttendanceApi.Models;
using AttendanceApi.Models.Dtos;
using Microsoft.EntityFrameworkCore;

namespace AttendanceApi.Repositories;

public class AttendanceRepository(
    ApplicationDbContext db,
    IEmployeeRepository employees,
    ISettingRepository settings) : IAttendanceRepository
{
    /// Lần quét đầu trong ngày = VÀO, lần hai = RA. Đã RA thì không ghi thêm (AlreadyDone).
    /// Quét trùng trong 60 giây thì trả về lượt trước đó. Giờ lấy theo server.
    public async Task<CheckInResponse?> CheckInAsync(string code, string token, string deviceId)
    {
        var emp = await employees.VerifyAsync(code, token, deviceId);
        if (emp == null) return null;

        var now = DateTime.Now;
        var sch = await settings.GetScheduleAsync();
        var last = await db.Attendances.Where(a => a.Code == code)
            .OrderByDescending(a => a.Time).FirstOrDefaultAsync();

        Attendance rec;
        var done = false;
        if (last != null && (now - last.Time).TotalSeconds < 60)
        {
            rec = last;
        }
        else if (last != null && last.Time.Date == now.Date && !last.IsCheckIn)
        {
            rec = last;
            done = true;
        }
        else
        {
            var hasScanToday = last != null && last.Time.Date == now.Date;
            rec = new Attendance { Code = code, Name = emp.Name, Time = now, IsCheckIn = !hasScanToday };
            db.Attendances.Add(rec);
            await db.SaveChangesAsync();
        }

        return new CheckInResponse
        {
            Code = rec.Code,
            Name = emp.Name,
            Time = rec.Time,
            IsCheckIn = rec.IsCheckIn,
            AlreadyDone = done,
            Status = sch.StatusOf(rec.Time, rec.IsCheckIn),
        };
    }

    public async Task<List<AttendanceDto>> GetHistoryAsync(int limit)
    {
        var sch = await settings.GetScheduleAsync();
        var rows = await db.Attendances.OrderByDescending(a => a.Time).Take(limit).ToListAsync();
        return rows.Select(a => new AttendanceDto
        {
            Code = a.Code,
            Name = a.Name,
            Time = a.Time,
            IsCheckIn = a.IsCheckIn,
            Status = sch.StatusOf(a.Time, a.IsCheckIn),
        }).ToList();
    }

    /// Giờ vào = lần quét đầu, giờ ra = lần quét cuối trong ngày
    public async Task<List<DayDto>> GetMonthlyAsync(string code, int year, int month)
    {
        var start = new DateTime(year, month, 1);
        var end = start.AddMonths(1);
        var sch = await settings.GetScheduleAsync();
        var rows = await db.Attendances
            .Where(a => a.Code == code && a.Time >= start && a.Time < end)
            .OrderBy(a => a.Time).ToListAsync();

        var list = rows.GroupBy(a => a.Time.Date).OrderBy(g => g.Key).Select(g =>
        {
            var times = g.Select(a => a.Time).ToList();
            var cin = times.First();
            DateTime? cout = times.Count > 1 ? times.Last() : null;
            return new DayDto
            {
                Date = g.Key,
                CheckIn = cin,
                CheckOut = cout,
                IsLate = sch.IsLate(cin),
                IsEarlyLeave = cout != null && sch.IsEarlyLeave(cout.Value),
            };
        }).ToList();

        // Thêm các ngày không quét: ngày lễ, nghỉ phép, vắng
        var worked = list.Select(x => x.Date).ToHashSet();
        var holidays = await db.Holidays.Where(h => h.Date >= start && h.Date < end)
            .ToDictionaryAsync(h => h.Date.Date, h => h.Name);
        var leaves = await db.LeaveRequests
            .Where(l => l.Code == code && l.Status == "Approved" && l.FromDate < end && l.ToDate >= start)
            .ToListAsync();
        var firstScan = await db.Attendances.Where(a => a.Code == code)
            .MinAsync(a => (DateTime?)a.Time);
        var today = DateTime.Today;

        for (var day = start; day < end; day = day.AddDays(1))
        {
            if (worked.Contains(day)) continue;

            if (holidays.TryGetValue(day, out var holidayName))
            {
                list.Add(new DayDto { Date = day, Kind = "Holiday", Label = holidayName });
                continue;
            }
            if (day.DayOfWeek is DayOfWeek.Saturday or DayOfWeek.Sunday) continue;

            var leave = leaves.FirstOrDefault(l => l.FromDate.Date <= day && l.ToDate.Date >= day);
            if (leave != null)
            {
                list.Add(new DayDto
                {
                    Date = day,
                    Kind = "Leave",
                    Label = "Nghỉ " + leave.Type.ToLowerInvariant(),
                });
                continue;
            }
            if (day < today && firstScan != null && day >= firstScan.Value.Date)
                list.Add(new DayDto { Date = day, Kind = "Absent", Label = "Vắng không phép" });
        }

        return list.OrderBy(x => x.Date).ToList();
    }
}
