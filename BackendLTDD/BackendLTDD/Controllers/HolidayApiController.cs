using AttendanceApi.Models.Dtos;
using AttendanceApi.Repositories;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Controllers;

[ApiController]
[Route("api/holidays")]
public class HolidayApiController(IHolidayRepository repo) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Get(int? year) => Ok(await repo.GetAsync(year));

    [HttpPost]
    public async Task<IActionResult> Post(HolidayRequest r)
    {
        if (string.IsNullOrWhiteSpace(r.Name))
            return BadRequest(new { error = "Tên ngày lễ không được để trống" });
        return await repo.AddAsync(r.Date, r.Name.Trim())
            ? Ok()
            : Conflict(new { error = "Ngày này đã có trong danh sách" });
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id) =>
        await repo.DeleteAsync(id) ? NoContent() : NotFound(new { error = "Không tìm thấy ngày lễ" });
}