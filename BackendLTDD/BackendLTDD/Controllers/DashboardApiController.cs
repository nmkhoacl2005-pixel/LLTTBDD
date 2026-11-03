using AttendanceApi.Repositories;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Controllers;

[ApiController]
[Route("api/dashboard")]
public class DashboardApiController(IDashboardRepository repo) : ControllerBase
{
    [HttpGet("today")]
    public async Task<IActionResult> Today() => Ok(await repo.GetTodayAsync());
}