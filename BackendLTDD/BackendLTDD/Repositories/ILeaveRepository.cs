using AttendanceApi.Models;
using AttendanceApi.Models.Dtos;

namespace AttendanceApi.Repositories;

public interface ILeaveRepository
{
    Task<(LeaveDto? Result, string? Error)> CreateAsync(
        Employee emp, DateTime from, DateTime to, string type, string reason);

    /// status / code = null thì không lọc
    Task<List<LeaveDto>> GetAsync(string? status, string? code);

    /// Trả về lỗi, null = thành công. Chỉ đổi được đơn đang Pending
    Task<string?> SetStatusAsync(int id, string status);

    Task<LeaveDto?> GetByIdAsync(int id);
}