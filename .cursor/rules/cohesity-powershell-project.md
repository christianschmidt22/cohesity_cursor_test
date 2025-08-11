# Cohesity PowerShell Project - AI Development Rules

## Project Context
This is a PowerShell script project designed to query Cohesity clusters using REST APIs. The project focuses on simplicity, security, and native PowerShell functionality without external dependencies.

## Core Requirements
1. **Query Cohesity clusters** for protection job runs and protected sources
2. **Interactive authentication** - prompt for cluster, username, and password
3. **Native PowerShell only** - no external modules or dependencies
4. **Development-focused** - simple, maintainable code structure

## Technical Architecture

### PowerShell Version Requirements
- **Minimum**: PowerShell 5.1 (Windows PowerShell)
- **Recommended**: PowerShell Core 6.0+ (cross-platform)
- **No modules**: Use only built-in cmdlets

### API Integration Pattern
- **REST API calls** using `Invoke-RestMethod`
- **JSON handling** with `ConvertTo-Json` and `ConvertFrom-Json`
- **Error handling** with try-catch blocks
- **HTTP status validation** for all API responses

### Security Requirements
- **No credential storage** on disk
- **Secure password input** using `Read-Host -AsSecureString`
- **HTTPS enforcement** for all cluster communications
- **Session token management** with proper expiration handling

## Code Structure Standards

### Function Naming Convention
- **Verb-Noun format**: `Get-CohesityProtectionJobs`
- **Consistent prefixes**: All functions start with `Cohesity` namespace
- **Clear purpose**: Function names should indicate their specific role

### Error Handling Standards
- **Try-catch blocks** for all API calls
- **Meaningful error messages** with specific failure reasons
- **Graceful degradation** when possible
- **Logging** for debugging and troubleshooting

### Output Formatting
- **Structured data** using PowerShell objects
- **Consistent formatting** across all functions
- **Human-readable output** with clear labeling
- **Machine-readable** when possible for automation

## API Endpoints and Data Models

### Authentication Flow
1. **POST** `/public/accessTokens`
   - Body: `{ "username": "string", "password": "string" }`
   - Response: `{ "accessToken": "string", "tokenType": "string" }`

### Protection Jobs Endpoint
- **GET** `/public/protectionJobs`
- **Parameters**: `{ "isActive": true, "isDeleted": false }`
- **Response**: Array of protection job objects

### Protection Runs Endpoint
- **GET** `/public/protectionRuns`
- **Parameters**: `{ "jobId": "string", "startTimeUsecs": "long" }`
- **Response**: Array of protection run objects

### Protected Sources Endpoint
- **GET** `/public/protectedSources`
- **Parameters**: `{ "isDeleted": false }`
- **Response**: Array of protected source objects

## Development Guidelines

### Code Quality Standards
- **Modular functions** - Each function has a single responsibility
- **Parameter validation** - Validate all inputs before processing
- **Documentation** - Comment complex logic and API interactions
- **Testing** - Include basic validation and error simulation

### Performance Considerations
- **Minimize API calls** - Batch requests when possible
- **Efficient data processing** - Use PowerShell pipeline effectively
- **Memory management** - Handle large datasets appropriately
- **Timeout handling** - Set reasonable timeouts for API calls

### Debugging and Logging
- **Verbose output** - Use `Write-Verbose` for detailed logging
- **Error tracking** - Log all errors with context
- **API response logging** - Log raw responses for troubleshooting
- **Performance metrics** - Track execution time for optimization

## Common Patterns and Solutions

### Authentication Pattern
```powershell
function Connect-CohesityCluster {
    param(
        [string]$ClusterName,
        [string]$Username,
        [SecureString]$Password
    )
    
    # Convert secure string to plain text for API
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    $PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    
    # API call and token storage
    # Return connection status
}
```

### API Call Pattern
```powershell
function Invoke-CohesityAPI {
    param(
        [string]$Endpoint,
        [hashtable]$Headers,
        [string]$Method = "GET",
        [object]$Body = $null
    )
    
    try {
        $Params = @{
            Uri = $Endpoint
            Method = $Method
            Headers = $Headers
        }
        
        if ($Body) { $Params.Body = $Body }
        
        $Response = Invoke-RestMethod @Params
        return $Response
    }
    catch {
        # Handle specific error types
        # Return meaningful error information
    }
}
```

### Data Processing Pattern
```powershell
function Format-CohesityOutput {
    param([object]$Data)
    
    # Transform API response to user-friendly format
    # Handle different data types consistently
    # Return structured PowerShell objects
}
```

## Error Handling Patterns

### Network Errors
- **Connection refused**: Check cluster reachability
- **Timeout**: Verify network latency and cluster responsiveness
- **SSL/TLS errors**: Ensure proper certificate handling

### Authentication Errors
- **Invalid credentials**: Clear error message for user
- **Account locked**: Inform user of account status
- **Permission denied**: Explain required permissions

### API Errors
- **Rate limiting**: Implement retry logic with backoff
- **Invalid parameters**: Validate inputs before API calls
- **Server errors**: Provide fallback behavior when possible

## Testing and Validation

### Input Validation
- **Cluster name**: Validate format and reachability
- **Username**: Check for required characters and length
- **Password**: Ensure minimum security requirements

### API Response Validation
- **Data integrity**: Verify response structure
- **Error handling**: Test various error conditions
- **Performance**: Validate response times

### Edge Cases
- **Empty responses**: Handle no data scenarios
- **Large datasets**: Test with significant data volumes
- **Network interruptions**: Test connection loss scenarios

## Maintenance and Support

### Code Updates
- **Version tracking** - Maintain version numbers in script
- **Change logging** - Document all modifications
- **Backward compatibility** - Ensure updates don't break existing functionality

### Troubleshooting Support
- **Error codes** - Provide specific error identification
- **Debug mode** - Include comprehensive logging options
- **Common solutions** - Document frequent issues and resolutions

### Performance Monitoring
- **Execution time** - Track script performance
- **API response times** - Monitor cluster responsiveness
- **Resource usage** - Monitor memory and CPU consumption

## Future Enhancement Considerations

### Scalability
- **Multi-cluster support** - Query multiple clusters simultaneously
- **Batch processing** - Handle large numbers of objects efficiently
- **Parallel execution** - Use PowerShell jobs for concurrent operations

### Functionality Extensions
- **Export options** - CSV, JSON, XML output formats
- **Scheduling** - Automated execution capabilities
- **Notifications** - Email or webhook alerts for issues

### Integration Possibilities
- **Configuration management** - External config file support
- **Logging integration** - Centralized logging systems
- **Monitoring tools** - Integration with monitoring platforms

## Security Best Practices

### Credential Handling
- **Never store** passwords in plain text
- **Use secure strings** for all password inputs
- **Clear variables** after use to prevent memory exposure

### Network Security
- **Enforce HTTPS** for all communications
- **Validate certificates** when possible
- **Use secure protocols** for all API interactions

### Access Control
- **Principle of least privilege** - Use minimal required permissions
- **Session management** - Proper token expiration and cleanup
- **Audit logging** - Track all access attempts and operations

