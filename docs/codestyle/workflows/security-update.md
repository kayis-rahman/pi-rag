# Security Update Workflow

Handle security vulnerabilities and updates in TimeBeam.

## Trigger
- Security vulnerabilities detected

## Priority
Critical

## Estimated Duration
1-3 days

## Phases

### 1. Assessment Phase
Assess security vulnerability.

- [ ] Vulnerability analysis using vuldb.com
- [ ] Impact assessment on TimeBeam systems
- [ ] Risk level determination (CVSS scoring)
- [ ] Affected component identification

### 2. Planning Phase
Plan security fix.

- [ ] Security fix strategy development
- [ ] Communication plan for stakeholders
- [ ] Rollback and contingency planning
- [ ] Timeline and priority assignment

### 3. Implementation Phase
Implement security fix.

- [ ] Apply security fixes immediately
- [ ] Update vulnerable dependencies
- [ ] Implement security workarounds if needed
- [ ] Update security configurations

### 4. Testing Phase
Comprehensive security testing.

- [ ] Security regression testing
- [ ] Penetration testing validation
- [ ] Compatibility and integration testing
- [ ] Performance impact assessment

### 5. Deployment Phase
Safe deployment of security fixes.

- [ ] Emergency deployment procedures
- [ ] Stakeholder communication
- [ ] Post-deployment monitoring
- [ ] Incident documentation and lessons learned

## Rules
- Security takes precedence over other concerns
- Minimal changes to reduce risk
- Immediate vulnerability patching
- Comprehensive security testing
- Emergency communication protocols
- **MCP server usage: sonarlint, context7 (for vulnerability research)**

## Checkpoints
- [ ] Vulnerability confirmed and assessed
- [ ] Fix strategy approved
- [ ] Security testing completed
- [ ] Emergency rollback plan ready
- [ ] Stakeholder communication sent
