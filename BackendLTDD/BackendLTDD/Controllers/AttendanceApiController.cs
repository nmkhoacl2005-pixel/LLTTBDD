using AttendanceApi.Filters;
using AttendanceApi.Models.Dtos;
using AttendanceApi.Repositories;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Controllers;

[ApiController]
[Route("api")]
public class AttendanceApiController(IAttendanceRepository repo) : ControllerBase
{
    /// Máy trạm chuyển tiếp gói chấm công nhận qua BLE
    [HttpPost("attendance/checkin")]
    public async Task<IActionResult> CheckIn(CheckInRequest r)
    {
        var res = await repo.CheckInAsync(r.Code, r.Token, r.DeviceId);
        return res == null ? Unauthorized(new { error = "Máy chưa được liên kết" }) : Ok(res);
    }

    [HttpGet("attendance/history")]
    public async Task<IActionResult> History(int limit = 50) =>
        Ok(await repo.GetHistoryAsync(Math.Clamp(limit, 1, 500)));

    [HttpGet("reports/monthly")]
    public async Task<IActionResult> Monthly(string code, int year, int month)
    {
        if (month is < 1 or > 12) return BadRequest(new { error = "Tháng không hợp lệ" });
        return Ok(await repo.GetMonthlyAsync(code, year, month));
    }
}
