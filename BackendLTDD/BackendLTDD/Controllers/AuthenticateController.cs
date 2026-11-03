using AttendanceApi.Models.Dtos;
using AttendanceApi.Repositories;
using AttendanceApi.Services;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Controllers;

/// Điện thoại nhân viên gọi trực tiếp (không cần API key): đăng nhập/kích hoạt máy và xem báo cáo tháng
[ApiController]
[Route("api/device")]
public class AuthenticateController(
    IEmployeeRepository employees,
    IAttendanceRepository attendance,
    ILeaveRepository leaves,
    IPayrollRepository payroll,
    IAnnouncementRepository announcements,
    PushService push) : ControllerBase
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

    /// Nhân viên gửi đơn xin nghỉ
    [HttpPost("leave")]
    public async Task<IActionResult> CreateLeave(LeaveCreateRequest r)
    {
        var emp = await employees.VerifyAsync(r.Code, r.Token, r.DeviceId);
        if (emp == null) return Unauthorized(new { error = "Máy chưa được liên kết" });
        var (res, error) = await leaves.CreateAsync(emp, r.FromDate, r.ToDate, r.Type, r.Reason);
        return res == null ? BadRequest(new { error }) : Ok(res);
    }

    /// Nhân viên xem đơn nghỉ của mình
    [HttpPost("leaves")]
    public async Task<IActionResult> MyLeaves(DeviceAuthRequest r)
    {
        if (await employees.VerifyAsync(r.Code, r.Token, r.DeviceId) == null)
            return Unauthorized(new { error = "Máy chưa được liên kết" });
        return Ok(await leaves.GetAsync(null, r.Code));
    }

    /// Nhân viên xem phiếu lương tháng của mình
    [HttpPost("payslip")]
    public async Task<IActionResult> Payslip(ReportRequest r)
    {
        if (r.Month is < 1 or > 12) return BadRequest(new { error = "Tháng không hợp lệ" });
        if (await employees.VerifyAsync(r.Code, r.Token, r.DeviceId) == null)
            return Unauthorized(new { error = "Máy chưa được liên kết" });
        var rows = await payroll.GetAsync(r.Year, r.Month, r.Code);
        return rows.Count == 0 ? NotFound(new { error = "Không tìm thấy nhân viên" }) : Ok(rows[0]);
    }

    /// Máy nhân viên gửi token FCM để nhận thông báo đẩy
    [HttpPost("fcm")]
    public async Task<IActionResult> SaveFcm(FcmTokenRequest r)
    {
        if (await employees.VerifyAsync(r.Code, r.Token, r.DeviceId) == null)
            return Unauthorized(new { error = "Máy chưa được liên kết" });
        if (string.IsNullOrWhiteSpace(r.FcmToken)) return BadRequest(new { error = "Thiếu token" });
        await push.SaveTokenAsync(r.Code, r.FcmToken);
        return NoContent();
    }

    /// Nhân viên xem thông báo của quản lý
    [HttpPost("announcements")]
    public async Task<IActionResult> MyAnnouncements(DeviceAuthRequest r)
    {
        if (await employees.VerifyAsync(r.Code, r.Token, r.DeviceId) == null)
            return Unauthorized(new { error = "Máy chưa được liên kết" });
        return Ok(await announcements.GetAsync(50));
    }
}
