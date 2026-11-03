using AttendanceApi.Repositories;
using ClosedXML.Excel;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Controllers;

[ApiController]
[Route("api/payroll")]
public class PayrollApiController(IPayrollRepository repo) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Get(int year, int month)
    {
        if (month is < 1 or > 12 || year is < 2000 or > 2100)
            return BadRequest(new { error = "Tháng không hợp lệ" });
        return Ok(await repo.GetAsync(year, month));
    }

    [HttpGet("export")]
    public async Task<IActionResult> Export(int year, int month)
    {
        if (month is < 1 or > 12 || year is < 2000 or > 2100)
            return BadRequest(new { error = "Tháng không hợp lệ" });
        var rows = await repo.GetAsync(year, month);

        using var wb = new XLWorkbook();
        var ws = wb.Worksheets.Add($"Luong {month:00}-{year}");
        string[] heads =
        {
            "Mã NV", "Họ tên", "Lương giờ (đ)", "Ngày công", "Giờ làm thường",
            "Giờ làm thêm (x1.5)", "Giờ cuối tuần (x2)", "Giờ làm ngày lễ (x3)",
            "Ngày lễ hưởng lương (giờ)", "Nghỉ có lương (ngày)", "Nghỉ có lương (giờ)",
            "Nghỉ không lương (ngày)", "Phép năm đã dùng", "Vắng không phép (ngày)",
            "Thiếu giờ ra (ngày)", "Tổng lương (đ)"
        };
        for (var c = 0; c < heads.Length; c++) ws.Cell(1, c + 1).Value = heads[c];

        var r = 2;
        foreach (var x in rows)
        {
            ws.Cell(r, 1).SetValue(x.Code);
            ws.Cell(r, 2).SetValue(x.Name);
            ws.Cell(r, 3).SetValue(x.HourlyRate);
            ws.Cell(r, 4).SetValue(x.WorkDays);
            ws.Cell(r, 5).SetValue(x.RegularHours);
            ws.Cell(r, 6).SetValue(x.OtHours);
            ws.Cell(r, 7).SetValue(x.WeekendHours);
            ws.Cell(r, 8).SetValue(x.HolidayWorkedHours);
            ws.Cell(r, 9).SetValue(x.HolidayPaidHours);
            ws.Cell(r, 10).SetValue(x.PaidLeaveDays);
            ws.Cell(r, 11).SetValue(x.PaidLeaveHours);
            ws.Cell(r, 12).SetValue(x.UnpaidLeaveDays);
            ws.Cell(r, 13).SetValue($"{x.AnnualLeaveUsed}/{x.AnnualLeaveQuota}");
            ws.Cell(r, 14).SetValue(x.AbsentDays);
            ws.Cell(r, 15).SetValue(x.MissingCheckOut);
            ws.Cell(r, 16).SetValue(x.Gross);
            r++;
        }

        ws.Cell(r, 2).SetValue("TỔNG");
        ws.Cell(r, 16).FormulaA1 = $"SUM(P2:P{r - 1})";
        ws.Range(r, 1, r, heads.Length).Style.Font.Bold = true;

        var head = ws.Range(1, 1, 1, heads.Length);
        head.Style.Font.Bold = true;
        head.Style.Fill.BackgroundColor = XLColor.FromHtml("#E8EAF6");
        head.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
        head.Style.Alignment.WrapText = true;
        ws.Column(3).Style.NumberFormat.Format = "#,##0";
        ws.Column(16).Style.NumberFormat.Format = "#,##0";
        ws.Range(1, 1, r, heads.Length).Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
        ws.Range(1, 1, r, heads.Length).Style.Border.InsideBorder = XLBorderStyleValues.Thin;
        ws.SheetView.FreezeRows(1);
        ws.Columns().AdjustToContents();

        using var ms = new MemoryStream();
        wb.SaveAs(ms);
        return File(ms.ToArray(),
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            $"BangLuong_{year}_{month:00}.xlsx");
    }
}