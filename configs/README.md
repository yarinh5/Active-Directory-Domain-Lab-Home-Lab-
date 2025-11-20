## קונפיגורציות ויצואי GPO

תקייה זו מרכזת קבצי קונפיגורציה ויצואי מדיניות קבוצתית (GPO) מהדומיין.

- `GPO-Backups/`: גיבויים מלאים של GPO (לשחזור).
- `GPO-Reports/`: דוחות HTML של GPO (לסקירה/תיעוד).

הרצה מומלצת מתוך בקר הדומיין (PowerShell כמנהל):

### גיבוי כל ה-GPO לתיקיית גיבויים
```powershell
# יוצר גיבוי לכל ה-GPO-ים לתיקיית GPO-Backups
Backup-Gpo -All -Path (Join-Path $PSScriptRoot 'GPO-Backups')
```

### יצוא דוחות HTML לכל ה-GPO לתיקיית דוחות
```powershell
$reports = Join-Path $PSScriptRoot 'GPO-Reports'
New-Item -ItemType Directory -Force -Path $reports | Out-Null

Get-GPO -All | ForEach-Object {
  $safe = ($_.DisplayName -replace '[^A-Za-z0-9_-]', '_')
  $out  = Join-Path $reports "$safe.html"
  Get-GPOReport -Guid $_.Id -ReportType Html -Path $out
}
```

הערות:
- יש להריץ חלון PowerShell כמנהל.
- ניתן לשנות נתיבים לפי מבנה הפרויקט שלכם.
- סקריפטי PowerShell של המעבדה נמצאים תחת `scripts\` וקובץ הקונפיגורציה הראשי הוא `lab.config.ps1` בשורש הפרויקט.


