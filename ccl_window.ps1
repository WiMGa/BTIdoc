# Запоминает положение и размер окна CCL между запусками.
# Запускается из O55.cmd через `start /b` и делит консоль с claude, поэтому
# окно Windows Terminal находит как владельца псевдоконсоли.
# Сначала восстанавливает сохранённое положение окна. Потом раз в секунду пишет
# текущее в winpos\<Label>.txt. Завершается вместе с родительским cmd.
# Если окно закрыли крестиком, сохранённое отстаёт не больше чем на секунду.
param([string]$Label = 'O55')

Add-Type @'
using System; using System.Runtime.InteropServices; using System.Text;
public static class CclWin {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
  [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
  [StructLayout(LayoutKind.Sequential)] public struct WINDOWPLACEMENT {
    public int length, flags, showCmd; public POINT ptMin, ptMax; public RECT rc; }
  [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
  [DllImport("kernel32.dll")] public static extern bool SetConsoleCtrlHandler(IntPtr h, bool add);
  [DllImport("user32.dll")] public static extern IntPtr GetWindow(IntPtr h, uint cmd);
  [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool GetWindowPlacement(IntPtr h, ref WINDOWPLACEMENT wp);
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int w, int hh, uint f);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
  [DllImport("user32.dll")] public static extern IntPtr MonitorFromRect(ref RECT r, uint flags);
  [DllImport("user32.dll")] public static extern IntPtr SetProcessDpiAwarenessContext(IntPtr ctx);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr h, StringBuilder s, int n);
  public static string Cls(IntPtr h) { var s = new StringBuilder(256); GetClassName(h, s, 256); return s.ToString(); }
}
'@

[void][CclWin]::SetProcessDpiAwarenessContext([IntPtr](-4))   # per-monitor v2: координаты без масштабирования
[void][CclWin]::SetConsoleCtrlHandler([IntPtr]::Zero, $true)   # Ctrl+C в окне не должен снимать наблюдателя

$file = Join-Path $PSScriptRoot "winpos\$Label.txt"
$log = Join-Path $PSScriptRoot "winpos\$Label.log"
function Log($m) { Add-Content -Path $log -Value ('{0:dd.MM.yyyy HH:mm:ss.fff} {1}' -f (Get-Date), $m) -Encoding UTF8 }
Log "start pid=$PID"
$parent = Get-Process -Id (Get-CimInstance Win32_Process -Filter "ProcessId=$PID").ParentProcessId

# Окно WT: владелец псевдоконсоли. Под conhost — сама консоль.
$hwnd = [IntPtr]::Zero
for ($i = 0; $i -lt 40 -and $hwnd -eq [IntPtr]::Zero; $i++) {
    $con = [CclWin]::GetConsoleWindow()
    $own = [CclWin]::GetWindow($con, 4)   # GW_OWNER
    if ($own -ne [IntPtr]::Zero -and [CclWin]::Cls($own) -eq 'CASCADIA_HOSTING_WINDOW_CLASS') { $hwnd = $own }
    elseif ($con -ne [IntPtr]::Zero -and [CclWin]::Cls($con) -eq 'ConsoleWindowClass') { $hwnd = $con }
    else { Start-Sleep -Milliseconds 250 }
}
if ($hwnd -eq [IntPtr]::Zero) { Log 'window not found, exit'; exit }
Log "hwnd=$hwnd class=$([CclWin]::Cls($hwnd))"

function Get-Wp { $wp = New-Object CclWin+WINDOWPLACEMENT; $wp.length = [Runtime.InteropServices.Marshal]::SizeOf($wp); [void][CclWin]::GetWindowPlacement($hwnd, [ref]$wp); $wp }
function Fmt($wp) { '{0} {1} {2} {3} {4}' -f $wp.showCmd, $wp.rc.L, $wp.rc.T, $wp.rc.R, $wp.rc.B }

# Восстановление: только если прямоугольник попадает на подключённый монитор.
$saved = $null
if (Test-Path $file) {
    $v = (Get-Content $file -TotalCount 1) -split ' ' | ForEach-Object { [int]$_ }
    if ($v.Count -eq 5 -and $v[3] -gt $v[1] + 200 -and $v[4] -gt $v[2] + 150) {
        $rc = New-Object CclWin+RECT
        $rc.L = $v[1]; $rc.T = $v[2]; $rc.R = $v[3]; $rc.B = $v[4]
        if ([CclWin]::MonitorFromRect([ref]$rc, 0) -ne [IntPtr]::Zero) {
            Log "restore: file='$($v -join ' ')' now='$(Fmt (Get-Wp))'"
            # SetWindowPlacement окно WT молча игнорирует (возвращает True, не двигает) — ставим через SetWindowPos.
            for ($k = 0; $k -lt 3; $k++) {   # WT может сам подвинуть окно сразу после создания — повторяем
                [void][CclWin]::ShowWindow($hwnd, 9)   # SW_RESTORE: из развёрнутого SetWindowPos не двигает
                $ok = [CclWin]::SetWindowPos($hwnd, [IntPtr]::Zero, $rc.L, $rc.T, $rc.R - $rc.L, $rc.B - $rc.T, 0x0014)   # NOZORDER|NOACTIVATE
                if ($v[0] -eq 3) { [void][CclWin]::ShowWindow($hwnd, 3) }   # развёрнутым; свёрнутым не открываем
                Start-Sleep -Milliseconds 400
                Log "  set#$k ok=$ok -> '$(Fmt (Get-Wp))'"
            }
            $saved = Fmt (Get-Wp)
        } else { Log "rect '$($v -join ' ')' off-monitor" }
    } else { Log "bad file: '$($v -join ' ')'" }
} else { Log 'no saved position' }

New-Item -ItemType Directory -Force (Split-Path $file) | Out-Null
while (-not $parent.WaitForExit(1000)) {
    if (-not [CclWin]::IsWindow($hwnd)) { break }
    $wp = Get-Wp
    if ($wp.showCmd -eq 2) { continue }   # свёрнутое не запоминаем
    $cur = Fmt $wp
    if ($cur -ne $saved) { Set-Content -Path $file -Value $cur -Encoding ASCII; Log "save '$cur'"; $saved = $cur }
}
Log 'end'
