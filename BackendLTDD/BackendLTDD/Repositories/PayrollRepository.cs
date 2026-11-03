using AttendanceApi.Models;
using AttendanceApi.Models.Dtos;
using Microsoft.EntityFrameworkCore;

namespace AttendanceApi.Repositories;

public class PayrollRepository(ApplicationDbContext db, ISettingRepository settings) : IPayrollRepository
{
    private const int BreakMinutes = 60;          // nghỉ trưa, trừ khi làm từ 5 giờ trở lên
    private const decimal OtRate = 1.5m;          // làm thêm sau giờ tan
    private const decimal WeekendRate = 2.0m;     // đi làm T7/CN
    private const decimal HolidayRate = 3.0m;     // đi làm ngày lễ
    private const int AnnualLeaveQuota = 12;      // ngày phép năm có lương / năm

    private static int MinutesOf(DateTime t) => t.Hour * 60 + t.Minute;
    private static int NetMinutes(int m) => m >= 300 ? m - BreakMinutes : m;
    private static decimal Hours(int minutes) => Math.Round(minutes / 60m, 2);

    public async Task<List<PayrollDto>> GetAsync(int year, int month, string? code = null)
    {
        var sch = await settings.GetScheduleAsync();
        var stdMinutes = NetMinutes(sch.CheckOutMinutes - sch.CheckInMinutes);
        var today = DateTime.Today;
        var monthStart = new DateTime(year, month, 1);
        var monthEnd = monthStart.AddMonths(1);
        var yearStart = new DateTime(year, 1, 1);
        var yearEnd = yearStart.AddYears(1);

        var employees = await db.Employees
    .Where(e => code == null || e.Code == code)
    .OrderBy(e => e.Id).ToListAsync();
        var holidays = (await db.Holidays.Where(h => h.Date >= yearStart && h.Date < yearEnd).ToListAsync())
            .Select(h => h.Date.Date).ToHashSet();
        var scans = await db.Attendances.Where(a => a.Time >= yearStart && a.Time < monthEnd).ToListAsync();
        var leaves = await db.LeaveRequests
            .Where(l => l.Status == "Approved" && l.FromDate < yearEnd && l.ToDate >= yearStart)
            .ToListAsync();

        bool IsWorkday(DateTime x) =>
            x.DayOfWeek is not (DayOfWeek.Saturday or DayOfWeek.Sunday) && !holidays.Contains(x);

        var result = new List<PayrollDto>();
        foreach (var emp in employees)
        {
            // ngày -> (giờ vào, giờ ra)
            var days = scans.Where(a => a.Code == emp.Code)
                .GroupBy(a => a.Time.Date)
                .ToDictionary(
                    g => g.Key,
                    g => (In: g.Min(a => a.Time), Out: g.Count() > 1 ? g.Max(a => a.Time) : (DateTime?)null));

            // ngày -> loại nghỉ (đơn đã duyệt)
            var leaveDays = new Dictionary<DateTime, string>();
            foreach (var l in leaves.Where(l => l.Code == emp.Code))
                for (var x = l.FromDate.Date; x <= l.ToDate.Date; x = x.AddDays(1))
                    leaveDays[x] = l.Type;

            // phép năm: 12 ngày đầu của năm có lương, ngày nào thực tế có đi làm thì không tính
            var annual = leaveDays
                .Where(p => p.Value == "Phép năm" && p.Key >= yearStart && p.Key < monthEnd
                            && IsWorkday(p.Key) && !days.ContainsKey(p.Key))
                .Select(p => p.Key).OrderBy(k => k).ToList();
            var withinQuota = annual.Take(AnnualLeaveQuota).ToHashSet();

            int regular = 0, ot = 0, weekend = 0, holidayWorked = 0, holidayPaid = 0, leavePaid = 0;
            int worked = 0, absent = 0, paidLeave = 0, unpaidLeave = 0, missingOut = 0;

            for (var day = monthStart; day < monthEnd && day <= today; day = day.AddDays(1))
            {
                var isHoliday = holidays.Contains(day);
                var isWeekend = day.DayOfWeek is DayOfWeek.Saturday or DayOfWeek.Sunday;

                if (isHoliday && !isWeekend) holidayPaid += stdMinutes;

                if (days.TryGetValue(day, out var sc))
                {
                    worked++;
                    if (sc.Out == null) { missingOut++; continue; }

                    var outTime = sc.Out.Value;
                    var span = (int)(outTime - sc.In).TotalMinutes;
                    if (isHoliday) holidayWorked += NetMinutes(span);
                    else if (isWeekend) weekend += NetMinutes(span);
                    else
                    {
                        var start = Math.Max(MinutesOf(sc.In), sch.CheckInMinutes);
                        var end = Math.Min(MinutesOf(outTime), sch.CheckOutMinutes);
                        regular += NetMinutes(Math.Max(0, end - start));
                        ot += Math.Max(0, MinutesOf(outTime) - sch.CheckOutMinutes);
                    }
                    continue;
                }

                if (isHoliday || isWeekend) continue;

                if (leaveDays.TryGetValue(day, out var type))
                {
                    var paid = type == "Ốm" || (type == "Phép năm" && withinQuota.Contains(day));
                    if (paid) { paidLeave++; leavePaid += stdMinutes; }
                    else unpaidLeave++;
                }
                else if (day < today) absent++;
            }

            var rate = emp.HourlyRate;
            var gross = rate * Hours(regular + holidayPaid + leavePaid)
                      + rate * OtRate * Hours(ot)
                      + rate * WeekendRate * Hours(weekend)
                      + rate * HolidayRate * Hours(holidayWorked);

            result.Add(new PayrollDto
            {
                Code = emp.Code,
                Name = emp.Name,
                HourlyRate = rate,
                WorkDays = worked,
                AbsentDays = absent,
                PaidLeaveDays = paidLeave,
                UnpaidLeaveDays = unpaidLeave,
                MissingCheckOut = missingOut,
                AnnualLeaveUsed = Math.Min(annual.Count, AnnualLeaveQuota),
                AnnualLeaveQuota = AnnualLeaveQuota,
                RegularHours = Hours(regular),
                OtHours = Hours(ot),
                WeekendHours = Hours(weekend),
                HolidayWorkedHours = Hours(holidayWorked),
                HolidayPaidHours = Hours(holidayPaid),
                PaidLeaveHours = Hours(leavePaid),
                Gross = Math.Round(gross, 0),
            });
        }
        return result;
    }
}