# Cohesity PowerShell Script - Quick Start Guide

## 🚀 Get Started in 5 Minutes

This guide will help you get the Cohesity PowerShell script running quickly.

## Prerequisites

- **PowerShell 5.1+** (Windows) or **PowerShell Core 6.0+** (Cross-platform)
- **Network access** to your Cohesity cluster
- **Valid credentials** for the Cohesity cluster

## Quick Start Steps

### 1. Test the Script (Recommended First Step)

```powershell
# Run the test script to validate functionality
.\Test-CohesityScript.ps1
```

This will run all tests and confirm the script is working correctly.

### 2. Run the Main Script

```powershell
# Execute the main script
.\Get-CohesityProtectionInfo.ps1
```

### 3. Provide Your Information

The script will prompt you for:
- **Cluster Name/IP**: Your Cohesity cluster address
- **Username**: Your Cohesity user account
- **Password**: Your account password (input will be masked)

### 4. View Results

The script will display:
- Protection jobs summary
- Protected sources information
- Protection runs status
- Option to export data to JSON

## Example Output

```
================================================================================
COHESITY CLUSTER PROTECTION INFORMATION
================================================================================

PROTECTION JOBS SUMMARY:
--------------------------------------------------
Total Active Jobs: 15
  - kVMware: 8 jobs
  - kHyperV: 4 jobs
  - kPhysical: 3 jobs

Recent Job Activity:
  - VM-Backup-Daily [✓ Success] - Last Run: 2024-01-15 02:00:00
  - HyperV-Backup-Weekly [✓ Success] - Last Run: 2024-01-14 22:00:00

PROTECTED SOURCES SUMMARY:
--------------------------------------------------
Total Protected Objects: 127
  - kVMware: 89 objects
  - kHyperV: 25 objects
  - kPhysical: 13 objects

Sample Protected Objects:
  - WebServer01 (kVMware)
  - DatabaseServer02 (kVMware)
  - FileServer01 (kHyperV)
```

## Troubleshooting Quick Fixes

### Script Won't Run
```powershell
# Check PowerShell execution policy
Get-ExecutionPolicy

# If restricted, run this (as Administrator):
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Connection Issues
- Verify cluster IP/name is correct
- Check network connectivity
- Ensure cluster is accessible from your machine

### Authentication Errors
- Verify username/password
- Check account permissions
- Ensure account is not locked

## Advanced Usage

### Verbose Mode (Debugging)
```powershell
.\Get-CohesityScript.ps1 -Verbose
```

### Test Specific Functions
```powershell
# Test URL reachability
.\Test-CohesityScript.ps1 -TestFunction "urlreachability"

# Test secure string handling
.\Test-CohesityScript.ps1 -TestFunction "securestring"

# Test data export
.\Test-CohesityScript.ps1 -TestFunction "dataexport"
```

## Next Steps

1. **Customize Configuration**: Edit `config-template.json` for your environment
2. **Review Documentation**: Read `README.md` for detailed information
3. **Extend Functionality**: Use `.cursor/rules/` for AI-assisted development
4. **Automate**: Schedule script execution for regular monitoring

## Support

- **Documentation**: See `README.md` for comprehensive guides
- **Testing**: Use `Test-CohesityScript.ps1` for validation
- **AI Development**: `.cursor/rules/` provides context for AI assistance
- **Project Structure**: `PROJECT_STRUCTURE.md` explains organization

## Success Indicators

✅ Script runs without errors  
✅ Tests pass successfully  
✅ Connection to cluster established  
✅ Data retrieved and displayed  
✅ Export functionality works  

If you see all these indicators, you're ready to use the script in production!

