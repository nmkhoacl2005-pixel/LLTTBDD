using AttendanceApi.Models;

namespace AttendanceApi.Repositories;

public interface IAnnouncementRepository
{
    Task<List<Announcement>> GetAsync(int limit);
    Task<Announcement> AddAsync(string title, string body);
    Task<bool> DeleteAsync(int id);
}