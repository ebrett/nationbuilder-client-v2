# Specification: NationBuilder API v0.1.0 - Phase 1 Core Infrastructure

## Goal

Build the foundational infrastructure for the NationBuilder API Ruby gem, providing OAuth 2.0 authentication with PKCE, flexible token storage, HTTP client architecture, comprehensive error handling, and seamless Rails integration. This establishes the base upon which all API resources will be built in Phase 2.

## User Stories

- As a **campaign developer**, I want to authenticate with NationBuilder using OAuth 2.0 so that I can securely access the API without managing low-level OAuth complexity
- As a **Rails application developer**, I want zero-configuration Rails integration so that I can use the gem immediately with sensible defaults
- As a **multi-tenant application developer**, I want instance-based client configuration so that I can manage multiple NationBuilder accounts in the same application
- As a **developer**, I want clear error messages with retry guidance so that I can handle failures appropriately
- As a **security-conscious developer**, I want credential sanitization in logs so that tokens never leak in log files
- As a **developer**, I want flexible token storage options (database, Redis, memory) so that I can choose the best persistence strategy for my application

## Core Requirements

### OAuth 2.0 with PKCE

**Authorization Flow:**
- Generate authorization URL with PKCE code challenge and verifier
- Support customizable OAuth scopes via constants (e.g., `SCOPE_PEOPLE_READ`)
- Generate cryptographically secure code verifier (43-128 characters, URL-safe)
- Create SHA256 code challenge from verifier
- Include state parameter for CSRF protection
- Return authorization URL with all required parameters

**Token Exchange:**
- Exchange authorization code for access token
- Include PKCE code verifier in token request
- Parse and store access token, refresh token, expiry time, and granted scopes
- Use configured token adapter for persistence
- Validate token response structure

**Token Refresh:**
- Detect expired access tokens (based on expires_at timestamp)
- Automatically refresh tokens using refresh_token
- Update stored tokens with new values
- Handle refresh token expiration (raise AuthenticationError)

**OAuth Scope Constants:**
Provide module-level constants for all NationBuilder API scopes:
- `SCOPE_PEOPLE_READ = "people:read"`
- `SCOPE_PEOPLE_WRITE = "people:write"`
- `SCOPE_DONATIONS_READ = "donations:read"`
- `SCOPE_DONATIONS_WRITE = "donations:write"`
- `SCOPE_EVENTS_READ = "events:read"`
- `SCOPE_EVENTS_WRITE = "events:write"`
- Additional scopes as documented by NationBuilder API v2

### Token Storage Adapters

**Abstract Interface:**
All token adapters must implement:
- `store_token(identifier, token_data)` - Persist token data
- `retrieve_token(identifier)` - Fetch token data
- `refresh_token(identifier, new_token_data)` - Update existing token
- `delete_token(identifier)` - Remove token
- `self.enabled?` - Class method returning true if adapter dependencies available

**Token Data Structure:**
```ruby
{
  access_token: "string",
  refresh_token: "string",
  expires_at: Time object,
  scopes: ["array", "of", "scopes"],
  token_type: "Bearer"
}
```

**ActiveRecord Adapter:**
- Default adapter when ActiveRecord is available
- Store tokens in database table (schema TBD - not part of Phase 1)
- Support encrypted attributes for sensitive token data
- Query by identifier (user_id, account_id, etc.)
- `enabled?` returns true if ActiveRecord constant defined

**Redis Adapter:**
- Store tokens in Redis with TTL matching token expiry
- Use identifier as Redis key (namespaced: `nationbuilder_api:tokens:{identifier}`)
- Serialize token data as JSON
- Auto-expire tokens using Redis EXPIREAT
- `enabled?` returns true if Redis constant defined and connection available

**Memory Adapter:**
- In-memory hash storage for testing
- No persistence across process restarts
- Thread-safe using Mutex if threaded access needed
- `enabled?` always returns true

**Adapter Selection:**
- Configuration option: `token_adapter` (class or symbol)
- Auto-detect: use ActiveRecord if available, else Memory
- Validate adapter implements required interface at initialization

### Base HTTP Client

**HTTP.rb Integration:**
- Use HTTP.rb gem for all HTTP communication
- Default base URL: `https://api.nationbuilder.com/v2`
- Configurable base URL for testing/staging environments
- HTTPS-only (validate and reject HTTP URLs)

**Automatic Header Management:**
- `Authorization: Bearer {access_token}` on authenticated requests
- `Content-Type: application/json` for POST/PATCH/PUT requests
- `Accept: application/json` for all requests
- `User-Agent: NationbuilderApi/{version} Ruby/{ruby_version}` for identification

**Request Methods:**
Core HTTP methods to support:
- `get(path, params: {})` - GET request with query parameters
- `post(path, body: {})` - POST request with JSON body
- `patch(path, body: {})` - PATCH request with JSON body
- `put(path, body: {})` - PUT request with JSON body
- `delete(path)` - DELETE request

**Response Handling:**
- Parse JSON responses automatically
- Return response body as Ruby hash/array
- Include response metadata (status, headers) when requested
- Handle non-JSON responses gracefully

**Timeout Configuration:**
- Default timeout: 30 seconds
- Configurable via `timeout` option
- Separate connect timeout and read timeout if needed

### Error Hierarchy

**Base Error Class:**
```ruby
class NationbuilderApi::Error < StandardError
  attr_reader :response, :error_code, :error_message

  def initialize(message = nil, response: nil)
    # Parse error details from response if present
    # Store original response for debugging
    super(message)
  end

  def retryable?
    # Default: false (subclasses override)
  end
end
```

**Specific Error Classes:**

1. **ConfigurationError** (retryable: false)
   - Missing required configuration (client_id, client_secret, redirect_uri)
   - Invalid configuration values (malformed URLs, invalid timeout)

2. **AuthenticationError** (retryable: false)
   - Invalid client credentials
   - Invalid authorization code
   - Expired or revoked refresh token
   - OAuth token exchange failures

3. **AuthorizationError** (retryable: false)
   - Insufficient OAuth scopes
   - Access denied to specific resource
   - Permission errors (403 responses)

4. **ValidationError** (retryable: false)
   - Invalid request parameters
   - Missing required fields
   - Data format errors (422 responses)

5. **NotFoundError** (retryable: false)
   - Resource does not exist (404 responses)

6. **RateLimitError** (retryable: true)
   - Rate limit exceeded (429 responses)
   - Include `retry_after` attribute with Time object
   - Parse Retry-After header or X-RateLimit-Reset header

7. **ServerError** (retryable: true)
   - 5xx server errors
   - NationBuilder API internal errors

8. **NetworkError** (retryable: true)
   - Connection timeouts
   - DNS resolution failures
   - Network unreachable errors
   - SSL/TLS errors

**Error Response Parsing:**
- Extract error code and message from NationBuilder API error response
- Handle both structured error responses and plain text errors
- Include original HTTP response in error object for debugging
- Provide helpful error messages with actionable guidance

### Configuration Management

**Global Configuration:**
```ruby
NationbuilderApi.configure do |config|
  config.client_id = ENV['NATIONBUILDER_CLIENT_ID']
  config.client_secret = ENV['NATIONBUILDER_CLIENT_SECRET']
  config.redirect_uri = ENV['NATIONBUILDER_REDIRECT_URI']
  config.base_url = 'https://api.nationbuilder.com/v2'
  config.token_adapter = :active_record
  config.logger = Logger.new(STDOUT)
  config.log_level = :info
  config.timeout = 30
end
```

**Instance Configuration:**
```ruby
client = NationbuilderApi::Client.new(
  client_id: 'custom_id',
  client_secret: 'custom_secret',
  redirect_uri: 'https://example.com/callback',
  token_adapter: :redis
)
```

**Configuration Options:**

Required:
- `client_id` - OAuth client ID from NationBuilder
- `client_secret` - OAuth client secret from NationBuilder
- `redirect_uri` - OAuth callback URL

Optional:
- `base_url` - API base URL (default: `https://api.nationbuilder.com/v2`)
- `token_adapter` - Token storage adapter (default: auto-detect)
- `logger` - Logger instance (default: Rails.logger or Logger.new(STDOUT))
- `log_level` - Logging level (default: :info)
- `timeout` - HTTP timeout in seconds (default: 30)

**Configuration Validation:**
- Validate required fields at Client initialization
- Raise ConfigurationError with helpful message listing missing fields
- Validate URL formats (must be HTTPS)
- Validate timeout is positive integer
- Fail fast before any HTTP requests

**Precedence Rules:**
1. Instance configuration (Client.new options)
2. Global configuration (NationbuilderApi.configure block)
3. Defaults

### Request/Response Logging

**Logging Levels:**
- **DEBUG**: Full request/response bodies (sanitized), headers, timing
- **INFO**: Request method/URL, response status, timing
- **WARN**: Retryable errors, token refresh events
- **ERROR**: Non-retryable errors with full context

**Request Logging:**
Log format:
```
[NationbuilderApi] GET https://api.nationbuilder.com/v2/people/123
  Headers: {Accept: application/json, User-Agent: NationbuilderApi/0.1.0}
  Body: [FILTERED]
```

**Response Logging:**
Log format:
```
[NationbuilderApi] 200 OK (245ms)
  Headers: {Content-Type: application/json}
  Body: {"id": 123, "first_name": "John"}
```

**Credential Sanitization:**
Replace sensitive values with `[FILTERED]`:
- Authorization header values
- `access_token` fields in request/response bodies
- `refresh_token` fields
- `client_secret` fields
- Any field containing "token", "secret", "password", "key"

**Rails Integration:**
- Auto-detect Rails.logger and use if available
- Respect Rails.application.config.log_level
- Tag logs with `[NationbuilderApi]` for easy filtering

### Rails Engine Integration

**Engine Setup:**
```ruby
# lib/nationbuilder_api/engine.rb
module NationbuilderApi
  class Engine < ::Rails::Engine
    isolate_namespace NationbuilderApi

    initializer 'nationbuilder_api.logger' do
      NationbuilderApi.logger = Rails.logger if NationbuilderApi.logger.nil?
    end
  end
end
```

**Automatic Configuration:**
- Detect Rails environment and set sensible defaults
- Use Rails.logger automatically
- Support Rails credentials/encrypted credentials for secrets
- Respect Rails environment (development, test, production)

**Zero-Config Experience:**
- If ActiveRecord available, use ActiveRecord adapter by default
- Use Rails.logger for logging
- No additional setup required beyond gem installation

## Visual Design

No visual components in Phase 1 - this is pure backend infrastructure.

## Reusable Components

### Existing Code to Leverage

**External Gem Patterns (Pay gem reference):**
- Module structure with `mattr_accessor` for global configuration
- `autoload` for lazy-loading adapter classes
- Adapter pattern with `enabled?` class method
- Rails Engine for automatic Rails integration
- Simple error hierarchy with base class inheritance

**Ruby Standard Library:**
- `Logger` for request/response logging
- `SecureRandom` for PKCE verifier generation
- `Base64` for URL-safe encoding
- `Digest::SHA256` for PKCE challenge generation
- `URI` for URL parsing and validation
- `JSON` for response parsing

**External Dependencies:**
- `http` gem (HTTP.rb) for HTTP client
- `oauth2` gem for OAuth protocol implementation (optional - may implement PKCE manually)
- `activesupport` (optional) for Rails integration

### New Components Required

**OAuth Module (new):**
- PKCE implementation not available in existing gems with exact requirements
- Custom implementation gives full control over flow
- Integrates directly with token adapters

**Token Adapter Interface (new):**
- Abstract base class for adapter pattern
- Three concrete implementations (ActiveRecord, Redis, Memory)
- Specific to this gem's token storage needs

**Client Class (new):**
- Custom HTTP client wrapping HTTP.rb
- NationBuilder-specific header management
- Integrates OAuth, token storage, error handling, and logging

**Error Classes (new):**
- NationBuilder API-specific error hierarchy
- Custom `retryable?` logic for each error type
- Parse NationBuilder API error response format

## Technical Approach

### Module Structure

```
lib/
├── nationbuilder_api.rb              # Main module, configuration, autoload
├── nationbuilder_api/
│   ├── version.rb                    # Version constant
│   ├── client.rb                     # HTTP client
│   ├── oauth.rb                      # OAuth flow (authorization, token exchange, refresh)
│   ├── errors.rb                     # Error hierarchy
│   ├── configuration.rb              # Configuration class
│   ├── logger.rb                     # Logging with sanitization
│   ├── token_adapters/
│   │   ├── base.rb                   # Abstract adapter interface
│   │   ├── active_record_adapter.rb # ActiveRecord implementation
│   │   ├── redis_adapter.rb          # Redis implementation
│   │   └── memory_adapter.rb         # In-memory implementation
│   └── engine.rb                     # Rails engine (loaded conditionally)
```

### Key Implementation Notes

**PKCE Implementation:**
- Generate code verifier: 43-128 random URL-safe characters
- Create code challenge: Base64 URL-safe encode of SHA256(verifier)
- Use S256 challenge method (not plain)
- Store verifier temporarily during authorization flow

**Token Refresh Logic:**
- Check token expiry before each authenticated request
- Add 60-second buffer (refresh if expires within 60 seconds)
- Use refresh token to get new access token
- Update stored token atomically
- Handle refresh failure (delete token, raise AuthenticationError)

**HTTP.rb Middleware Stack:**
Internal middleware pipeline (not exposed to users in Phase 1):
1. Logging middleware (request/response)
2. Authentication middleware (inject Authorization header)
3. Error handling middleware (convert HTTP errors to gem exceptions)
4. JSON parsing middleware (parse response bodies)

**Thread Safety:**
- Memory adapter uses Mutex for thread-safe access
- Redis adapter is thread-safe via Redis connection pool
- ActiveRecord adapter relies on ActiveRecord's thread safety
- Client instances are not shared across threads (users create per-thread instances)

**Dependency Management:**
- Core dependencies: http gem only
- Optional dependencies: activerecord, redis, rails
- Use `enabled?` checks before using optional dependencies
- Graceful degradation when optional dependencies missing

## Out of Scope

Phase 1 explicitly excludes:

**API Resources (Phase 2):**
- People resource
- Donations resource
- Events resource
- Tags resource
- Any specific API endpoint implementations

**Advanced Features (Phase 3):**
- Pagination helpers (cursor-based, offset-based)
- Automatic retry logic for rate limits
- Webhook signature verification
- Webhook event handling
- Batch operations for bulk API calls
- Advanced rate limit management

**Developer Experience (Phase 4):**
- Rails generators (migration, model, initializer)
- Comprehensive documentation site
- RSpec/Minitest test helpers
- VCR cassettes for integration testing
- CLI development tools
- Interactive console

**Not Planned:**
- GraphQL support (NationBuilder API v2 is REST only)
- Caching layer (users implement as needed)
- Background job integration (users implement as needed)

## Success Criteria

**Functional Success:**
- OAuth 2.0 flow completes successfully (authorization URL -> token exchange -> API access)
- Token refresh works automatically when access token expires
- All three token adapters (ActiveRecord, Redis, Memory) work correctly
- HTTP client makes authenticated requests to NationBuilder API v2
- Configuration works both globally and per-instance
- Rails applications integrate with zero additional configuration

**Error Handling Success:**
- All NationBuilder API error responses map to appropriate error classes
- Error messages are clear and actionable
- `retryable?` method accurately identifies which errors can be retried
- Rate limit errors include retry-after timestamp

**Security Success:**
- No credentials appear in log files (all sanitized)
- PKCE flow prevents authorization code interception
- HTTPS-only enforcement (rejects HTTP URLs)
- No hardcoded secrets in codebase

**Code Quality Success:**
- 90%+ test coverage
- All RuboCop/Standard linting passes
- Tests pass on Ruby 2.7, 3.0, 3.1, 3.2, 3.3
- Zero external API calls in test suite (all mocked/stubbed)
- Documentation includes working code examples

**Performance Success:**
- Token refresh adds < 100ms latency
- HTTP requests complete within configured timeout
- Memory adapter uses < 1MB for 1000 tokens
- No memory leaks in long-running processes

**Developer Experience Success:**
- Rails app can integrate in < 5 minutes
- Configuration errors provide clear guidance
- Error messages include next steps
- Code examples in README work without modification
