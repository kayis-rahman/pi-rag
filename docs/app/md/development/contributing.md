---
title: Contributing
description: How to contribute to SYNAPSE
---

# Contributing

Contributions are welcome! Here's how to get started.

## Development Setup

```bash
# Clone repository
git clone https://github.com/kayis-rahman/synapse.git
cd synapse

# Create virtual environment
python -m venv venv
source venv/bin/activate

# Install dependencies
pip install -e ".[dev]"

# Install pre-commit hooks
pip install pre-commit
pre-commit install
```

## Running Tests

```bash
# Run all tests
pytest

# Run specific test file
pytest tests/test_memory.py

# Run with coverage
pytest --cov=rag tests/
```

## Code Style

```bash
# Format code
black core/ mcp_server/ scripts/

# Type check
mypy core/
```

## Submitting Changes

1. Fork repository
2. Create a feature branch from `develop` (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Branch Workflow

We follow GitFlow-style workflow with minimal branch prefixes:

- `main` - Production releases
- `develop` - Integration branch
- `feature/*` - Feature development
- `bug/*` - Bug fixes
- `hotfix/*` - Critical production fixes

### Workflow Steps

1. Fork repository
2. Create branch from `develop` using appropriate prefix:
   ```bash
   git checkout develop
   git checkout -b feature/your-feature-name
   # OR
   git checkout -b bug/fix-description
   # OR
   git checkout -b hotfix/critical-fix
   ```
3. Make changes and commit
4. Push to your fork
5. Create Pull Request targeting `develop`
6. After PR approval and merge to `develop`, create release PR: `develop` → `main`

## Commit Messages

Follow conventional commits:

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style changes
- `refactor:` - Code refactoring
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
