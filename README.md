# Windows Service Debloat Script

PowerShell script to configure Windows services as **Manual** or **Disabled**.

---

## Features

- Reads service list from `services.txt`
- Automatically applies startup states
- Error handling
- Skips protected services

---

## Usage

1. Edit the `services.txt` file  
2. Run as administrator:
```powershell
.\teste.ps1