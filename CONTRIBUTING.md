# Contributing to cjdiag

Thank you for your interest in contributing to cjdiag.

## How to Contribute

### Bug Reports

Open an issue on GitHub with:
- A minimal reproducible example
- Expected vs actual behavior
- `sessionInfo()` output

### Feature Requests

Open an issue describing the feature and its use case.

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Make your changes
4. Run `devtools::check()` — ensure 0 errors, 0 warnings
5. Run `devtools::test()` — ensure all tests pass
6. Add tests for new functionality
7. Update `NEWS.md`
8. Submit a pull request

### Code Style

- Follow the [tidyverse style guide](https://style.tidyverse.org/)
- Use roxygen2 for documentation
- All exported functions need `@param`, `@return`, and `@examples`

### Testing

- Use testthat (edition 3)
- Test all exported functions
- Keep tests fast (use small synthetic data, not full datasets)
