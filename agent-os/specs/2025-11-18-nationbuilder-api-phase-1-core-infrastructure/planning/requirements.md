# Spec Requirements: NationBuilder API Phase 1 Core Infrastructure

## Initial Description

Phase 1 focuses on core infrastructure for the NationBuilder API Ruby gem, including:
- OAuth 2.0 authentication flow implementation
- Base client architecture with HTTP.rb
- Error handling and custom exceptions
- Configuration management
- Request/response logging

This is the foundation phase that will enable all subsequent API resource implementations.

## Product Context

### Product Mission
The NationBuilder API gem provides a Ruby-first interface for political campaigns, advocacy groups, and nonprofits to integrate with NationBuilder's v2 API. It eliminates 100+ lines of OAuth and HTTP client boilerplate, providing OAuth authentication out-of-the-box, automatic token management, and comprehensive error handling.

### Target Users
- **Campaign Developers**: Need quick, reliable integrations for voter contact dashboards and custom campaign tools
- **Rails Application Developers**: Require seamless Rails integration with environment-based configuration
- **Solo Developers/Consultants**: Need rapid prototyping with minimal configuration

### Key Differentiators
- OAuth 2.0 authentication built-in (eliminates 50+ lines of code)
- Resource-based design pattern following Stripe/Twilio gem conventions
- Rails-first integration with generators and conventions
- Comprehensive error handling with actionable error messages

### Phase 1 Position in Roadmap
This is the foundation phase (v0.1.0) that establishes:
- OAuth 2.0 authentication flow
- Base HTTP client architecture
- Error handling hierarchy
- Configuration system
- Request logging and debugging

Phase 2 will build People, Donations, Events, and Tags resources on this foundation.
Phase 3 will add pagination, rate limit management, webhooks, and batch operations.
Phase 4 will add Rails generators, comprehensive docs, and testing utilities.

## Requirements Discussion

### First Round Questions

**Q1: OAuth Flow Storage** - Should we provide specific storage adapters (ActiveRecord, Redis) out of the box, or just a simple interface for users to implement?
**Answer:** Provide specific adapters (ActiveRecord, Redis) out of the box, similar to Pay gem's multi-processor pattern

**Q2: PKCE Support** - Should we support both traditional OAuth flow and PKCE flow, or PKCE only (more secure, modern best practice)?
**Answer:** PKCE only - modern best practice, more secure, simpler implementation

**Q3: Client Initialization Pattern** - Should we support both global configuration (`NationbuilderApi.configure`) and instance-based (`Client.new`) patterns?
**Answer:** Support both global configuration (`NationbuilderApi.configure`) and instance-based (`Client.new`) with instance taking precedence

**Q4: Error Handling Hierarchy** - Should error classes include a `retryable?` method to indicate which errors can be safely retried?
**Answer:** Yes, include `retryable?` method in exception classes to indicate which errors can be safely retried

**Q5: Rate Limit Response** - When we hit rate limits, should we just raise an error with retry-after details, or implement automatic retry logic?
**Answer:** Just raise error with retry-after details (no automatic retry in Phase 1)

**Q6: Logging Defaults** - Should we use Ruby's standard Logger, or integrate with Rails.logger when available?
**Answer:** Use Ruby's standard Logger with Rails.logger integration when available

**Q7: Configuration Validation** - Should we fail fast at initialization time if required config is missing, or wait until first API call?
**Answer:** Fail fast at initialization time

**Q8: HTTP.rb Middleware** - Should the HTTP.rb middleware stack be user-configurable, or keep it internal?
**Answer:** Keep middleware stack internal (not user-configurable in Phase 1)

**Q9: Base URL Configuration** - Should we default to `https://api.nationbuilder.com/v2` with override capability, or require users to specify?
**Answer:** Default to `https://api.nationbuilder.com/v2` with override capability

**Q10: Scope Management** - Should we provide OAuth scope constants (like `SCOPE_PEOPLE_READ`, `SCOPE_PEOPLE_WRITE`)?
**Answer:** Yes, provide OAuth scope constants

**Q11: Phase 1 Exclusions** - What should we explicitly exclude from Phase 1?
**Answer:** Explicitly exclude:
- Actual API resources (People, Donations, Events) - Phase 2
- Pagination helpers - Phase 3
- Webhook signature verification - Phase 3
- Batch operations - Phase 3
- Automatic retry logic - Phase 3
- Rails generators - Phase 4

### Existing Code to Reference

**Reference Architecture:**
The Pay gem (https://github.com/pay-rails/pay) serves as architectural inspiration for this implementation.

**Key Patterns from Pay Gem:**
- Module structure with `mattr_accessor` for configuration and `autoload` for processors/adapters
- Adapter pattern for multiple payment processor support (analogous to our token storage adapters)
- Rails Engine integration with engine initializers for seamless Rails support
- Simple error hierarchy: base `Error < StandardError` with specific subclasses
- Configuration via `Pay.setup { |config| }` block with sensible defaults
- `enabled?` class methods on adapters to check if dependencies are loaded
- Version requirements verification to ensure dependency gems match requirements

**Architectural Decisions Based on Pay Gem:**
1. Use `mattr_accessor` for global configuration options
2. Rails Engine for automatic Rails integration
3. Token storage adapters: ActiveRecord adapter (default), Redis adapter, Memory adapter (testing)
4. Error classes include original HTTP response and parsed error details
5. Configuration via `NationbuilderApi.setup` block or environment variables
6. OAuth scope constants as module constants
7. Logging with automatic Rails.logger detection

### Follow-up Questions
None required - answers were comprehensive with clear architectural direction.

## Visual Assets

### Files Provided:
No visual assets provided.

### Visual Insights:
Not applicable.

## Requirements Summary

### Functional Requirements

**OAuth 2.0 with PKCE:**
- Authorization URL generation with PKCE challenge/verifier
- Token exchange (authorization code for access token)
- Automatic token refresh when access token expires
- OAuth scope constants as module constants (e.g., `SCOPE_PEOPLE_READ`, `SCOPE_PEOPLE_WRITE`)

**Token Storage Interface:**
- Abstract storage interface for token persistence
- ActiveRecord adapter (default) - stores tokens in database
- Redis adapter - stores tokens in Redis
- Memory adapter - in-memory storage for testing
- Adapters include `enabled?` method to check dependency availability

**Base HTTP Client:**
- Built on HTTP.rb library
- Default base URL: `https://api.nationbuilder.com/v2` (configurable)
- Internal middleware stack (not user-configurable in Phase 1)
- Automatic header management (Authorization, Content-Type, User-Agent)
- Request/response middleware pipeline

**Error Hierarchy:**
- Base `NationbuilderApi::Error < StandardError`
- Specific error subclasses for different failure modes:
  - `AuthenticationError` - OAuth/token failures
  - `AuthorizationError` - Permission/scope issues
  - `ValidationError` - Invalid request parameters
  - `RateLimitError` - Rate limit exceeded (includes retry-after details)
  - `NotFoundError` - Resource not found
  - `ServerError` - 5xx responses
  - `NetworkError` - Connection/timeout issues
- All error classes include `retryable?` method
- Errors include original HTTP response and parsed error details

**Configuration Management:**
- Global configuration via `NationbuilderApi.configure` block
- Instance-based configuration via `Client.new(options)`
- Instance configuration takes precedence over global
- Environment variable support for sensitive credentials
- Fail-fast validation at initialization time
- Configuration options:
  - `client_id` (required)
  - `client_secret` (required)
  - `redirect_uri` (required for OAuth flow)
  - `base_url` (defaults to NationBuilder v2 API)
  - `token_adapter` (defaults to ActiveRecord if available)
  - `logger` (defaults to Rails.logger if available, else standard Logger)
  - `log_level` (defaults to :info)

**Request/Response Logging:**
- Uses Ruby's standard Logger
- Automatic Rails.logger integration when Rails is detected
- Configurable log levels (debug, info, warn, error)
- Credential sanitization (removes tokens, client_secret from logs)
- Request logging: method, URL, headers (sanitized), body (sanitized)
- Response logging: status, headers, body (sanitized)

**Rails Engine Integration:**
- Automatic Rails integration via Rails Engine
- Engine initializers for seamless setup
- Rails.logger integration
- ActiveSupport integration when available

### Reusability Opportunities

**Patterns to Follow from Pay Gem:**
- Module-level configuration with `mattr_accessor`
- Adapter pattern with `enabled?` checks for optional dependencies
- Rails Engine for zero-config Rails integration
- Simple error hierarchy with base class and specific subclasses
- Configuration block pattern: `NationbuilderApi.setup { |config| ... }`

**Code Organization to Model After Pay Gem:**
- `lib/nationbuilder_api.rb` - main module with configuration
- `lib/nationbuilder_api/version.rb` - version constant
- `lib/nationbuilder_api/client.rb` - HTTP client implementation
- `lib/nationbuilder_api/oauth.rb` - OAuth flow implementation
- `lib/nationbuilder_api/token_adapters/` - storage adapter implementations
  - `base.rb` - abstract interface
  - `active_record_adapter.rb`
  - `redis_adapter.rb`
  - `memory_adapter.rb`
- `lib/nationbuilder_api/errors.rb` - exception hierarchy
- `lib/nationbuilder_api/engine.rb` - Rails engine (if Rails detected)

### Scope Boundaries

**In Scope:**
- OAuth 2.0 authorization URL generation with PKCE
- OAuth 2.0 token exchange and refresh
- Token storage adapters (ActiveRecord, Redis, Memory)
- Base HTTP client with HTTP.rb
- Error hierarchy with retryable? method
- Configuration system (global and instance-based)
- Request/response logging with credential sanitization
- Rails Engine for automatic integration
- OAuth scope constants

**Out of Scope:**
- Actual API resources (People, Donations, Events, Tags) - deferred to Phase 2
- Pagination helpers - deferred to Phase 3
- Automatic retry logic for rate limits - deferred to Phase 3
- Webhook signature verification - deferred to Phase 3
- Batch operations - deferred to Phase 3
- Rails generators - deferred to Phase 4
- Comprehensive documentation - deferred to Phase 4
- Testing utilities (RSpec/Minitest helpers, VCR) - deferred to Phase 4
- CLI development tools - deferred to Phase 4

### Technical Considerations

**Technology Stack:**
- Ruby 2.7+ (modern Ruby with required: true support)
- HTTP.rb for HTTP client
- OAuth2 gem for OAuth protocol implementation
- Multi JSON for JSON parsing (flexible adapter support)
- RSpec for testing
- VCR and WebMock for HTTP stubbing
- Standard (RuboCop wrapper) for code quality

**Rails Integration:**
- Optional peer dependency on Rails 6.0+
- ActiveSupport integration when available
- Rails.logger automatic detection
- Rails Engine for zero-config setup

**Security:**
- PKCE only (no traditional OAuth flow)
- HTTPS only for all API communication
- Credential sanitization in logs
- No hardcoded secrets (environment variables)
- Token storage via adapters (supports encrypted storage)

**Testing Strategy:**
- Unit tests for individual classes with mocked dependencies
- Integration tests using VCR cassettes
- Test against multiple Ruby versions (2.7, 3.0, 3.1, 3.2, 3.3)
- SimpleCov for code coverage (target: 90%+)

**Version Management:**
- Semantic versioning (MAJOR.MINOR.PATCH)
- Phase 1 target: v0.1.0
- RubyGems.org distribution
- GitHub releases with changelog

**Dependency Management:**
- Bundler for dependency resolution
- Version constraints for security and compatibility
- Adapter `enabled?` checks for optional dependencies (ActiveRecord, Redis)

**Similar Features to Reference:**
- Pay gem (https://github.com/pay-rails/pay) - overall architecture, adapter pattern, Rails integration
- Stripe Ruby gem - resource-based API design patterns (for future phases)
- Octokit (GitHub API gem) - client initialization patterns
