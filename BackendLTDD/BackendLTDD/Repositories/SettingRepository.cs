using AttendanceApi.Models;

namespace AttendanceApi.Repositories;

public class SettingRepository(ApplicationDbContext db) : ISettingRepository
{
    private const string InKey = "check_in_minutes";
    private const string OutKey = "check_out_minutes";

    public async Task<WorkSchedule> GetScheduleAsync()
    {
        var s = new WorkSchedule();
        var i = await db.Settings.FindAsync(InKey);
        var o = await db.Settings.FindAsync(OutKey);
        if (i != null && int.TryParse(i.Value, out var inMin)) s.CheckInMinutes = inMin;
        if (o != null && int.TryParse(o.Value, out var outMin)) s.CheckOutMinutes = outMin;
        return s;
    }

    public async Task SetScheduleAsync(WorkSchedule schedule)
    {
        await SetAsync(InKey, schedule.CheckInMinutes.ToString());
        await SetAsync(OutKey, schedule.CheckOutMinutes.ToString());
        await db.SaveChangesAsync();
    }

    private async Task SetAsync(string key, string value)
    {
        var s = await db.Settings.FindAsync(key);
        if (s == null) db.Settings.Add(new Setting { Key = key, Value = value });
        else s.Value = value;
    }
}
