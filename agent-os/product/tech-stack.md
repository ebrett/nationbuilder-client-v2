# Tech Stack

## Language & Runtime

- **Ruby**: 2.7+ (modern Ruby with required: true support, pattern matching available)
- **Version Management**: mise (as per user environment for runtime version management)

## Core Dependencies

### HTTP & Networking
- **HTTP.rb**: Modern HTTP client library for all API requests (clean API, excellent streaming support, middleware-friendly)
- **OAuth2**: OAuth 2.0 protocol implementation for authorization flows and token management

### JSON Processing
- **Multi JSON**: Flexible JSON parsing library allowing users to use their preferred JSON adapter (Oj, Yajl, standard lib)

### Configuration
- **Dotenv**: Environment variable management for standalone Ruby applications (development/testing)
- **Rails**: ActiveSupport and Rails integration for Rails applications (optional peer dependency)

## Development Dependencies

### Testing Framework
- **RSpec**: Primary testing framework (BDD-style specs, extensive matcher library)
- **VCR**: HTTP interaction recording/playback for integration tests
- **WebMock**: HTTP request stubbing and expectations
- **SimpleCov**: Code coverage reporting

### Code Quality
- **RuboCop**: Ruby static code analyzer and formatter
- **RuboCop-RSpec**: RSpec-specific RuboCop cops
- **RuboCop-Performance**: Performance-focused cops
- **Standard**: Ruby style guide and linter (wrapper around RuboCop with zero-config)

### Documentation
- **YARD**: Ruby documentation generation tool
- **Markdown**: Documentation format for README, guides, and examples

## Build & Distribution

### Gem Management
- **Bundler**: Dependency management and gem packaging
- **Rake**: Build automation and task management
- **Gem Specification**: Standard Ruby gem packaging format

### Version Control
- **Git**: Source control
- **GitHub**: Repository hosting, issue tracking, and CI/CD
- **git-secrets**: Credential scanning to prevent accidental commits of sensitive data

## CI/CD & Quality Assurance

### Continuous Integration
- **GitHub Actions**: Automated testing across Ruby versions (2.7, 3.0, 3.1, 3.2, 3.3)
- **Matrix Testing**: Test against multiple Ruby versions and dependency versions

### Quality Gates
- **RSpec Test Suite**: Comprehensive unit and integration tests
- **RuboCop Checks**: Automated style and quality enforcement
- **SimpleCov Thresholds**: Minimum code coverage requirements (target: 90%+)
- **Changelog Validation**: Ensure changelog updates for each release

## Development Tools

### Local Development
- **Bundler**: `bundle install` for dependency management
- **Rake Tasks**: Common development tasks (test, lint, console, documentation)
- **IRB/Pry**: Interactive Ruby console for API exploration (IRB default, Pry optional)

### Debugging & Logging
- **Logger**: Ruby standard library logger for gem-level logging
- **Debug Output**: Configurable request/response logging for troubleshooting

## Rails Integration (Optional)

### Rails Support
- **Rails 6.0+**: Support for modern Rails applications
- **ActiveSupport**: Utilization of Rails core extensions when available
- **Rails Generators**: Custom generators for setup and scaffolding
- **Rails Credentials**: Integration with encrypted credentials system

### Environment Configuration
- **Rails.env**: Environment detection for configuration
- **Rails.logger**: Integration with Rails logging system
- **Rails.cache**: Optional caching support for API responses

## Security

### Authentication & Authorization
- **OAuth 2.0**: Industry-standard authorization framework
- **Token Storage**: Secure credential management patterns (no hardcoded secrets)
- **Environment Variables**: Sensitive configuration via ENV vars

### Data Protection
- **HTTPS Only**: All API communication over TLS
- **Credential Sanitization**: Automatic removal of tokens/secrets from logs
- **Webhook Signature Verification**: HMAC signature validation for webhooks

## Testing Strategy

### Test Types
- **Unit Tests**: Individual class and method testing with mocked dependencies
- **Integration Tests**: End-to-end API interaction tests using VCR cassettes
- **Contract Tests**: Validation against NationBuilder API v2 specifications
- **Rails Integration Tests**: Testing Rails-specific functionality in isolation

### Test Data Management
- **VCR Cassettes**: Recorded HTTP interactions for deterministic testing
- **Fixtures**: Sample JSON responses for unit tests
- **Factory Patterns**: Test object builders for complex scenarios

## Documentation Stack

### API Documentation
- **YARD Tags**: Inline documentation with @param, @return, @example annotations
- **Generated Docs**: HTML documentation via YARD for gem API reference

### User Documentation
- **README.md**: Quick start guide and installation instructions
- **CHANGELOG.md**: Version history and migration guides
- **docs/**: Extended guides for OAuth setup, Rails integration, common patterns
- **Code Examples**: Inline examples in documentation and separate examples/ directory

## Package Registry

### Distribution
- **RubyGems.org**: Primary gem distribution platform
- **Semantic Versioning**: Version numbering following SemVer (MAJOR.MINOR.PATCH)
- **GitHub Releases**: Tagged releases with changelog and upgrade notes
