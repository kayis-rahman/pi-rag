# MCP Server Usage Guidelines

This rule defines when and how to use each configured MCP (Model Context Protocol) server in Cline prompts for optimal task completion.

## Overview

MCP servers extend Cline's capabilities with specialized tools. While Cline automatically selects appropriate tools, explicitly mentioning MCP servers ensures optimal tool usage for complex tasks.

## MCP Server Guide

### 🔄 sequential-thinking
**Purpose:** Sequential reasoning, multi-step planning, complex analysis
**When to use:**
- Complex multi-step tasks requiring systematic planning
- Architecture analysis and design decisions
- Problem decomposition and solution planning
- Strategic thinking and decision trees

**Example prompts:**
```
"Use sequential-thinking MCP to plan the database migration strategy"
"Apply sequential-thinking MCP to analyze this monolithic function breakdown"
```

### 📁 filesystem
**Purpose:** File system operations, directory analysis, file manipulation
**When to use:**
- Reading/writing multiple files
- Directory structure analysis
- File organization and refactoring
- Bulk file operations (search, replace, move)
- Configuration file management

**Example prompts:**
```
"Use filesystem MCP to analyze the project directory structure"
"Check filesystem MCP for all configuration files in the back-end"
"Apply filesystem MCP to refactor file organization"
```

### 🎭 playwright
**Purpose:** Web UI testing, browser automation, end-to-end testing
**When to use:**
- UI/UX testing and validation
- Browser automation workflows
- End-to-end user journey testing
- Web application interaction testing
- Cross-browser compatibility checks

**Example prompts:**
```
"Use playwright MCP to test the user authentication flow"
"Apply playwright MCP for end-to-end testing of the stats dashboard"
```

### 🧠 memory
**Purpose:** Context management, conversation history, state persistence
**When to use:**
- Maintaining context across multiple related tasks
- Remembering previous decisions and implementations
- Long-running development sessions
- Complex refactoring with multiple phases
- Knowledge base queries and retrieval

**Example prompts:**
```
"Use memory MCP to recall our previous database optimization decisions"
"Apply memory MCP to maintain context during this multi-step refactoring"
```

### 🐘 postgres
**Purpose:** PostgreSQL database operations, query analysis, schema management
**When to use:**
- Database schema analysis and design
- SQL query optimization and performance tuning
- Database migration planning
- Data integrity checks and constraints
- Index optimization and query planning

**Example prompts:**
```
"Use postgres MCP to analyze the slow query performance"
"Check postgres MCP for table relationships and foreign keys"
"Apply postgres MCP to optimize the analytics query plan"
```

### 🌐 curl
**Purpose:** HTTP operations, API testing, network requests
**When to use:**
- REST API testing and validation
- HTTP request/response debugging
- External service integration testing
- Network troubleshooting
- API documentation and endpoint discovery

**Example prompts:**
```
"Use curl MCP to test all analytics API endpoints"
"Apply curl MCP to debug the authentication API responses"
"Check curl MCP for external service health checks"
```

### 🔍 sonarlint
**Purpose:** Code quality analysis, security scanning, bug detection
**When to use:**
- Static code analysis and quality assessment
- Security vulnerability scanning
- Code smell detection and refactoring suggestions
- Compliance checking and best practices
- Automated code review assistance

**Example prompts:**
```
"Use sonarlint MCP to analyze code quality and security issues"
"Apply sonarlint MCP for comprehensive code review"
"Check sonarlint MCP for potential security vulnerabilities"
```

### 🗄️ pg-aiguide
**Purpose:** PostgreSQL AI guidance, query optimization, database design
**When to use:**
- Complex SQL query optimization
- Database schema design recommendations
- PostgreSQL-specific best practices
- Performance tuning guidance
- Database architecture decisions

**Example prompts:**
```
"Use pg-aiguide MCP to optimize this complex analytics query"
"Apply pg-aiguide MCP for database schema design recommendations"
"Check pg-aiguide MCP for PostgreSQL performance best practices"
```

## Usage Guidelines

### When to Explicitly Mention MCP Servers

**✅ DO mention when:**
- Task clearly benefits from specific server capabilities
- You want to override Cline's automatic tool selection
- Complex multi-server operations required
- Specific tool behavior needed
- Debugging or troubleshooting specific tools

**❌ DON'T mention when:**
- Standard coding and file operations
- Simple tasks that Cline handles automatically
- Basic code analysis and editing
- Routine development work

### Multi-Server Operations

For complex tasks requiring multiple tools:
```
"Use both postgres and pg-aiguide MCP servers to analyze and optimize the database queries, then apply filesystem MCP to implement the changes"
```

```
"Check sonarlint MCP for code quality issues, then use curl MCP to test the API endpoints affected by the fixes"
```

### Best Practices

1. **Be specific:** Mention exact MCP servers needed for the task
2. **Combine wisely:** Use multiple servers only when necessary
3. **Context matters:** Consider the task complexity and requirements
4. **Fallback gracefully:** Cline will use appropriate tools even without explicit mentions

### Server Status Awareness

- Check MCP server status in Cline interface
- Disabled servers (like context7) are not available
- Server connection issues may affect availability
- Some servers require specific setup (like postgres database connection)

## Emergency Overrides

If Cline is not using the expected tools, explicitly mention the desired MCP server:
```
"I need you to specifically use the postgres MCP server for this database analysis, not just the general tools"
```

This ensures the correct specialized tools are applied to your specific task requirements.
