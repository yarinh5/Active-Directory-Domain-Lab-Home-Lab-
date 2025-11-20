##הקמת סביבת דומיין Active Directory – מעבדה אישית

המטרה שלי כאן הייתה לבנות מעבדה נקייה, כזו שאפשר להרים בקלות ולתרגל בה עולם אמיתי: AD DS, DNS, GPOs, משתמשים/קבוצות, מחשב לקוח שמצטרף לדומיין, ולסיום גם ייצוא דוחות ולוגים. השתדלתי להשאיר את זה פשוט וברור, עם כמה טיפים קטנים בדרך.

### מה בונים פה
- דומיין: `yarinlab.local` (אפשר לשנות בקובץ ההגדרות)
- בקר דומיין אחד (Windows Server 2016/2019)
- יחידות ארגוניות: `IT`, `HR`, `Finance`, `Workstations`
- משתמשים וקבוצות עם מדיניות סיסמאות
- GPOים: מורכבות סיסמה, רקע שולחן עבודה, חסימת USB Storage
- לקוח Windows 10/11 שמצטרף לדומיין
- ייצוא דוחות GPO, לוגים מהמערכת, ודוחות AD נוחים

### לפני שמתחילים
- מכונה וירטואלית: VMware Workstation או VirtualBox
- קבצי ISO: Windows Server 2016/2019 + Windows 10/11
- הרשאות אדמין על שתי המכונות

טיפ קטן: עדיף לעבוד עם רשת Host-Only/Private כדי להימנע מהפתעות מהראוטר/ DHCP הביתי.

### הכלים שהשתמשתי בהם
- Windows Server עם תפקידי AD DS, DNS ו-Group Policy Management
- Windows 10/11 כלקוח
- PowerShell (כולל מודולים ActiveDirectory ו-GroupPolicy)
- Hypervisor: VMware Workstation / VirtualBox
- RSAT (במידת הצורך בקליינט)

### Screenshots ו-Config
- `Screenshots\`: תיקיות לפי שלב (`01-Set-StaticIP` ... `09-Export-Reports`). שימו שם צילומי מסך מאמתים לכל שלב.
- `configs\GPO-Backups\`: גיבויי GPO לשחזור.
- `configs\GPO-Reports\`: דוחות HTML לכל GPO.
- `configs\README.md`: פקודות לדוגמה ל־Backup/Report של GPO.

### מבנה התיקיות
```
Active Directory Domain Setup/
  README.md
  lab.config.ps1
  scripts/
    01-Set-StaticIP.ps1
    02-Rename-And-Reboot.ps1
    03-Install-ADDS-And-Promote.ps1
    04-Setup-DNS.ps1
    05-Create-OUs.ps1
    06-Create-Users-And-Groups.ps1
    07-Create-GPOs.ps1
    08-Join-Client-To-Domain.ps1
    09-Export-Reports.ps1
  docs/
    Templates/
      Lab-Checklist.md
      Documentation-Template.md
      Change-Log.md
  assets/
    wallpaper.jpg   (שימו כאן תמונת רקע, או עדכנו את הנתיב בקונפיג)
```

### ריצה מהירה (Server / Domain Controller)
1) מתקינים Windows Server על VM (ממליץ 2 vCPU, 4–8GB RAM, דיסק 40GB+).
2) מתחברים כ־Administrator מקומי ומעתיקים את התיקייה (נניח `C:\Lab`).
3) פותחים PowerShell כאדמין ומאפשרים הרצה לסשן:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
```

4) עורכים את `lab.config.ps1` כדי שיתאים ל־IP/שמות אצלכם. אם רוצים רקע – שימו תמונה תחת `.\assets\wallpaper.jpg` או עדכנו נתיב.

5) מריצים לפי הסדר (על השרת):
```powershell
cd "C:\Lab"
.\scripts\01-Set-StaticIP.ps1
.\scripts\02-Rename-And-Reboot.ps1
# אחרי ריבוט, להיכנס שוב
.\scripts\03-Install-ADDS-And-Promote.ps1
# השרת יעשה ריבוט אוטומטי; להיכנס כ- Domain\Administrator
.\scripts\04-Setup-DNS.ps1
.\scripts\05-Create-OUs.ps1
.\scripts\06-Create-Users-And-Groups.ps1
.\scripts\07-Create-GPOs.ps1
```

### צירוף מחשב לקוח (Windows 10/11)
1) מתקינים את ה־Client, מתחברים כ־Administrator מקומי.
2) מעתיקים ללקוח את `lab.config.ps1` ואת `scripts\08-Join-Client-To-Domain.ps1` (למשל `C:\Lab`).
3) בלקוח מריצים:
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
cd "C:\Lab"
.\08-Join-Client-To-Domain.ps1
```
יופיע חלון קרדנצ'יאלס – אפשר `YARINLAB\Administrator` או `Administrator@yarinlab.local`. בסיום יתבצע ריבוט.

אימות מהיר אחרי הצטרפות:
- שינוי סיסמה אמור לדרוש מורכבות.
- רקע שולחן העבודה יופיע אחרי `gpupdate /force` או התחברות מחדש.
- חיבור התקן USB Storage אמור להיחסם (עכבר/מקלדת לא מושפעים).

### ייצוא דוחות ולוגים (על ה־DC)
```powershell
cd "C:\Lab"
.\scripts\09-Export-Reports.ps1
```
הכל נשמר תחת `.\exports\...`

### קובץ ההגדרות
כל מה שאפשרי להזזה נמצא ב־`lab.config.ps1`:
- Domain/NetBIOS, IP סטטי, Gateway ו־DNS
- OUs: `IT`, `HR`, `Finance`, `Workstations`
- משתמשים וקבוצות ליצירה, כולל סיסמה התחלתית
- GPOים: מורכבות סיסמה, רקע שולחן עבודה (נתיב + Style), חסימת USB Storage
- רשומות DNS שתרצו להגדיר מראש (A/PTR)

### מה כל סקריפט עושה (בגובה העיניים)
- 01-Set-StaticIP: מגדיר IPv4 סטטי ו־DNS על הכרטיס הנכון
- 02-Rename-And-Reboot: משנה שם לשרת (למשל `DC1`) ומבצע ריבוט
- 03-Install-ADDS-And-Promote: מתקין AD DS, יוצר Forest חדש עם DNS ומקדם ל־DC
- 04-Setup-DNS: מוסיף רשומות Forward/Reverse (A + PTR) ודואג ל־Reverse Zone
- 05-Create-OUs: יוצר את יחידות הארגון
- 06-Create-Users-And-Groups: יוצר קבוצות ומשתמשים, מפעיל אותם ומצרף לקבוצות
- 07-Create-GPOs: מגדיר מדיניות סיסמה, רקע שולחן עבודה, וחוסם USB Storage
- 08-Join-Client-To-Domain: מכין DNS בלקוח, מצרף לדומיין ועושה ריבוט
- 09-Export-Reports: גיבוי ודו"חות GPO (HTML), ייצוא לוגים (EVTX), ו־CSV של משתמשים/התחברויות

### תקלות נפוצות וטיפים אישיים
- להריץ PowerShell תמיד כ־Administrator.
- אם חסרים מודולי AD – ודאו שאתם על ה־DC (שם מותקנים הכלים).
- GPO לא נאכף? להריץ `gpupdate /force` ועל הדרך לעשות Log off/Log on.
- לקוח לא מצטרף? 99% מהמקרים – DNS של הלקוח חייב להצביע על ה־DC בלבד.
- רקע לא מופיע? לבדוק שהנתיב לתמונה תקין ונגיש, ושה־GPO מקושר למיקום הנכון.

### מה למסור בסוף
- צילומי מסך: Roles/Features בשרת, OUs/Users ב־ADUC, אזורי DNS ורשומות, GPOs ו־Links, שולחן עבודה בלקוח עם הרקע, ניסיון USB שנחסם, `whoami` על הלקוח.
- ייצוא: `.\exports\gpo\`, `.\exports\event-logs\`, `.\exports\ad\users.csv`, `.\exports\ad\logons-4624.csv`

### הערות אחרונות
- זו מעבדה – השתמשו בסיסמאות בדויות בלבד.
- יש גם Fine-Grained Password Policies, פה הלכתי על ברירת המחדל של הדומיין כדי להשאיר את זה ברור וישיר.
- אם אתם עובדים ברשת אחרת, אל תשכחו להתאים את ה־IP/Kameha/נתיבי DNS בקונפיג.


