# Contributing to Calendar Assistant

Thank you for your interest in contributing to Calendar Assistant! This document provides guidelines for contributing to the project.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/calendar_assistant.git`
3. Set up the development environment:
   ```bash
   bundle install
   rails db:create db:migrate db:seed
   ```
4. Create a new branch: `git checkout -b feature/your-feature-name`

## Development Guidelines

### Code Style

- Follow Ruby Style Guide and Rails best practices
- Use 2 spaces for indentation
- Keep methods small and focused
- Write descriptive variable and method names
- Add comments for complex logic

### Testing

- Write tests for all new features
- Ensure all tests pass before submitting a PR: `bundle exec rspec`
- Aim for high test coverage
- Use FactoryBot for test data
- Follow the existing test structure

### Commit Messages

- Use clear and descriptive commit messages
- Start with a verb in the imperative mood (Add, Fix, Update, etc.)
- Keep the first line under 72 characters
- Add detailed description if necessary

Example:
```
Add filtering by date range for schedules

- Implement start_date and end_date parameters
- Add tests for date range filtering
- Update API documentation
```

### Pull Requests

1. Update your branch with the latest changes from main:
   ```bash
   git checkout main
   git pull upstream main
   git checkout your-branch
   git rebase main
   ```

2. Ensure all tests pass and there are no linting errors

3. Update documentation if you're adding or changing features

4. Create a pull request with:
   - Clear title describing the change
   - Detailed description of what and why
   - Reference any related issues
   - Screenshots for UI changes (if applicable)

## Types of Contributions

### Bug Reports

When reporting bugs, please include:
- Steps to reproduce
- Expected behavior
- Actual behavior
- Ruby/Rails version
- Error messages or logs
- Screenshots if applicable

### Feature Requests

For feature requests, please:
- Describe the feature and its use case
- Explain why it would be valuable
- Provide examples if possible
- Be open to discussion

### Code Contributions

Areas where contributions are welcome:
- Bug fixes
- New features
- Performance improvements
- Documentation improvements
- Test coverage improvements
- Security enhancements

### Documentation

- Fix typos or clarify unclear sections
- Add examples
- Improve API documentation
- Translate documentation (if applicable)

## Code Review Process

1. All submissions require review
2. Maintainers will review PRs as soon as possible
3. Address any feedback or requested changes
4. Once approved, maintainers will merge the PR

## Development Setup

### Prerequisites

- Ruby 3.2.3 or higher
- Bundler
- SQLite3 (development) or PostgreSQL (production)

### Running the Application

Development server:
```bash
bundle exec rails server
```

Run tests:
```bash
bundle exec rspec
```

Run linter (if configured):
```bash
bundle exec rubocop
```

### Database

Reset database:
```bash
rails db:drop db:create db:migrate db:seed
```

Run migrations:
```bash
rails db:migrate
```

## API Development

When adding new API endpoints:

1. Follow RESTful conventions
2. Version the API (currently v1)
3. Add proper authentication and authorization
4. Return appropriate HTTP status codes
5. Include error handling
6. Update API documentation
7. Add request/response examples

## Security

- Never commit sensitive data (API keys, passwords, etc.)
- Use environment variables for configuration
- Follow security best practices
- Report security vulnerabilities privately to maintainers

## Questions?

Feel free to:
- Open an issue for discussion
- Reach out to maintainers
- Check existing issues and PRs

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

## Thank You!

Your contributions are greatly appreciated and help make Calendar Assistant better for everyone!
