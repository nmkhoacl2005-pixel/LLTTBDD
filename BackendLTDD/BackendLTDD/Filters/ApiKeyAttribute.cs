using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace AttendanceApi.Filters;

/// Bắt buộc header X-Api-Key khớp "ApiKey" trong appsettings.json (dùng cho máy trạm / admin)
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class ApiKeyAttribute : Attribute, IAsyncActionFilter
{
    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        var key = context.HttpContext.RequestServices.GetRequiredService<IConfiguration>()["ApiKey"];
        var sent = context.HttpContext.Request.Headers["X-Api-Key"].ToString();
        if (string.IsNullOrEmpty(key) || sent != key)
        {
            context.Result = new ObjectResult(new { error = "Thiếu hoặc sai API key" }) { StatusCode = 401 };
            return;
        }
        await next();
    }
}
