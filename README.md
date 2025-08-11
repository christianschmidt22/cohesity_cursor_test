# Cohesity Cluster Query PowerShell Script

## Overview
This PowerShell script provides a simple and efficient way to query Cohesity clusters using REST APIs to retrieve protection job runs and protected sources information.

## Requirements
- **PowerShell 5.1+** (Windows PowerShell) or **PowerShell Core 6.0+** (Cross-platform)
- **Network access** to Cohesity cluster
- **Valid credentials** with appropriate permissions on the Cohesity cluster
- **No additional modules** required - uses only native PowerShell cmdlets

## Design Decisions

### 1. Native PowerShell Approach
- **No external dependencies** - Uses only built-in PowerShell cmdlets
- **Cross-platform compatibility** - Works on Windows, Linux, and macOS
- **Easy deployment** - No module installation required

### 2. REST API Integration
- **Direct HTTP requests** using `Invoke-RestMethod`
- **JSON handling** with native PowerShell JSON conversion
- **Error handling** with try-catch blocks and proper HTTP status code checking

### 3. Security Considerations
- **Credential prompting** - Secure password input without storing credentials
- **HTTPS enforcement** - Ensures secure communication with cluster
- **Session management** - Proper authentication token handling

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   User Input   │───▶│  Authentication  │───▶│  API Queries    │
│                │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │ Session Token    │    │ Data Processing │
                       │ Management       │    │ & Output        │
                       └──────────────────┘    └─────────────────┘
```

## Code Structure

### Main Script (`Get-CohesityProtectionInfo.ps1`)
- **Authentication functions** - Handle login and session management
- **API query functions** - Retrieve protection jobs and sources
- **Data processing functions** - Parse and format API responses
- **Main execution flow** - Orchestrate the entire process

### Key Functions
1. `Connect-CohesityCluster` - Establishes connection and authentication
2. `Get-CohesityProtectionJobs` - Retrieves protection job information
3. `Get-CohesityProtectedSources` - Gets protected sources/objects
4. `Format-CohesityOutput` - Formats results for display

## API Endpoints Used

Based on Cohesity REST API documentation:
- **Authentication**: `/public/accessTokens`
- **Protection Jobs**: `/public/protectionJobs`
- **Protection Runs**: `/public/protectionRuns`
- **Protected Sources**: `/public/protectedSources`

## Usage

### Basic Usage
```powershell
.\Get-CohesityProtectionInfo.ps1
```

### Interactive Mode
The script will prompt for:
1. **Cluster Name/IP** - The Cohesity cluster to connect to
2. **Username** - Your Cohesity user account
3. **Password** - Your account password (input is masked)

### Output
The script returns:
- **Protected Sources List** - Objects being protected
- **Object Types** - Type of each protected object
- **Protection Job Status** - Current state of protection jobs

## Error Handling

- **Network connectivity** - Checks cluster reachability
- **Authentication failures** - Handles invalid credentials gracefully
- **API errors** - Provides meaningful error messages
- **Data validation** - Ensures response integrity

## Security Features

- **No credential storage** - Credentials are not saved to disk
- **Secure password input** - Uses `Read-Host -AsSecureString`
- **HTTPS enforcement** - Prevents insecure connections
- **Session timeout** - Automatic token expiration handling

## Development Notes

- **Debug mode** - Use `-Verbose` flag for detailed logging
- **Error logging** - Comprehensive error tracking for troubleshooting
- **Modular design** - Easy to extend with additional functionality
- **Testing** - Includes basic validation and error simulation

## Troubleshooting

### Common Issues
1. **Connection refused** - Check cluster IP/name and network connectivity
2. **Authentication failed** - Verify username/password and account permissions
3. **API errors** - Check cluster version compatibility and API endpoint availability

### Debug Steps
1. Run with `-Verbose` flag for detailed output
2. Check network connectivity to cluster
3. Verify API endpoint accessibility
4. Review error messages for specific failure reasons

## Future Enhancements

- **Configuration file support** - Store cluster information
- **Export functionality** - CSV/JSON output options
- **Scheduled execution** - Automated reporting capabilities
- **Additional metrics** - More detailed protection information
- **Multi-cluster support** - Query multiple clusters simultaneously

## License
This project is provided as-is for development and testing purposes.

