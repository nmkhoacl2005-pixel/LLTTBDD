using AttendanceApi.Filters;
using AttendanceApi.Models;
using AttendanceApi.Repositories;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Controllers;

[ApiController]
[Route("api/settings")]
public class SettingsApiController(ISettingRepository repo) : ControllerBase
{
    [HttpGet("schedule")]
    public async Task<IActionResult> Get() => Ok(await repo.GetScheduleAsync());

    [HttpPut("schedule")]
    public async Task<IActionResult> Put(WorkSchedule r)
    {
        if (r.CheckInMinutes is < 0 or > 1439 || r.CheckOutMinutes is < 0 or > 1439)
            return BadRequest(new { error = "Giờ không hợp lệ" });
        if (r.CheckOutMinutes <= r.CheckInMinutes)
            return BadRequest(new { error = "Giờ ra phải sau giờ vào" });
        await repo.SetScheduleAsync(r);
        return NoContent();
    }
}
