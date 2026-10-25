using AttendanceApi.Models.Dtos;
using AttendanceApi.Repositories;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Controllers;

/// Điện thoại nhân viên gọi trực tiếp (không cần API key): đăng nhập/kích hoạt máy và xem báo cáo tháng
[ApiController]
[Route("api/device")]
public class AuthenticateController(IEmployeeRepository employees, IAttendanceRepository attendance) : ControllerBase
{
    [HttpPost("activate")]
    public async Task<IActionResult> Activate(ActivateRequest r)
    {
        var (result, error) = await employees.ActivateAsync(r.Code, r.Password, r.DeviceId);
        return result == null ? BadRequest(new { error }) : Ok(result);
    }

    [HttpPost("report")]
    public async Task<IActionResult> Report(ReportRequest r)
    {
        if (r.Month is < 1 or > 12) return BadRequest(new { error = "Tháng không hợp lệ" });
        if (await employees.VerifyAsync(r.Code, r.Token, r.DeviceId) == null)
            return Unauthorized(new { error = "Máy chưa được liên kết" });
        return Ok(await attendance.GetMonthlyAsync(r.Code, r.Year, r.Month));
    }
}
