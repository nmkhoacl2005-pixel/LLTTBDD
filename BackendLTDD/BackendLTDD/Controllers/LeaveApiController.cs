using AttendanceApi.Repositories;
using AttendanceApi.Services;
using Microsoft.AspNetCore.Mvc;
namespace AttendanceApi.Controllers;

/// Máy trạm (quản lý) xem và duyệt đơn nghỉ
[ApiController]
[Route("api/leaves")]
public class LeaveApiController(ILeaveRepository repo, PushService push) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Get(string? status, string? code) =>
        Ok(await repo.GetAsync(status, code));

    [HttpPost("{id:int}/approve")]
    public async Task<IActionResult> Approve(int id) => await Set(id, "Approved");

    [HttpPost("{id:int}/reject")]
    public async Task<IActionResult> Reject(int id) => await Set(id, "Rejected");

    private async Task<IActionResult> Set(int id, string status)
    {
        var error = await repo.SetStatusAsync(id, status);
        if (error != null) return BadRequest(new { error });

        var l = await repo.GetByIdAsync(id);
        if (l != null)
        {
            var ok = status == "Approved";
            await push.SendToEmployeeAsync(l.Code,
                ok ? "Đơn nghỉ đã được duyệt" : "Đơn nghỉ bị từ chối",
                $"{l.Type}: {l.FromDate:dd/MM} - {l.ToDate:dd/MM}", "leave");
        }
        return NoContent();
    }
}