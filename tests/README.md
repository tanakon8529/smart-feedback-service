# Tests Documentation

## Structure
- **unit/**: Fast tests for individual components (Models, Services, Utils). Mock external dependencies.
- **integration/**: Tests API endpoints and Database interactions using a real (Dockerized) database.
- **load/**: Performance tests using k6.

## Running Tests

### Unit & Integration
Run with `pytest`. Ensure your Docker environment is up for integration tests.
```bash
pytest
```

### Load Tests
Requires [k6](https://k6.io/) installed.
```bash
k6 run tests/load/k6_script.js
```

## Other Recommended Test Types

1.  **Property-Based Testing**:
    -   Use `hypothesis` library to generate thousands of random inputs to find edge cases in your logic.
    -   *Why?* Finds bugs that standard example-based tests miss.
    
2.  **Mutation Testing**:
    -   Use `mutmut`. It changes your code randomly (mutants) and runs your tests. If tests pass, the mutant "survived" (bad). If tests fail, the mutant was "killed" (good).
    -   *Why?* Verifies the quality of your test suite.

3.  **Security Scanning**:
    -   Use `bandit` to scan Python code for common security issues.
    -   `bandit -r app/`

4.  **Contract Testing**:
    -   If this microservice talks to others, use `Pact` to verify API contracts.
