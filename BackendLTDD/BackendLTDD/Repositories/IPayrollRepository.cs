using AttendanceApi.Models.Dtos;

namespace AttendanceApi.Repositories;

public interface IPayrollRepository
{
    /// code = null thì tính cho tất cả nhân viên
    Task<List<PayrollDto>> GetAsync(int year, int month, string? code = null);
}