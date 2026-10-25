using AttendanceApi.Filters;
using AttendanceApi.Repositories;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Controllers;

[ApiController]
[Route("api/devices")]
public class DeviceApiController(IEmployeeRepository repo) : ControllerBase
{
    /// Các device ID đang gắn với từ 2 tài khoản trở lên
    [HttpGet("duplicates")]
    public async Task<IActionResult> Duplicates() => Ok(await repo.GetDuplicateDevicesAsync());
}
