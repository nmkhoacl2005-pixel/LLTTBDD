using AttendanceApi.Models;
using Microsoft.EntityFrameworkCore;

namespace AttendanceApi.Repositories;

public class AnnouncementRepository(ApplicationDbContext db) : IAnnouncementRepository
{
    public Task<List<Announcement>> GetAsync(int limit) =>
        db.Announcements.OrderByDescending(a => a.CreatedAt).Take(limit).ToListAsync();

    public async Task<Announcement> AddAsync(string title, string body)
    {
        var a = new Announcement { Title = title, Body = body, CreatedAt = DateTime.Now };
        db.Announcements.Add(a);
        await db.SaveChangesAsync();
        return a;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var a = await db.Announcements.FindAsync(id);
        if (a == null) return false;
        db.Announcements.Remove(a);
        await db.SaveChangesAsync();
        return true;
    }
}