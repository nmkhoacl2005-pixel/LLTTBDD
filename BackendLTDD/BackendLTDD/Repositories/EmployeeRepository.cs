using System.Security.Cryptography;
using System.Text;
using AttendanceApi.Models;
using AttendanceApi.Models.Dtos;
using Microsoft.EntityFrameworkCore;

namespace AttendanceApi.Repositories;

public class EmployeeRepository(ApplicationDbContext db) : IEmployeeRepository
{
    private static string HashToken(string token) =>
        Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(token))).ToLowerInvariant();

    private static string NewToken() =>
        Convert.ToHexString(RandomNumberGenerator.GetBytes(24)).ToLowerInvariant();

    private static string HashPassword(string password) => BCrypt.Net.BCrypt.HashPassword(password);

    public async Task<List<EmployeeDto>> GetAllAsync() =>
        await db.Employees.OrderBy(e => e.Id)
            .Select(e => new EmployeeDto { Code = e.Code, Name = e.Name, Bound = e.DeviceId != null })
            .ToListAsync();

    public async Task<EmployeeDto?> GetByCodeAsync(string code) =>
        await db.Employees.Where(e => e.Code == code)
            .Select(e => new EmployeeDto { Code = e.Code, Name = e.Name, Bound = e.DeviceId != null })
            .FirstOrDefaultAsync();

    public async Task<bool> AddAsync(string code, string name, string password)
    {
        if (await db.Employees.AnyAsync(e => e.Code == code)) return false;
        db.Employees.Add(new Employee { Code = code, Name = name, PassHash = HashPassword(password) });
        await db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> UpdateNameAsync(string code, string name)
    {
        var e = await db.Employees.FirstOrDefaultAsync(x => x.Code == code);
        if (e == null) return false;
        e.Name = name;
        await db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeleteAsync(string code)
    {
        var e = await db.Employees.FirstOrDefaultAsync(x => x.Code == code);
        if (e == null) return false;
        db.Employees.Remove(e);
        await db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> SetPasswordAsync(string code, string password)
    {
        var e = await db.Employees.FirstOrDefaultAsync(x => x.Code == code);
        if (e == null) return false;
        e.PassHash = HashPassword(password);
        e.TokenHash = null;
        e.DeviceId = null;
        await db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> UnbindAsync(string code)
    {
        var e = await db.Employees.FirstOrDefaultAsync(x => x.Code == code);
        if (e == null) return false;
        e.TokenHash = null;
        e.DeviceId = null;
        await db.SaveChangesAsync();
        return true;
    }

    public async Task<List<DuplicateDeviceDto>> GetDuplicateDevicesAsync()
    {
        var rows = await db.Employees.Where(e => e.DeviceId != null).OrderBy(e => e.Id).ToListAsync();
        return rows.GroupBy(e => e.DeviceId!)
            .Where(g => g.Count() > 1)
            .Select(g => new DuplicateDeviceDto
            {
                DeviceId = g.Key,
                Accounts = g.Select(e => new AccountDto { Code = e.Code, Name = e.Name }).ToList()
            })
            .ToList();
    }

    public async Task<(ActivateResponse? Result, string? Error)> ActivateAsync(
        string code, string password, string deviceId)
    {
        var e = await db.Employees.FirstOrDefaultAsync(x => x.Code == code);
        if (e == null) return (null, "Mã nhân viên không tồn tại");
        if (e.PassHash == null) return (null, "Chưa được đặt mật khẩu");
        if (e.DeviceId != null && e.DeviceId != deviceId) return (null, "Tài khoản đã liên kết máy khác");
        if (!BCrypt.Net.BCrypt.Verify(password, e.PassHash)) return (null, "Sai mật khẩu");

        var token = NewToken();
        e.TokenHash = HashToken(token);
        e.DeviceId = deviceId;
        await db.SaveChangesAsync();
        return (new ActivateResponse { Token = token, Name = e.Name }, null);
    }

    public async Task<Employee?> VerifyAsync(string code, string token, string deviceId)
    {
        var e = await db.Employees.FirstOrDefaultAsync(x => x.Code == code);
        if (e == null || e.TokenHash == null || e.DeviceId != deviceId) return null;
        var a = Encoding.UTF8.GetBytes(e.TokenHash);
        var b = Encoding.UTF8.GetBytes(HashToken(token));
        return CryptographicOperations.FixedTimeEquals(a, b) ? e : null;
    }

    public async Task SeedAsync()
    {
        if (await db.Employees.AnyAsync()) return;
        var seed = new (string Code, string Name)[]
        {
            ("2380601068", "Nguyễn Minh Khoa"),
            ("2380602431", "Nguyễn Phạm Tuân"),
            ("2380600564", "Đặng Thị Thái Hà"),
            ("2380600226", "Triệu Thị Mai Chi"),
        };
        foreach (var (code, name) in seed)
            db.Employees.Add(new Employee { Code = code, Name = name, PassHash = HashPassword("123456") });
        await db.SaveChangesAsync();
    }
}
