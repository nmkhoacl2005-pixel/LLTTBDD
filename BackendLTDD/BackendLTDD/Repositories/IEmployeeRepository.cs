using AttendanceApi.Models;
using AttendanceApi.Models.Dtos;

namespace AttendanceApi.Repositories;

public interface IEmployeeRepository
{
    Task<List<EmployeeDto>> GetAllAsync();
    Task<EmployeeDto?> GetByCodeAsync(string code);
    Task<bool> AddAsync(string code, string name, string password);
    Task<bool> UpdateNameAsync(string code, string name);
    Task<bool> DeleteAsync(string code);

    /// Đặt lại mật khẩu, đồng thời hủy liên kết máy cũ
    Task<bool> SetPasswordAsync(string code, string password);
    Task<bool> UnbindAsync(string code);
    Task<List<DuplicateDeviceDto>> GetDuplicateDevicesAsync();

    /// Đúng mật khẩu thì cấp token mới, gắn với ID máy
    Task<(ActivateResponse? Result, string? Error)> ActivateAsync(string code, string password, string deviceId);

    /// Token + ID máy hợp lệ thì trả về nhân viên, không thì null
    Task<Employee?> VerifyAsync(string code, string token, string deviceId);

    /// Nạp 4 nhân viên mẫu (mật khẩu 123456) nếu bảng còn trống
    Task SeedAsync();
}
