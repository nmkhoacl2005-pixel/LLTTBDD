using AttendanceApi.Models.Dtos;

namespace AttendanceApi.Repositories;

public interface IAttendanceRepository
{
    /// null = token/máy không hợp lệ
    Task<CheckInResponse?> CheckInAsync(string code, string token, string deviceId);
    Task<List<AttendanceDto>> GetHistoryAsync(int limit);
    Task<List<DayDto>> GetMonthlyAsync(string code, int year, int month);
}
