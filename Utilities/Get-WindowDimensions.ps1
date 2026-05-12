# Description: Lists the position and dimensions of all open windows that have a title bar
# Requirements: Windows OS (uses Win32 user32.dll via P/Invoke)
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class Win32 {
        [DllImport("user32.dll")]
        public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
        public struct RECT { public int Left, Top, Right, Bottom; }
    }
"@

Get-Process | Where-Object { $_.MainWindowHandle -ne 0 } | ForEach-Object {
    $rect = New-Object Win32+RECT
    [Win32]::GetWindowRect($_.MainWindowHandle, [ref]$rect) | Out-Null
    $width  = $rect.Right  - $rect.Left
    $height = $rect.Bottom - $rect.Top
    "$($_.MainWindowTitle) => winposstr:s:0,1,$($rect.Left),$($rect.Top),$($rect.Right),$($rect.Bottom) [$($width)x$($height)]"
}
