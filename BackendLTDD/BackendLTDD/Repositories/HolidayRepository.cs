using AttendanceApi.Models;
using Microsoft.EntityFrameworkCore;

namespace AttendanceApi.Repositories;

public class HolidayRepository(ApplicationDbContext db) : IHolidayRepository
{
    public async Task<List<Holiday>> GetAsync(int? year)
    {
        var q = db.Holidays.AsQueryable();
        if (year != null) q = q.Where(h => h.Date.Year == year);
        return await q.OrderBy(h => h.Date).ToListAsync();
    }

    public async Task<bool> AddAsync(DateTime date, string name)
    {
        date = date.Date;
        if (await db.Holidays.AnyAsync(h => h.Date == date)) return false;
        db.Holidays.Add(new Holiday { Date = date, Name = name });
        await db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var h = await db.Holidays.FindAsync(id);
        if (h == null) return false;
        db.Holidays.Remove(h);
        await db.SaveChangesAsync();
        return true;
    }
}