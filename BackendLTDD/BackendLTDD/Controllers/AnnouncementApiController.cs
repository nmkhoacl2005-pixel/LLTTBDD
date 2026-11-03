using AttendanceApi.Models.Dtos;
using AttendanceApi.Repositories;
using AttendanceApi.Services;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Controllers;

/// Máy trạm (quản lý) viết thông báo cho nhân viên
[ApiController]
[Route("api/announcements")]
public class AnnouncementApiController(IAnnouncementRepository repo, PushService push) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Get(int limit = 50) => Ok(await repo.GetAsync(limit));

    [HttpPost]
    public async Task<IActionResult> Post(AnnouncementRequest r)
    {
        if (string.IsNullOrWhiteSpace(r.Title) || string.IsNullOrWhiteSpace(r.Body))
            return BadRequest(new { error = "Nhập đủ tiêu đề và nội dung" });
        var a = await repo.AddAsync(r.Title.Trim(), r.Body.Trim());
        await push.SendToAllAsync(a.Title, a.Body, "announcement");
        return Ok(a);
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id) =>
        await repo.DeleteAsync(id) ? NoContent() : NotFound(new { error = "Không tìm thấy thông báo" });
}