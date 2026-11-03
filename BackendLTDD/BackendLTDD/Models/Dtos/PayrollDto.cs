namespace AttendanceApi.Models.Dtos;

public class PayrollDto
{
    public string Code { get; set; } = "";
    public string Name { get; set; } = "";
    public decimal HourlyRate { get; set; }

    public int WorkDays { get; set; }          // số ngày có quét
    public int AbsentDays { get; set; }        // vắng không phép
    public int PaidLeaveDays { get; set; }
    public int UnpaidLeaveDays { get; set; }
    public int MissingCheckOut { get; set; }   // ngày quét vào nhưng không quét ra
    public int AnnualLeaveUsed { get; set; }   // phép năm đã dùng trong năm (đến hết tháng này)
    public int AnnualLeaveQuota { get; set; }

    public decimal RegularHours { get; set; }
    public decimal OtHours { get; set; }
    public decimal WeekendHours { get; set; }
    public decimal HolidayWorkedHours { get; set; }
    public decimal HolidayPaidHours { get; set; }
    public decimal PaidLeaveHours { get; set; }

    public decimal Gross { get; set; }
}