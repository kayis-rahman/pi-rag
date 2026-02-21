# Build and Testing Guide for Synapse Claude Plugin

## Prerequisites

Before building and testing the Synapse Claude Plugin, ensure you have:

1. Node.js >= 16.x
2. npm >= 8.x
3. TypeScript >= 4.9.0
4. A running Synapse MCP server on `http://localhost:8003` (configurable in src/config.ts)
5. Claude Code development environment

## Building the Plugin

### 1. Install Dependencies

```bash
cd /home/dietpi/synapse/synapse-claude-plugin
npm install
```

### 2. Build the Plugin

```bash
# Build for production
npm run build

# Watch for changes during development
npm run watch
```

### 3. Build Output

The build process generates files in the `dist/` directory:
- `extension.js` - Main plugin bundle
- `extension.js.map` - Source maps for debugging
- TypeScript declaration files (if enabled)

## Testing the Plugin

### 1. Unit Testing

The plugin includes unit tests for core components:

```bash
# Run all unit tests
npm test

# Run specific tests
npm run test -- --testPathPattern="codeAnalyzer"
```

### 2. Integration Testing

To test integration with Synapse's MCP server:

```bash
# Run integration tests
npm run test:integration
```

### 3. Manual Testing

#### Test 1: Basic Functionality
1. Open Claude Code
2. Activate the Synapse plugin
3. Open a Python/JavaScript file
4. Run "Synapse: Analyze Current File"

#### Test 2: MCP Tool Integration
1. Open Claude Code
2. Run "Synapse: Search Knowledge Base"
3. Enter a query like "Python REST API"
4. Verify results are returned from Synapse

#### Test 3: IDE Integration
1. Open any code file
2. Hover over code elements
3. Verify hover information from Synapse
4. Check for code lenses in the editor

### 4. Performance Testing

#### Load Time Testing
```bash
# Measure plugin activation time
time code . --disable-extensions
```

#### Memory Usage Testing
Monitor memory usage during:
- Code analysis operations
- Context retrieval from Synapse
- Documentation generation

## Testing Scenarios

### 1. Successful Integration
- Plugin activates without errors
- MCP connection to Synapse server established
- All 7 MCP tools accessible
- Code analysis executes successfully

### 2. Error Handling
- Network connectivity issues
- Invalid MCP tool parameters
- Timeout scenarios
- Memory limitations

### 3. Edge Cases
- Empty or malformed code files
- Very large code files
- Special characters in filenames
- Different programming languages

## Debugging

### 1. Console Logging
Enable detailed logging in the plugin:
```typescript
// In extension.ts
console.log('Debug: Plugin activated');
console.log('Debug: MCP Client initialized');
```

### 2. Browser DevTools
Open Claude Code's Developer Tools:
1. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on macOS)
2. Type "Developer: Reload Window"
3. Open Developer Tools (View → Toggle Developer Tools)

### 3. Network Monitoring
Monitor network traffic to `http://localhost:8003` (configurable in src/config.ts):
- Verify HTTP requests to MCP endpoints
- Check response times and payloads
- Validate JSON structure of responses

## Continuous Integration

### 1. Build Pipeline
```yaml
# Example GitHub Actions workflow
name: Build and Test Synapse Plugin
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
    - name: Install dependencies
      run: npm ci
    - name: Build plugin
      run: npm run build
    - name: Run tests
      run: npm test
```

### 2. Test Coverage
- 100% coverage of MCP tool integration
- 95%+ coverage of core analysis components
- 100% coverage of error handling scenarios

## Performance Benchmarks

### 1. Response Times
- Code analysis: < 100ms for typical files
- Context retrieval: < 200ms
- Semantic search: < 500ms

### 2. Memory Usage
- Peak memory consumption: < 50MB
- Cache efficiency: > 90%
- Network bandwidth: < 1MB/sec

## Troubleshooting

### 1. Connection Issues
**Problem**: Cannot connect to Synapse MCP server
**Solution**:
```bash
# Verify Synapse is running
curl http://piworm.local:8003/health

# Check firewall settings
sudo ufw status

# Verify ports are open
netstat -tuln | grep 8003
```

### 2. Authentication Issues
**Problem**: MCP authentication failures
**Solution**:
- Verify Synapse configuration
- Check MCP server settings
- Review security policies

### 3. Performance Issues
**Problem**: Slow analysis operations
**Solution**:
- Check network connectivity
- Monitor resource usage
- Review caching configuration

## Release Process

### 1. Version Management
Update `package.json` with new version:
```json
{
  "version": "0.1.1"
}
```

### 2. Build for Release
```bash
npm run build
npm run package  # if using VS Code extension packaging
```

### 3. Testing Release
- Test in clean environment
- Verify all features work
- Document any breaking changes

### 4. Publishing
- Package as VS Code extension
- Publish to marketplace
- Update documentation

## Monitoring

### 1. Health Checks
Monitor these metrics:
- MCP connection status
- Response times
- Error rates
- Cache hit ratios

### 2. Logging
Enable detailed logging:
```typescript
// In extension.ts
const logLevel = process.env.SYNAPSE_LOG_LEVEL || 'info';
console.log(`[${new Date().toISOString()}] ${logLevel}: Plugin initialized`);
```

### 3. Metrics Collection
Collect these performance metrics:
- Average analysis time
- Network request frequency
- Memory usage patterns
- Error rate trends

## Support

### 1. Reporting Issues
When reporting issues:
- Include plugin version
- Describe reproduction steps
- Attach logs if available
- Specify environment details

### 2. Community Support
- GitHub Issues for bugs
- Discussions for feature requests
- Documentation for usage guides

## Future Improvements

### 1. Performance Enhancements
- Advanced caching strategies
- Parallel processing
- Background analysis operations

### 2. Feature Extensions
- AI-powered code suggestions
- Collaborative features
- Advanced pattern recognition

### 3. Integration Improvements
- More programming language support
- Enhanced IDE integration
- Team collaboration features