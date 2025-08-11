# Cohesity PowerShell Project - Structure Overview

## Project Organization

This project is organized to provide a clean, maintainable, and extensible PowerShell solution for querying Cohesity clusters. The structure follows PowerShell best practices and provides comprehensive documentation for AI-assisted development.

## File Structure

```
cohesity_test/
├── README.md                           # Comprehensive project documentation
├── Get-CohesityProtectionInfo.ps1     # Main PowerShell script
├── Test-CohesityScript.ps1            # Testing and validation script
├── config-template.json                # Configuration template
├── PROJECT_STRUCTURE.md               # This file - project organization
└── .cursor/
    └── rules/
        └── cohesity-powershell-project.md  # AI development context and rules
```

## File Descriptions

### Core Scripts

#### `Get-CohesityProtectionInfo.ps1`
- **Purpose**: Main PowerShell script that implements all Cohesity cluster querying functionality
- **Key Features**:
  - Interactive authentication (cluster, username, password)
  - REST API integration with Cohesity clusters
  - Retrieval of protection jobs, runs, and protected sources
  - Comprehensive error handling and logging
  - Data export capabilities (JSON, CSV)
  - Secure credential handling
- **Architecture**: Modular function-based design with clear separation of concerns
- **Dependencies**: None - uses only native PowerShell cmdlets

#### `Test-CohesityScript.ps1`
- **Purpose**: Comprehensive testing framework for validating script functionality
- **Key Features**:
  - Unit tests for individual functions
  - Error handling validation
  - Data processing verification
  - Performance testing capabilities
- **Usage**: Run to validate script before production use

### Configuration and Documentation

#### `config-template.json`
- **Purpose**: Template configuration file for customizing script behavior
- **Key Sections**:
  - Cluster connection settings
  - API endpoint configuration
  - Query parameters and limits
  - Output formatting options
  - Logging configuration
- **Usage**: Copy and customize for your environment

#### `README.md`
- **Purpose**: Comprehensive project documentation and user guide
- **Key Sections**:
  - Project overview and requirements
  - Design decisions and architecture
  - Usage instructions and examples
  - Troubleshooting guide
  - Security considerations
- **Audience**: End users, developers, and system administrators

#### `PROJECT_STRUCTURE.md`
- **Purpose**: This file - explains project organization and file purposes
- **Key Sections**:
  - File structure overview
  - Component descriptions
  - Development workflow
  - Maintenance guidelines

### AI Development Support

#### `.cursor/rules/cohesity-powershell-project.md`
- **Purpose**: Comprehensive context for AI models to understand, maintain, and extend the project
- **Key Sections**:
  - Project context and requirements
  - Technical architecture patterns
  - Code structure standards
  - API endpoint documentation
  - Development guidelines
  - Common patterns and solutions
  - Error handling strategies
  - Testing and validation approaches
  - Security best practices
- **Audience**: AI models and developers working with the codebase

## Development Workflow

### 1. Initial Setup
1. Review `README.md` for project overview
2. Examine `PROJECT_STRUCTURE.md` for file organization
3. Customize `config-template.json` for your environment
4. Run `Test-CohesityScript.ps1` to validate functionality

### 2. Development and Testing
1. Use `Get-CohesityProtectionInfo.ps1` as the main development target
2. Run `Test-CohesityScript.ps1` after making changes
3. Update documentation in `README.md` as needed
4. Modify `.cursor/rules/` file for new AI context requirements

### 3. Production Deployment
1. Ensure all tests pass
2. Customize configuration as needed
3. Deploy to target environment
4. Monitor execution and logs

## Component Relationships

### Authentication Flow
```
User Input → Connect-CohesityCluster → Session Management → API Calls
```

### Data Retrieval Flow
```
Authentication → API Queries → Data Processing → Output Formatting → Export
```

### Error Handling Flow
```
API Call → Try-Catch → Error Classification → User-Friendly Messages → Logging
```

## Extension Points

### Adding New API Endpoints
1. Add endpoint to `config-template.json`
2. Create new function in main script
3. Update `.cursor/rules/` documentation
4. Add corresponding test cases

### Adding New Output Formats
1. Extend `Export-CohesityData` function
2. Update configuration template
3. Add format validation
4. Update documentation

### Adding New Data Sources
1. Create new query function
2. Integrate with main execution flow
3. Update output formatting
4. Add to test framework

## Maintenance Guidelines

### Code Quality
- Follow PowerShell best practices
- Maintain consistent naming conventions
- Include comprehensive error handling
- Add verbose logging for debugging

### Documentation Updates
- Keep README.md current with functionality
- Update AI rules when adding new patterns
- Maintain inline code comments
- Update examples and usage instructions

### Testing Requirements
- Run full test suite before releases
- Add tests for new functionality
- Validate error handling scenarios
- Test with different PowerShell versions

## Security Considerations

### Credential Handling
- Never store passwords in plain text
- Use secure strings for all password inputs
- Clear sensitive variables after use
- Implement proper session management

### Network Security
- Enforce HTTPS for all communications
- Validate cluster certificates when possible
- Implement proper timeout handling
- Log all access attempts

### Access Control
- Use principle of least privilege
- Implement proper token expiration
- Clear sessions after use
- Audit all operations

## Future Enhancement Roadmap

### Short Term (1-3 months)
- Configuration file support
- Enhanced error reporting
- Performance optimization
- Additional export formats

### Medium Term (3-6 months)
- Multi-cluster support
- Scheduled execution
- Notification systems
- Advanced filtering options

### Long Term (6+ months)
- Web-based interface
- Integration with monitoring tools
- Advanced analytics
- Machine learning insights

## Support and Troubleshooting

### Common Issues
- Check network connectivity to cluster
- Verify API endpoint availability
- Review error messages for specific details
- Use verbose logging for debugging

### Getting Help
- Review README.md troubleshooting section
- Run test script to validate functionality
- Check PowerShell version compatibility
- Review API documentation for endpoint changes

This project structure provides a solid foundation for building, maintaining, and extending Cohesity cluster management capabilities while ensuring AI models have comprehensive context for development assistance.

