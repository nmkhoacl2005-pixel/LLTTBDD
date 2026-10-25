using System.Text.RegularExpressions;
using AttendanceApi.Filters;
using AttendanceApi.Models.Dtos;
using AttendanceApi.Repositories;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Controllers;

[ApiController]
[Route("api/employees")]
public class EmployeesApiController(IEmployeeRepository repo) : ControllerBase
{
    private const int MinPasswordLength = 6;
    private static readonly Regex CodeRule = new(@"^\d{10,12}$");

    [HttpGet]
    public async Task<IActionResult> GetAll() => Ok(await repo.GetAllAsync());

    [HttpGet("{code}")]
    public async Task<IActionResult> Get(string code) =>
        await repo.GetByCodeAsync(code) is { } e ? Ok(e) : NotFound(new { error = "Không tìm thấy nhân viên" });

    [HttpPost]
    public async Task<IActionResult> Add(NewEmployeeRequest r)
    {
        var code = r.Code.Trim();
        var name = r.Name.Trim();
        if (!CodeRule.IsMatch(code)) return BadRequest(new { error = "Mã phải gồm 10–12 chữ số" });
        if (name.Length == 0) return BadRequest(new { error = "Vui lòng nhập tên nhân viên" });
        if (r.Password.Length < MinPasswordLength)
            return BadRequest(new { error = $"Mật khẩu tối thiểu {MinPasswordLength} ký tự" });

        return await repo.AddAsync(code, name, r.Password)
            ? Created($"/api/employees/{code}", new { code, name })
            : Conflict(new { error = "Mã đã tồn tại" });
    }

    [HttpPut("{code}")]
    public async Task<IActionResult> UpdateName(string code, UpdateNameRequest r)
    {
        var name = r.Name.Trim();
        if (name.Length == 0) return BadRequest(new { error = "Tên không được để trống" });
        return await repo.UpdateNameAsync(code, name) ? NoContent() : NotFound(new { error = "Không tìm thấy nhân viên" });
    }

    [HttpDelete("{code}")]
    public async Task<IActionResult> Delete(string code) =>
        await repo.DeleteAsync(code) ? NoContent() : NotFound(new { error = "Không tìm thấy nhân viên" });

    [HttpPost("{code}/password")]
    public async Task<IActionResult> SetPassword(string code, PasswordRequest r)
    {
        if (r.Password.Length < MinPasswordLength)
            return BadRequest(new { error = $"Mật khẩu tối thiểu {MinPasswordLength} ký tự" });
        return await repo.SetPasswordAsync(code, r.Password) ? NoContent() : NotFound(new { error = "Không tìm thấy nhân viên" });
    }

    [HttpPost("{code}/unbind")]
    public async Task<IActionResult> Unbind(string code) =>
        await repo.UnbindAsync(code) ? NoContent() : NotFound(new { error = "Không tìm thấy nhân viên" });
}
