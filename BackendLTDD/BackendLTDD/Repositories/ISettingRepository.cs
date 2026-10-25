using AttendanceApi.Models;

namespace AttendanceApi.Repositories;

public interface ISettingRepository
{
    Task<WorkSchedule> GetScheduleAsync();
    Task SetScheduleAsync(WorkSchedule schedule);
}
