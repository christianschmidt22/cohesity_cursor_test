#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test script for Cohesity PowerShell functionality.
    
.DESCRIPTION
    This script provides testing capabilities for the main Cohesity script,
    allowing developers to validate individual functions and test error handling.
    
.PARAMETER TestFunction
    Specific function to test. If not specified, runs all tests.
    
.PARAMETER Verbose
    Enable detailed output for debugging.
    
.EXAMPLE
    .\Test-CohesityScript.ps1
    
.EXAMPLE
    .\Test-CohesityScript.ps1 -TestFunction "Test-UrlReachability"
    
.NOTES
    This is a development tool for testing and validation.
#>

[CmdletBinding()]
param(
    [string]$TestFunction
)

# Import the main script functions
. .\Get-CohesityProtectionInfo.ps1

# Test results tracking
$TestResults = @{
    Passed = 0
    Failed = 0
    Total = 0
}

<#
.SYNOPSIS
    Write test result with formatting.
#>
function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Message = ""
    )
    
    $TestResults.Total++
    if ($Passed) {
        $TestResults.Passed++
        Write-Host "[PASS] $TestName" -ForegroundColor Green
    } else {
        $TestResults.Failed++
        Write-Host "[FAIL] $TestName" -ForegroundColor Red
        if ($Message) {
            Write-Host "  Error: $Message" -ForegroundColor Red
        }
    }
}

<#
.SYNOPSIS
    Test URL reachability function.
#>
function Test-UrlReachabilityTest {
    Write-Host "Testing URL reachability function..." -ForegroundColor Yellow
    
    # Test with valid URL
    try {
        $Result = Test-UrlReachability -Url "https://www.google.com"
        Write-TestResult -TestName "Test-UrlReachability (Valid URL)" -Passed $Result
    }
    catch {
        Write-TestResult -TestName "Test-UrlReachability (Valid URL)" -Passed $false -Message $_.Exception.Message
    }
    
    # Test with invalid URL
    try {
        $Result = Test-UrlReachability -Url "https://invalid-url-that-does-not-exist-12345.com"
        Write-TestResult -TestName "Test-UrlReachability (Invalid URL)" -Passed (-not $Result)
    }
    catch {
        Write-TestResult -TestName "Test-UrlReachability (Invalid URL)" -Passed $false -Message $_.Exception.Message
    }
}

<#
.SYNOPSIS
    Test secure string conversion function.
#>
function Test-SecureStringConversionTest {
    Write-Host "Testing secure string conversion..." -ForegroundColor Yellow
    
    try {
        $SecureString = ConvertTo-SecureString -String "TestPassword123!" -AsPlainText -Force
        $PlainText = Convert-SecureStringToPlainText -SecureString $SecureString
        
        $Passed = $PlainText -eq "TestPassword123!"
        Write-TestResult -TestName "Convert-SecureStringToPlainText" -Passed $Passed
        
        # Clear the variable
        Clear-SensitiveData -VariableName "PlainText"
    }
    catch {
        Write-TestResult -TestName "Convert-SecureStringToPlainText" -Passed $false -Message $_.Exception.Message
    }
}

<#
.SYNOPSIS
    Test formatted output function.
#>
function Test-FormattedOutputTest {
    Write-Host "Testing formatted output function..." -ForegroundColor Yellow
    
    try {
        # Test different message types
        Write-FormattedOutput -Message "Test info message" -Type "Info"
        Write-FormattedOutput -Message "Test success message" -Type "Success"
        Write-FormattedOutput -Message "Test warning message" -Type "Warning"
        Write-FormattedOutput -Message "Test error message" -Type "Error"
        
        Write-TestResult -TestName "Write-FormattedOutput" -Passed $true
    }
    catch {
        Write-TestResult -TestName "Write-FormattedOutput" -Passed $false -Message $_.Exception.Message
    }
}

<#
.SYNOPSIS
    Test data export function.
#>
function Test-DataExportTest {
    Write-Host "Testing data export function..." -ForegroundColor Yellow
    
    try {
        # Create test data
        $TestJobs = @(
            @{
                name = "Test Job 1"
                environment = "kVMware"
                lastRunStatus = "kSuccess"
                lastRunStartTimeUsecs = [long]((Get-Date).ToUniversalTime() - [DateTime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)).TotalMilliseconds * 1000
            },
            @{
                name = "Test Job 2"
                environment = "kHyperV"
                lastRunStatus = "kFailure"
                lastRunStartTimeUsecs = $null
            }
        )
        
        $TestSources = @(
            @{
                name = "Test VM 1"
                environment = "kVMware"
                protectionStatus = "Protected"
            },
            @{
                name = "Test VM 2"
                environment = "kHyperV"
                protectionStatus = "Unprotected"
            }
        )
        
        # Test JSON export
        $JsonExport = Export-CohesityData -ProtectionJobs $TestJobs -ProtectedSources $TestSources -Format "json"
        $JsonValid = $JsonExport -match "Test Job 1" -and $JsonExport -match "Test VM 1"
        Write-TestResult -TestName "Export-CohesityData (JSON)" -Passed $JsonValid
        
        # Test CSV export
        $CsvExport = Export-CohesityData -ProtectionJobs $TestJobs -ProtectedSources $TestSources -Format "csv"
        $CsvValid = $CsvExport.Jobs.Count -eq 2 -and $CsvExport.Sources.Count -eq 2
        Write-TestResult -TestName "Export-CohesityData (CSV)" -Passed $CsvValid
        
        # Test default export
        $DefaultExport = Export-CohesityData -ProtectionJobs $TestJobs -ProtectedSources $TestSources
        $DefaultValid = $DefaultExport.ProtectionJobs.Count -eq 2 -and $DefaultExport.ProtectedSources.Count -eq 2
        Write-TestResult -TestName "Export-CohesityData (Default)" -Passed $DefaultValid
    }
    catch {
        Write-TestResult -TestName "Export-CohesityData" -Passed $false -Message $_.Exception.Message
    }
}

<#
.SYNOPSIS
    Test error handling and validation.
#>
function Test-ErrorHandlingTest {
    Write-Host "Testing error handling..." -ForegroundColor Yellow
    
    try {
        # Test empty input validation
        $EmptyCluster = ""
        $EmptyUsername = ""
        $EmptyPassword = $null
        
        # These should throw errors
        try {
            Connect-CohesityCluster -ClusterName $EmptyCluster -Username "test" -Password (ConvertTo-SecureString -String "test" -AsPlainText -Force)
            Write-TestResult -TestName "Error Handling (Empty Cluster)" -Passed $false -Message "Should have thrown error for empty cluster"
        }
        catch {
            Write-TestResult -TestName "Error Handling (Empty Cluster)" -Passed $true
        }
        
        try {
            Connect-CohesityCluster -ClusterName "test" -Username $EmptyUsername -Password (ConvertTo-SecureString -String "test" -AsPlainText -Force)
            Write-TestResult -TestName "Error Handling (Empty Username)" -Passed $false -Message "Should have thrown error for empty username"
        }
        catch {
            Write-TestResult -TestName "Error Handling (Empty Username)" -Passed $true
        }
        
        try {
            Connect-CohesityCluster -ClusterName "test" -Username "test" -Password $EmptyPassword
            Write-TestResult -TestName "Error Handling (Empty Password)" -Passed $false -Message "Should have thrown error for empty password"
        }
        catch {
            Write-TestResult -TestName "Error Handling (Empty Password)" -Passed $true
        }
    }
    catch {
        Write-TestResult -TestName "Error Handling" -Passed $false -Message $_.Exception.Message
    }
}

<#
.SYNOPSIS
    Run all tests.
#>
function Run-AllTests {
    Write-Host "Running all Cohesity script tests..." -ForegroundColor Cyan
    Write-Host "=" * 60
    
    Test-UrlReachabilityTest
    Test-SecureStringConversionTest
    Test-FormattedOutputTest
    Test-DataExportTest
    Test-ErrorHandlingTest
    
    # Display results
    Write-Host "`n" + "=" * 60
    Write-Host "TEST RESULTS SUMMARY" -ForegroundColor Cyan
    Write-Host "=" * 60
    Write-Host "Total Tests: $($TestResults.Total)" -ForegroundColor White
    Write-Host "Passed: $($TestResults.Passed)" -ForegroundColor Green
    Write-Host "Failed: $($TestResults.Failed)" -ForegroundColor Red
    
    $SuccessRate = if ($TestResults.Total -gt 0) { [math]::Round(($TestResults.Passed / $TestResults.Total) * 100, 2) } else { 0 }
    Write-Host "Success Rate: $SuccessRate%" -ForegroundColor $(if ($SuccessRate -ge 80) { "Green" } elseif ($SuccessRate -ge 60) { "Yellow" } else { "Red" })
    
    if ($TestResults.Failed -eq 0) {
        Write-Host "`nAll tests passed! The script is ready for use." -ForegroundColor Green
    } else {
        Write-Host "`nSome tests failed. Please review the errors above." -ForegroundColor Yellow
    }
}

# Main execution
if ($TestFunction) {
    # Run specific test
    switch ($TestFunction.ToLower()) {
        "urlreachability" { Test-UrlReachabilityTest }
        "securestring" { Test-SecureStringConversionTest }
        "formattedoutput" { Test-FormattedOutputTest }
        "dataexport" { Test-DataExportTest }
        "errorhandling" { Test-ErrorHandlingTest }
        default { 
            Write-Host "Unknown test function: $TestFunction" -ForegroundColor Red
            Write-Host "Available tests: urlreachability, securestring, formattedoutput, dataexport, errorhandling" -ForegroundColor Yellow
        }
    }
} else {
    # Run all tests
    Run-AllTests
}

