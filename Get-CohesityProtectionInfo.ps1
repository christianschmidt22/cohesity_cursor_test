#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Query Cohesity cluster for protection job runs and protected sources information.
    
.DESCRIPTION
    This script connects to a Cohesity cluster using REST APIs and retrieves information
    about protection jobs, protection runs, and protected sources. It provides a simple
    way to gather backup and protection status information without external dependencies.
    
.PARAMETER Verbose
    Enable detailed logging and output for debugging purposes.
    
.EXAMPLE
    .\Get-CohesityProtectionInfo.ps1
    
.EXAMPLE
    .\Get-CohesityProtectionInfo.ps1 -Verbose
    
.NOTES
    Version: 1.0.0
    Author: Cohesity PowerShell Project
    Requires: PowerShell 5.1+ (Windows) or PowerShell Core 6.0+ (Cross-platform)
    
    This script uses only native PowerShell cmdlets and does not require any
    additional modules or dependencies.
#>

[CmdletBinding()]
param()

# Script configuration and constants
$ScriptVersion = "1.0.0"
$DefaultTimeout = 30
$MaxRetries = 3

# Global variables for session management
$Global:CohesitySession = $null
$Global:ClusterBaseUrl = $null

#region Helper Functions

<#
.SYNOPSIS
    Write formatted output with timestamp.
#>
function Write-FormattedOutput {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Color = switch ($Type) {
        "Info" { "White" }
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        default { "White" }
    }
    
    Write-Host "[$Timestamp] [$Type] $Message" -ForegroundColor $Color
}

<#
.SYNOPSIS
    Test if a URL is reachable.
#>
function Test-UrlReachability {
    param([string]$Url)
    
    try {
        $Response = Invoke-WebRequest -Uri $Url -Method Head -TimeoutSec 10 -UseBasicParsing
        return $Response.StatusCode -eq 200
    }
    catch {
        Write-Verbose "URL $Url is not reachable: $($_.Exception.Message)"
        return $false
    }
}

<#
.SYNOPSIS
    Convert secure string to plain text for API calls.
#>
function Convert-SecureStringToPlainText {
    param([SecureString]$SecureString)
    
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    $PlainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    return $PlainText
}

<#
.SYNOPSIS
    Clear sensitive data from memory.
#>
function Clear-SensitiveData {
    param([string]$VariableName)
    
    if (Get-Variable -Name $VariableName -ErrorAction SilentlyContinue) {
        Set-Variable -Name $VariableName -Value $null
        Remove-Variable -Name $VariableName -ErrorAction SilentlyContinue
    }
}

#endregion

#region Authentication Functions

<#
.SYNOPSIS
    Connect to a Cohesity cluster and authenticate.
#>
function Connect-CohesityCluster {
    param(
        [string]$ClusterName,
        [string]$Username,
        [SecureString]$Password
    )
    
    Write-FormattedOutput "Attempting to connect to Cohesity cluster: $ClusterName" "Info"
    
    # Validate cluster name
    if ([string]::IsNullOrWhiteSpace($ClusterName)) {
        throw "Cluster name cannot be empty."
    }
    
    # Handle protocol specification
    $ClusterName = $ClusterName.Trim()
    if ($ClusterName.StartsWith("http://")) {
        Write-FormattedOutput "Warning: HTTP protocol detected. Converting to HTTPS for security." "Warning"
        $ClusterName = "https://$($ClusterName.Substring(7))"
    }
    elseif ($ClusterName.StartsWith("https://")) {
        # Already has HTTPS protocol, keep as is
    }
    else {
        # No protocol specified, try HTTPS first, then HTTP if that fails
        $HttpsUrl = "https://$ClusterName"
        $HttpUrl = "http://$ClusterName"
        
        Write-Verbose "Testing HTTPS connectivity first..."
        if (Test-UrlReachability -Url $HttpsUrl) {
            $ClusterName = $HttpsUrl
            Write-FormattedOutput "Using HTTPS protocol for cluster connection" "Info"
        }
        else {
            Write-Verbose "HTTPS failed, testing HTTP connectivity..."
            if (Test-UrlReachability -Url $HttpUrl) {
                $ClusterName = $HttpUrl
                Write-FormattedOutput "Using HTTP protocol for cluster connection" "Warning"
            }
            else {
                throw "Cluster $ClusterName is not reachable via HTTPS or HTTP. Please check the cluster name and network connectivity."
            }
        }
    }
    
    # Cluster reachability already tested during protocol selection
    Write-Verbose "Cluster reachability verified during protocol selection"
    
    # Convert secure string to plain text
    $PlainPassword = Convert-SecureStringToPlainText -SecureString $Password
    
    try {
        # Prepare authentication request
        $AuthBody = @{
            username = $Username
            password = $PlainPassword
        } | ConvertTo-Json
        
        $AuthHeaders = @{
            "Content-Type" = "application/json"
            "Accept" = "application/json"
        }
        
        $AuthUrl = "$ClusterName/irisservices/api/v1/public/accessTokens"
        
        Write-Verbose "Sending authentication request to: $AuthUrl"
        
        # Send authentication request
        $AuthResponse = Invoke-RestMethod -Uri $AuthUrl -Method Post -Body $AuthBody -Headers $AuthHeaders -TimeoutSec $DefaultTimeout
        
        if ($AuthResponse.accessToken) {
            # Store session information
            $Global:CohesitySession = @{
                AccessToken = $AuthResponse.accessToken
                TokenType = $AuthResponse.tokenType
                Username = $Username
                ClusterName = $ClusterName
                LastAccess = Get-Date
            }
            
            $Global:ClusterBaseUrl = $ClusterName
            
            Write-FormattedOutput "Successfully authenticated to cluster $ClusterName as user $Username" "Success"
            
            # Clear sensitive data from memory
            Clear-SensitiveData -VariableName "PlainPassword"
            
            return $true
        }
        else {
            throw "Authentication failed: No access token received from cluster."
        }
    }
    catch {
        $ErrorMessage = "Authentication failed: $($_.Exception.Message)"
        if ($_.Exception.Response) {
            $StatusCode = $_.Exception.Response.StatusCode
            $ErrorMessage += " (HTTP Status: $StatusCode)"
        }
        
        Write-FormattedOutput $ErrorMessage "Error"
        throw $ErrorMessage
    }
    finally {
        # Ensure password is cleared from memory
        Clear-SensitiveData -VariableName "PlainPassword"
    }
}

#endregion

#region API Query Functions

<#
.SYNOPSIS
    Make authenticated API calls to Cohesity cluster.
#>
function Invoke-CohesityAPI {
    param(
        [string]$Endpoint,
        [string]$Method = "GET",
        [object]$Body = $null,
        [hashtable]$QueryParams = @{}
    )
    
    if (-not $Global:CohesitySession) {
        throw "Not connected to Cohesity cluster. Please run Connect-CohesityCluster first."
    }
    
    # Check if token is expired (basic check - 24 hours)
    $TokenAge = (Get-Date) - $Global:CohesitySession.LastAccess
    if ($TokenAge.TotalHours -gt 24) {
        Write-FormattedOutput "Authentication token may be expired. Please re-authenticate." "Warning"
    }
    
    # Build full URL
    $FullUrl = "$Global:ClusterBaseUrl/irisservices/api/v1$Endpoint"
    
    # Add query parameters if provided
    if ($QueryParams.Count -gt 0) {
        $QueryString = ($QueryParams.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "&"
        $FullUrl += "?$QueryString"
    }
    
    # Prepare headers
    $Headers = @{
        "Authorization" = "$($Global:CohesitySession.TokenType) $($Global:CohesitySession.AccessToken)"
        "Accept" = "application/json"
        "Content-Type" = "application/json"
    }
    
    # Prepare request parameters
    $RequestParams = @{
        Uri = $FullUrl
        Method = $Method
        Headers = $Headers
        TimeoutSec = $DefaultTimeout
    }
    
    if ($Body) {
        $RequestParams.Body = $Body | ConvertTo-Json -Depth 10
    }
    
    Write-Verbose "Making $Method request to: $FullUrl"
    
    try {
        $Response = Invoke-RestMethod @RequestParams
        
        # Update last access time
        $Global:CohesitySession.LastAccess = Get-Date
        
        return $Response
    }
    catch {
        $ErrorMessage = "API call failed: $($_.Exception.Message)"
        if ($_.Exception.Response) {
            $StatusCode = $_.Exception.Response.StatusCode
            $ErrorMessage += " (HTTP Status: $StatusCode)"
        }
        
        Write-FormattedOutput $ErrorMessage "Error"
        throw $ErrorMessage
    }
}

<#
.SYNOPSIS
    Get protection jobs from the cluster.
#>
function Get-CohesityProtectionJobs {
    Write-FormattedOutput "Retrieving protection jobs information..." "Info"
    
    try {
        $QueryParams = @{
            "isActive" = "true"
            "isDeleted" = "false"
        }
        
        $Jobs = Invoke-CohesityAPI -Endpoint "/public/protectionJobs" -QueryParams $QueryParams
        
        Write-FormattedOutput "Successfully retrieved $($Jobs.Count) protection jobs" "Success"
        return $Jobs
    }
    catch {
        Write-FormattedOutput "Failed to retrieve protection jobs: $($_.Exception.Message)" "Error"
        return @()
    }
}

<#
.SYNOPSIS
    Get protection runs for specific jobs.
#>
function Get-CohesityProtectionRuns {
    param([array]$JobIds)
    
    if (-not $JobIds -or $JobIds.Count -eq 0) {
        Write-FormattedOutput "No job IDs provided for protection runs query" "Warning"
        return @()
    }
    
    Write-FormattedOutput "Retrieving protection runs for $($JobIds.Count) jobs..." "Info"
    
    $AllRuns = @()
    
    foreach ($JobId in $JobIds) {
        try {
            $QueryParams = @{
                "jobId" = $JobId
                "startTimeUsecs" = [long]((Get-Date).AddDays(-30).ToUniversalTime() - [DateTime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)).TotalMilliseconds * 1000
            }
            
            $Runs = Invoke-CohesityAPI -Endpoint "/public/protectionRuns" -QueryParams $QueryParams
            
            if ($Runs) {
                $AllRuns += $Runs
            }
        }
        catch {
            Write-FormattedOutput "Failed to retrieve protection runs for job $JobId`: $($_.Exception.Message)" "Warning"
        }
    }
    
    Write-FormattedOutput "Successfully retrieved $($AllRuns.Count) protection runs" "Success"
    return $AllRuns
}

<#
.SYNOPSIS
    Get protected sources from the cluster.
#>
function Get-CohesityProtectedSources {
    Write-FormattedOutput "Retrieving protected sources information..." "Info"
    
    try {
        $QueryParams = @{
            "isDeleted" = "false"
        }
        
        $Sources = Invoke-CohesityAPI -Endpoint "/public/protectedSources" -QueryParams $QueryParams
        
        Write-FormattedOutput "Successfully retrieved $($Sources.Count) protected sources" "Success"
        return $Sources
    }
    catch {
        Write-FormattedOutput "Failed to retrieve protected sources: $($_.Exception.Message)" "Error"
        return @()
    }
}

#endregion

#region Data Processing Functions

<#
.SYNOPSIS
    Format and display protection information in a user-friendly way.
#>
function Format-CohesityOutput {
    param(
        [array]$ProtectionJobs,
        [array]$ProtectionRuns,
        [array]$ProtectedSources
    )
    
    Write-Host "`n" + "="*80
    Write-Host "COHESITY CLUSTER PROTECTION INFORMATION"
    Write-Host "="*80
    
    # Display Protection Jobs Summary
    if ($ProtectionJobs -and $ProtectionJobs.Count -gt 0) {
        Write-Host "`nPROTECTION JOBS SUMMARY:"
        Write-Host "-" * 50
        Write-Host "Total Active Jobs: $($ProtectionJobs.Count)"
        
        $JobTypes = $ProtectionJobs | Group-Object -Property "environment" | Sort-Object Count -Descending
        foreach ($Type in $JobTypes) {
            Write-Host "  - $($Type.Name): $($Type.Count) jobs"
        }
        
        # Show recent job status
        $RecentJobs = $ProtectionJobs | Sort-Object -Property "lastRunStartTimeUsecs" -Descending | Select-Object -First 5
        Write-Host "`nRecent Job Activity:"
        foreach ($Job in $RecentJobs) {
            $LastRunTime = if ($Job.lastRunStartTimeUsecs) {
                [DateTime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc).AddMilliseconds($Job.lastRunStartTimeUsecs / 1000)
            } else { "Never" }
            
            $Status = switch ($Job.lastRunStatus) {
                "kSuccess" { "Success" }
                "kFailure" { "Failed" }
                "kRunning" { "Running" }
                default { "Unknown" }
            }
            
            Write-Host "  - $($Job.name) [$Status] - Last Run: $LastRunTime"
        }
    }
    else {
        Write-Host "`nNo protection jobs found or accessible."
    }
    
    # Display Protected Sources Summary
    if ($ProtectedSources -and $ProtectedSources.Count -gt 0) {
        Write-Host "`nPROTECTED SOURCES SUMMARY:"
        Write-Host "-" * 50
        Write-Host "Total Protected Objects: $($ProtectedSources.Count)"
        
        $SourceTypes = $ProtectedSources | Group-Object -Property "environment" | Sort-Object Count -Descending
        foreach ($Type in $SourceTypes) {
            Write-Host "  - $($Type.Name): $($Type.Count) objects"
        }
        
        # Show sample of protected objects
        Write-Host "`nSample Protected Objects:"
        $SampleSources = $ProtectedSources | Select-Object -First 10
        foreach ($Source in $SampleSources) {
            $ObjectName = if ($Source.name) { $Source.name } else { "Unnamed Object" }
            $ObjectType = if ($Source.environment) { $Source.environment } else { "Unknown" }
            Write-Host "  - $ObjectName ($ObjectType)"
        }
    }
    else {
        Write-Host "`nNo protected sources found or accessible."
    }
    
    # Display Protection Runs Summary
    if ($ProtectionRuns -and $ProtectionRuns.Count -gt 0) {
        Write-Host "`nPROTECTION RUNS SUMMARY:"
        Write-Host "-" * 50
        Write-Host "Total Protection Runs (Last 30 days): $($ProtectionRuns.Count)"
        
        $RunStatuses = $ProtectionRuns | Group-Object -Property "backupRun.status" | Sort-Object Count -Descending
        foreach ($Status in $RunStatuses) {
            $StatusName = if ($Status.Name) { $Status.Name } else { "Unknown" }
            Write-Host "  - $StatusName`: $($Status.Count) runs"
        }
    }
    
    Write-Host "`n" + "="*80
}

<#
.SYNOPSIS
    Export protection information to structured format.
#>
function Export-CohesityData {
    param(
        [array]$ProtectionJobs,
        [array]$ProtectionRuns,
        [array]$ProtectedSources,
        [string]$Format = "Object"
    )
    
    switch ($Format.ToLower()) {
        "json" {
            $ExportData = @{
                ProtectionJobs = $ProtectionJobs
                ProtectedSources = $ProtectedSources
                ProtectionRuns = $ProtectionRuns
                ExportTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                ClusterName = $Global:CohesitySession.ClusterName
            }
            return $ExportData | ConvertTo-Json -Depth 10
        }
        "csv" {
            # Create CSV-friendly objects
            $JobsForCSV = $ProtectionJobs | ForEach-Object {
                [PSCustomObject]@{
                    JobName = $_.name
                    Environment = $_.environment
                    LastRunStatus = $_.lastRunStatus
                    LastRunTime = if ($_.lastRunStartTimeUsecs) {
                        [DateTime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc).AddMilliseconds($_.lastRunStartTimeUsecs / 1000)
                    } else { $null }
                }
            }
            
            $SourcesForCSV = $ProtectedSources | ForEach-Object {
                [PSCustomObject]@{
                    SourceName = $_.name
                    Environment = $_.environment
                    ProtectionStatus = $_.protectionStatus
                }
            }
            
            return @{
                Jobs = $JobsForCSV
                Sources = $SourcesForCSV
            }
        }
        default {
            return @{
                ProtectionJobs = $ProtectionJobs
                ProtectedSources = $ProtectedSources
                ProtectionRuns = $ProtectionRuns
            }
        }
    }
}

#endregion

#region Main Execution

<#
.SYNOPSIS
    Main function to orchestrate the entire process.
#>
function Main {
    Write-FormattedOutput "Cohesity Cluster Query Script v$ScriptVersion" "Info"
    Write-FormattedOutput "Starting cluster information retrieval..." "Info"
    
    try {
        # Get user input
        Write-Host "`nPlease provide the following information:"
        
        $ClusterName = Read-Host "Cluster Name/IP Address"
        if ([string]::IsNullOrWhiteSpace($ClusterName)) {
            throw "Cluster name cannot be empty."
        }
        
        $Username = Read-Host "Username"
        if ([string]::IsNullOrWhiteSpace($Username)) {
            throw "Username cannot be empty."
        }
        
        $Password = Read-Host "Password" -AsSecureString
        if (-not $Password) {
            throw "Password cannot be empty."
        }
        
        Write-Host "`nConnecting to cluster..." -ForegroundColor Yellow
        
        # Connect to cluster
        $ConnectionResult = Connect-CohesityCluster -ClusterName $ClusterName -Username $Username -Password $Password
        
        if (-not $ConnectionResult) {
            throw "Failed to connect to cluster."
        }
        
        # Clear password from memory
        Clear-SensitiveData -VariableName "Password"
        
        Write-Host "`nRetrieving cluster information..." -ForegroundColor Yellow
        
        # Get protection information
        $ProtectionJobs = Get-CohesityProtectionJobs
        $ProtectedSources = Get-CohesityProtectedSources
        
        # Get protection runs for active jobs
        $JobIds = $ProtectionJobs | Where-Object { $_.id } | ForEach-Object { $_.id }
        $ProtectionRuns = Get-CohesityProtectionRuns -JobIds $JobIds
        
        # Display results
        Format-CohesityOutput -ProtectionJobs $ProtectionJobs -ProtectionRuns $ProtectionRuns -ProtectedSources $ProtectedSources
        
        # Export data if requested
        $ExportChoice = Read-Host "`nExport data to JSON? (y/n)"
        if ($ExportChoice -eq "y" -or $ExportChoice -eq "Y") {
            $ExportData = Export-CohesityData -ProtectionJobs $ProtectionJobs -ProtectionRuns $ProtectionRuns -ProtectedSources $ProtectedSources -Format "json"
            $ExportFile = "CohesityProtectionInfo_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
            $ExportData | Out-File -FilePath $ExportFile -Encoding UTF8
            Write-FormattedOutput "Data exported to: $ExportFile" "Success"
        }
        
        Write-FormattedOutput "Script execution completed successfully!" "Success"
    }
    catch {
        Write-FormattedOutput "Script execution failed: $($_.Exception.Message)" "Error"
        Write-FormattedOutput "Please check your input and try again." "Info"
        exit 1
    }
    finally {
        # Cleanup
        if ($Global:CohesitySession) {
            Write-Verbose "Cleaning up session information..."
            $Global:CohesitySession = $null
            $Global:ClusterBaseUrl = $null
        }
    }
}

#endregion

# Script execution
if ($MyInvocation.InvocationName -ne '.') {
    Main
}

