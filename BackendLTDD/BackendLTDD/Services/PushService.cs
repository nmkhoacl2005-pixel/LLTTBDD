using AttendanceApi.Models;
using DocumentFormat.OpenXml.Wordprocessing;
using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using Microsoft.AspNetCore.Builder.Extensions;
using Microsoft.EntityFrameworkCore;

namespace AttendanceApi.Services;

/// Gửi thông báo đẩy FCM. Thiếu file khóa Firebase thì bỏ qua, không làm lỗi API.
public class PushService(ApplicationDbContext db, IConfiguration cfg, ILogger<PushService> log)
{
    private static readonly object Lock = new();
    private static bool _ready;

    private bool Init()
    {
        lock (Lock)
        {
            if (_ready) return true;
            var path = cfg["Firebase:CredentialPath"];
            if (string.IsNullOrWhiteSpace(path) || !File.Exists(path))
            {
                log.LogWarning("Chưa có file khóa Firebase, bỏ qua gửi thông báo");
                return false;
            }
            FirebaseApp.Create(new AppOptions { Credential = GoogleCredential.FromFile(path) });
            _ready = true;
            return true;
        }
    }

    /// Lưu token FCM của máy; token này không được gắn với tài khoản khác
    public async Task SaveTokenAsync(string code, string fcmToken)
    {
        var others = await db.Employees.Where(e => e.FcmToken == fcmToken && e.Code != code).ToListAsync();
        foreach (var o in others) o.FcmToken = null;
        var me = await db.Employees.FirstOrDefaultAsync(e => e.Code == code);
        if (me != null) me.FcmToken = fcmToken;
        await db.SaveChangesAsync();
    }

    public Task SendToEmployeeAsync(string code, string title, string body, string type) =>
        SendAsync(db.Employees.Where(e => e.Code == code), title, body, type);

    public Task SendToAllAsync(string title, string body, string type) =>
        SendAsync(db.Employees, title, body, type);

    private async Task SendAsync(IQueryable<Employee> q, string title, string body, string type)
    {
        if (!Init()) return;
        var tokens = await q
            .Where(e => e.FcmToken != null && e.DeviceId != null) // máy đã hủy liên kết thì không gửi
            .Select(e => e.FcmToken!)
            .ToListAsync();
        if (tokens.Count == 0) return;
        try
        {
            var msgs = tokens.Select(t => new Message
            {
                Token = t,
                Notification = new Notification { Title = title, Body = body },
                Android = new AndroidConfig { Priority = Priority.High },
                Data = new Dictionary<string, string> { ["type"] = type },
            });
            foreach (var chunk in msgs.Chunk(500))
                await FirebaseMessaging.DefaultInstance.SendEachAsync(chunk);
        }
        catch (Exception ex)
        {
            log.LogWarning(ex, "Gửi FCM lỗi");
        }
    }
}