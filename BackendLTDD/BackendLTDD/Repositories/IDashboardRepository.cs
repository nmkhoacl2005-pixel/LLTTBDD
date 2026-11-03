using AttendanceApi.Models.Dtos;

namespace AttendanceApi.Repositories;

public interface IDashboardRepository
{
    Task<DashboardDto> GetTodayAsync();
}