using AttendanceApi.Models;

namespace AttendanceApi.Repositories;

public interface IHolidayRepository
{
    Task<List<Holiday>> GetAsync(int? year);
    /// false = ngày này đã có
    Task<bool> AddAsync(DateTime date, string name);
    Task<bool> DeleteAsync(int id);
}