# Task Breakdown: NationBuilder API v0.1.0 - Phase 1 Core Infrastructure

## Overview
Total Task Groups: 7
Total Tasks: ~50 atomic sub-tasks
Target Version: 0.1.0
Estimated Complexity: Medium-High (foundational infrastructure with OAuth implementation)

## Task List

### 1. Project Setup & Foundation

#### Task Group 1.1: Gem Scaffolding
**Dependencies:** None
**Complexity:** Low
**Deliverable:** Working gem structure with build/test infrastructure

- [x] 1.1.0 Complete project scaffolding
  - [ ] 1.1.1 Initialize gem structure
    - Run `bundle gem nationbuilder_api` with RSpec
    - Configure gemspec: description, homepage, license, metadata
    - Set Ruby version requirement: >= 2.7.0
    - Add required dependencies: http (~> 5.0)
    - Add development dependencies: rspec, webmock, vcr, simplecov, standard
  - [ ] 1.1.2 Set up testing infrastructure
    - Configure RSpec with spec/spec_helper.rb
    - Configure SimpleCov for code coverage tracking (target: 90%)
    - Set up WebMock to prevent real HTTP calls in tests
    - Configure VCR for HTTP interaction recording
    - Add .rspec file with --require spec_helper
  - [ ] 1.1.3 Configure CI and code quality
    - Add .rubocop.yml using Standard gem configuration
    - Create .github/workflows/ci.yml for GitHub Actions
    - Test against Ruby versions: 2.7, 3.0, 3.1, 3.2, 3.3
    - Add badge placeholders in README (build status, coverage)
  - [ ] 1.1.4 Create basic module structure
    - Create lib/nationbuilder_api.rb main module file
    - Create lib/nationbuilder_api/version.rb with VERSION constant (0.1.0)
    - Set up autoload for core classes
    - Add basic module documentation
  - [ ] 1.1.5 Verify gem builds and tests run
    - Run `bundle exec rake build` successfully
    - Run `bundle exec rspec` with no tests (0 examples)
    - Run `bundle exec standardrb` with no violations

**Acceptance Criteria:**
- Gem builds without errors
- RSpec runs successfully (even with 0 tests)
- Standard linter passes
- CI workflow validates on GitHub Actions
- All Ruby versions 2.7-3.3 tested

---

### 2. Configuration & Error Foundation

#### Task Group 2.1: Configuration System
**Dependencies:** Task Group 1.1
**Complexity:** Medium
**Deliverable:** Global and instance-based configuration with validation

- [x] 2.1.0 Complete configuration system
  - [ ] 2.1.1 Write 6-8 focused tests for configuration
    - Test global configuration via configure block
    - Test instance configuration via Client.new
    - Test instance configuration takes precedence over global
    - Test configuration defaults (base_url, timeout, log_level)
    - Test missing required configuration raises ConfigurationError
    - Test invalid URL format raises ConfigurationError
  - [ ] 2.1.2 Create lib/nationbuilder_api/configuration.rb
    - Define Configuration class with attr_accessor for all options
    - Required options: client_id, client_secret, redirect_uri
    - Optional options: base_url (default: https://api.nationbuilder.com/v2)
    - Optional options: token_adapter (default: nil, auto-detect)
    - Optional options: logger (default: nil, auto-detect)
    - Optional options: log_level (default: :info)
    - Optional options: timeout (default: 30)
  - [ ] 2.1.3 Add module-level configuration in lib/nationbuilder_api.rb
    - Add `mattr_accessor :configuration` to module
    - Define `configure` class method yielding configuration
    - Initialize default configuration on module load
    - Pattern from Pay gem: `NationbuilderApi.configure { |config| ... }`
  - [ ] 2.1.4 Implement configuration validation
    - Validate required fields presence
    - Validate base_url is HTTPS (reject HTTP)
    - Validate timeout is positive integer
    - Validate redirect_uri is valid HTTPS URL
    - Raise ConfigurationError with helpful message listing missing/invalid fields
  - [ ] 2.1.5 Ensure configuration tests pass
    - Run ONLY the 6-8 tests written in 2.1.1
    - Verify all configuration scenarios work correctly
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- The 6-8 tests written in 2.1.1 pass
- Global configuration works via configure block
- Instance configuration overrides global configuration
- Configuration validation fails fast with clear error messages
- HTTPS-only enforcement works

#### Task Group 2.2: Error Hierarchy
**Dependencies:** Task Group 1.1
**Complexity:** Low-Medium
**Deliverable:** Complete error class hierarchy with retryable? logic

- [x] 2.2.0 Complete error hierarchy
  - [ ] 2.2.1 Write 6-8 focused tests for error classes
    - Test base Error class initialization
    - Test Error class stores response and error details
    - Test retryable? method returns correct value for each error type
    - Test RateLimitError includes retry_after attribute
    - Test error message formatting with actionable guidance
    - Test error parsing from NationBuilder API response format
  - [ ] 2.2.2 Create lib/nationbuilder_api/errors.rb with base class
    - Define NationbuilderApi::Error < StandardError
    - Add attr_reader :response, :error_code, :error_message
    - Implement initialize(message = nil, response: nil)
    - Parse error details from response if present
    - Default retryable? returns false
  - [ ] 2.2.3 Implement non-retryable error classes
    - ConfigurationError - missing/invalid configuration (retryable: false)
    - AuthenticationError - OAuth/token failures (retryable: false)
    - AuthorizationError - permission/scope issues (retryable: false)
    - ValidationError - invalid request parameters (retryable: false)
    - NotFoundError - resource not found (retryable: false)
  - [ ] 2.2.4 Implement retryable error classes
    - RateLimitError - rate limit exceeded (retryable: true)
      - Add retry_after attribute (Time object)
      - Parse Retry-After or X-RateLimit-Reset header
    - ServerError - 5xx responses (retryable: true)
    - NetworkError - timeouts/connection failures (retryable: true)
  - [ ] 2.2.5 Ensure error hierarchy tests pass
    - Run ONLY the 6-8 tests written in 2.2.1
    - Verify all error classes initialize correctly
    - Verify retryable? logic works for each error type
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- The 6-8 tests written in 2.2.1 pass
- All error classes inherit from base Error
- retryable? method returns correct boolean for each type
- RateLimitError includes retry_after timestamp
- Error messages are clear and actionable

---

### 3. Token Storage Adapters

#### Task Group 3.1: Base Adapter Interface
**Dependencies:** Task Group 2.1, 2.2
**Complexity:** Medium
**Deliverable:** Abstract token storage interface

- [x] 3.1.0 Complete base adapter interface
  - [ ] 3.1.1 Write 4-6 focused tests for base adapter
    - Test enabled? class method (abstract, returns false by default)
    - Test interface methods raise NotImplementedError
    - Test token data structure validation
    - Test adapter auto-detection logic
  - [ ] 3.1.2 Create lib/nationbuilder_api/token_storage/base.rb
    - Define TokenStorage::Base abstract class
    - Define interface methods (raise NotImplementedError):
      - store_token(identifier, token_data)
      - retrieve_token(identifier)
      - refresh_token(identifier, new_token_data)
      - delete_token(identifier)
    - Define self.enabled? class method (returns false)
  - [ ] 3.1.3 Document token data structure
    - access_token: String (required)
    - refresh_token: String (required)
    - expires_at: Time object (required)
    - scopes: Array of strings (required)
    - token_type: String (default: "Bearer")
  - [ ] 3.1.4 Ensure base adapter tests pass
    - Run ONLY the 4-6 tests written in 3.1.1
    - Verify interface methods raise NotImplementedError
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- The 4-6 tests written in 3.1.1 pass
- Base class defines clear interface contract
- Token data structure is documented
- enabled? method pattern established

#### Task Group 3.2: Memory Adapter
**Dependencies:** Task Group 3.1
**Complexity:** Low
**Deliverable:** In-memory token storage for testing

- [x] 3.2.0 Complete memory adapter
  - [ ] 3.2.1 Write 6-8 focused tests for memory adapter
    - Test store_token stores data in memory
    - Test retrieve_token fetches stored data
    - Test retrieve_token returns nil for missing identifier
    - Test refresh_token updates existing token
    - Test delete_token removes token
    - Test thread-safety with Mutex
    - Test enabled? always returns true
  - [ ] 3.2.2 Create lib/nationbuilder_api/token_storage/memory.rb
    - Inherit from TokenStorage::Base
    - Use Hash for in-memory storage
    - Implement thread-safe operations using Mutex
    - Store tokens by identifier (key)
    - self.enabled? returns true (always available)
  - [ ] 3.2.3 Implement all interface methods
    - store_token: Hash[identifier] = token_data
    - retrieve_token: Hash[identifier]
    - refresh_token: Hash[identifier].merge!(new_token_data)
    - delete_token: Hash.delete(identifier)
  - [ ] 3.2.4 Ensure memory adapter tests pass
    - Run ONLY the 6-8 tests written in 3.2.1
    - Verify all CRUD operations work
    - Verify thread-safety
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- The 6-8 tests written in 3.2.1 pass
- All interface methods implemented
- Thread-safe using Mutex
- enabled? returns true
- No external dependencies

#### Task Group 3.3: Redis Adapter
**Dependencies:** Task Group 3.1
**Complexity:** Medium
**Deliverable:** Redis-based token storage

- [x] 3.3.0 Complete Redis adapter
  - [ ] 3.3.1 Write 6-8 focused tests for Redis adapter
    - Test store_token stores data in Redis
    - Test retrieve_token fetches data from Redis
    - Test Redis key namespacing (nationbuilder_api:tokens:{identifier})
    - Test token auto-expiry using EXPIREAT
    - Test refresh_token updates Redis data
    - Test delete_token removes from Redis
    - Test enabled? returns true when Redis available
    - Test enabled? returns false when Redis unavailable
  - [ ] 3.3.2 Create lib/nationbuilder_api/token_storage/redis.rb
    - Inherit from TokenStorage::Base
    - Accept redis client in initializer
    - Use namespaced keys: "nationbuilder_api:tokens:#{identifier}"
    - Serialize token data as JSON
  - [ ] 3.3.3 Implement interface methods
    - store_token: SET key, JSON.dump(token_data); EXPIREAT key, expires_at
    - retrieve_token: GET key, JSON.parse
    - refresh_token: SET key, JSON.dump(merged_data); EXPIREAT key, expires_at
    - delete_token: DEL key
    - self.enabled?: check if Redis constant defined and connection available
  - [ ] 3.3.4 Handle Redis connection errors gracefully
    - Rescue Redis connection errors
    - Raise NetworkError with helpful message
    - Log Redis connection issues
  - [ ] 3.3.5 Ensure Redis adapter tests pass
    - Run ONLY the 6-8 tests written in 3.3.1
    - Use mock Redis client or Redis test instance
    - Verify all CRUD operations work
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- The 6-8 tests written in 3.3.1 pass
- All interface methods implemented
- Redis keys properly namespaced
- Auto-expiry using EXPIREAT works
- enabled? checks Redis availability
- Connection errors handled gracefully

#### Task Group 3.4: ActiveRecord Adapter
**Dependencies:** Task Group 3.1
**Complexity:** Medium
**Deliverable:** Database-backed token storage

- [x] 3.4.0 Complete ActiveRecord adapter
  - [ ] 3.4.1 Write 6-8 focused tests for ActiveRecord adapter
    - Test store_token creates database record
    - Test retrieve_token queries by identifier
    - Test refresh_token updates existing record
    - Test delete_token destroys record
    - Test enabled? returns true when ActiveRecord available
    - Test enabled? returns false when ActiveRecord unavailable
    - Test multiple tokens per identifier (scope to latest)
  - [ ] 3.4.2 Create lib/nationbuilder_api/token_storage/active_record.rb
    - Inherit from TokenStorage::Base
    - Accept model_class option (default: detect NationbuilderApiToken)
    - Query/create records using ActiveRecord interface
    - Support encrypted attributes if available
  - [ ] 3.4.3 Implement interface methods
    - store_token: model_class.create!(identifier:, token_data)
    - retrieve_token: model_class.find_by(identifier:)&.token_data
    - refresh_token: model_class.find_by(identifier:)&.update!(token_data)
    - delete_token: model_class.find_by(identifier:)&.destroy
    - self.enabled?: check if ActiveRecord constant defined
  - [ ] 3.4.4 Handle ActiveRecord errors gracefully
    - Rescue ActiveRecord::RecordNotFound
    - Rescue ActiveRecord connection errors
    - Map to appropriate gem errors
  - [ ] 3.4.5 Ensure ActiveRecord adapter tests pass
    - Run ONLY the 6-8 tests written in 3.4.1
    - Use in-memory SQLite for testing
    - Create test table schema in test setup
    - Verify all CRUD operations work
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- The 6-8 tests written in 3.4.1 pass
- All interface methods implemented
- Works with ActiveRecord models
- enabled? checks ActiveRecord availability
- Database errors handled gracefully

**Note:** Actual ActiveRecord model/migration generation deferred to Phase 4 (Rails generators). Phase 1 provides adapter interface only.

---

### 4. OAuth 2.0 with PKCE

#### Task Group 4.1: PKCE Implementation
**Dependencies:** Task Group 2.1, 2.2, 3.1-3.4
**Complexity:** High
**Deliverable:** OAuth authorization URL generation with PKCE

- [x] 4.1.0 Complete PKCE authorization flow
  - [ ] 4.1.1 Write 6-8 focused tests for PKCE
    - Test code verifier generation (43-128 chars, URL-safe)
    - Test code challenge generation (SHA256, Base64 URL-safe)
    - Test authorization URL includes all required parameters
    - Test authorization URL includes PKCE challenge and method
    - Test state parameter generation for CSRF protection
    - Test custom OAuth scopes included in URL
  - [ ] 4.1.2 Create lib/nationbuilder_api/oauth.rb module
    - Define OAuth module under NationbuilderApi namespace
    - Add PKCE helper methods
    - Add authorization URL builder
    - Add state parameter generator
  - [ ] 4.1.3 Implement PKCE code verifier generation
    - Generate 43-128 character random string
    - Use SecureRandom.urlsafe_base64
    - Ensure URL-safe characters only (A-Z, a-z, 0-9, -, _, ~)
    - Store verifier for token exchange (temporary storage)
  - [ ] 4.1.4 Implement PKCE code challenge generation
    - Create SHA256 hash of code verifier
    - Base64 URL-safe encode the hash
    - Use challenge_method: S256 (not plain)
    - Return challenge string
  - [ ] 4.1.5 Implement authorization URL builder
    - Base URL: https://nationbuilder.com/oauth/authorize
    - Parameters: client_id, redirect_uri, response_type=code
    - PKCE parameters: code_challenge, code_challenge_method=S256
    - Optional: scope (array of scope strings joined by space)
    - Optional: state (CSRF protection token)
    - Return complete authorization URL
  - [ ] 4.1.6 Add OAuth scope constants
    - Define in lib/nationbuilder_api/scopes.rb
    - SCOPE_PEOPLE_READ = "people:read"
    - SCOPE_PEOPLE_WRITE = "people:write"
    - SCOPE_DONATIONS_READ = "donations:read"
    - SCOPE_DONATIONS_WRITE = "donations:write"
    - SCOPE_EVENTS_READ = "events:read"
    - SCOPE_EVENTS_WRITE = "events:write"
    - Document all available scopes
  - [ ] 4.1.7 Ensure PKCE tests pass
    - Run ONLY the 6-8 tests written in 4.1.1
    - Verify PKCE verifier and challenge generation
    - Verify authorization URL format
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- The 6-8 tests written in 4.1.1 pass
- PKCE verifier generates 43-128 URL-safe characters
- PKCE challenge uses SHA256 and Base64 URL-safe encoding
- Authorization URL includes all required OAuth parameters
- OAuth scope constants defined and documented

#### Task Group 4.2: Token Exchange
**Dependencies:** Task Group 4.1
**Complexity:** High
**Deliverable:** Exchange authorization code for access token

- [x] 4.2.0 Complete token exchange flow
  - [ ] 4.2.1 Write 6-8 focused tests for token exchange
    - Test successful token exchange with valid code
    - Test token exchange includes PKCE code verifier
    - Test token response parsing (access_token, refresh_token, expires_in)
    - Test token storage via configured adapter
    - Test invalid authorization code raises AuthenticationError
    - Test malformed token response raises error
    - Test token expiry calculation (expires_at from expires_in)
  - [ ] 4.2.2 Implement token exchange request
    - POST to https://nationbuilder.com/oauth/token
    - Parameters: grant_type=authorization_code, code, redirect_uri
    - Parameters: client_id, client_secret, code_verifier (PKCE)
    - Headers: Content-Type: application/x-www-form-urlencoded
    - Use HTTP.rb for request
  - [ ] 4.2.3 Parse token response
    - Extract access_token, refresh_token, expires_in, token_type
    - Extract scope (string) and split into array
    - Calculate expires_at: Time.now + expires_in
    - Validate response structure (required fields present)
    - Raise AuthenticationError if error in response
  - [ ] 4.2.4 Store token via adapter
    - Call token_adapter.store_token(identifier, token_data)
    - Token data structure matches adapter interface
    - Handle storage errors gracefully
  - [ ] 4.2.5 Ensure token exchange tests pass
    - Run ONLY the 6-8 tests written in 4.2.1
    - Use WebMock to stub OAuth token endpoint
    - Verify token storage via adapter
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- The 6-8 tests written in 4.2.1 pass
- Token exchange request includes PKCE code verifier
- Token response parsed correctly
- Tokens stored via configured adapter
- Errors handled with clear messages

#### Task Group 4.3: Token Refresh
**Dependencies:** Task Group 4.2
**Complexity:** Medium-High
**Deliverable:** Automatic token refresh when expired

- [x] 4.3.0 Complete token refresh flow
  - [ ] 4.3.1 Write 6-8 focused tests for token refresh
    - Test token expiry detection (expires_at in past)
    - Test token refresh request with refresh_token
    - Test new token response parsing and storage
    - Test refresh token expiration raises AuthenticationError
    - Test 60-second expiry buffer (refresh if expires within 60s)
    - Test refresh updates stored token via adapter
  - [ ] 4.3.2 Implement token expiry check
    - Check if expires_at <= Time.now + 60 (60-second buffer)
    - Return true if token expired or expiring soon
    - Return false if token still valid
  - [ ] 4.3.3 Implement token refresh request
    - POST to https://nationbuilder.com/oauth/token
    - Parameters: grant_type=refresh_token, refresh_token
    - Parameters: client_id, client_secret
    - Headers: Content-Type: application/x-www-form-urlencoded
    - Use HTTP.rb for request
  - [ ] 4.3.4 Parse refresh response and update storage
    - Extract new access_token, refresh_token, expires_in
    - Calculate new expires_at
    - Call token_adapter.refresh_token(identifier, new_token_data)
    - Handle refresh failure (delete token, raise AuthenticationError)
  - [ ] 4.3.5 Integrate refresh into HTTP client
    - Check token expiry before each authenticated request
    - Automatically refresh if expired/expiring
    - Retry original request with new token
    - Handle refresh failure gracefully
  - [ ] 4.3.6 Ensure token refresh tests pass
    - Run ONLY the 6-8 tests written in 4.3.1
    - Use WebMock to stub refresh endpoint
    - Verify token updates via adapter
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- The 6-8 tests written in 4.3.1 pass
- Token expiry detection works with 60-second buffer
- Token refresh request succeeds
- New tokens stored via adapter
- Expired refresh token raises AuthenticationError

---

### 5. HTTP Client & Logging

#### Task Group 5.1: Base HTTP Client
**Dependencies:** Task Group 2.1, 2.2, 4.1-4.3
**Complexity:** High
**Deliverable:** HTTP.rb-based client with authentication

- [x] 5.1.0 Complete HTTP client
  - [ ] 5.1.1 Write 6-8 focused tests for HTTP client
    - Test GET request with query parameters
    - Test POST request with JSON body
    - Test PATCH/PUT/DELETE requests
    - Test automatic Authorization header injection
    - Test automatic Content-Type and Accept headers
    - Test User-Agent header format
    - Test response JSON parsing
    - Test timeout configuration
  - [ ] 5.1.2 Create lib/nationbuilder_api/http_client.rb
    - Define HttpClient class
    - Accept configuration in initializer
    - Build HTTP.rb client with base URL and headers
    - Set default timeout from configuration
  - [ ] 5.1.3 Implement request methods
    - get(path, params: {}) - GET with query params
    - post(path, body: {}) - POST with JSON body
    - patch(path, body: {}) - PATCH with JSON body
    - put(path, body: {}) - PUT with JSON body
    - delete(path) - DELETE request
  - [ ] 5.1.4 Implement automatic header management
    - Authorization: Bearer {access_token} (from token storage)
    - Content-Type: application/json (for POST/PATCH/PUT)
    - Accept: application/json (all requests)
    - User-Agent: NationbuilderApi/{version} Ruby/{ruby_version}
  - [ ] 5.1.5 Implement response handling
    - Parse JSON response body automatically
    - Return parsed Ruby hash/array
    - Handle non-JSON responses gracefully
    - Include response metadata (status, headers) if requested
  - [ ] 5.1.6 Integrate token refresh
    - Check token expiry before each request
    - Automatically refresh if needed
    - Retry request with new token
    - Handle refresh failure
  - [ ] 5.1.7 Ensure HTTP client tests pass
    - Run ONLY the 6-8 tests written in 5.1.1
    - Use WebMock to stub HTTP requests
    - Verify all request methods work
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- The 6-8 tests written in 5.1.1 pass
- All HTTP methods implemented (GET, POST, PATCH, PUT, DELETE)
- Headers automatically managed
- JSON parsing works
- Token refresh integrated
- Timeout configuration works

#### Task Group 5.2: Error Handling Middleware
**Dependencies:** Task Group 5.1
**Complexity:** Medium
**Deliverable:** HTTP error to gem exception mapping

- [x] 5.2.0 Complete error handling
  - [ ] 5.2.1 Write 6-8 focused tests for error handling
    - Test 401 response raises AuthenticationError
    - Test 403 response raises AuthorizationError
    - Test 404 response raises NotFoundError
    - Test 422 response raises ValidationError
    - Test 429 response raises RateLimitError with retry_after
    - Test 5xx response raises ServerError
    - Test network timeout raises NetworkError
    - Test error response body parsing
  - [ ] 5.2.2 Implement HTTP status to error mapping
    - 401 -> AuthenticationError
    - 403 -> AuthorizationError
    - 404 -> NotFoundError
    - 422 -> ValidationError
    - 429 -> RateLimitError (parse Retry-After header)
    - 500-599 -> ServerError
  - [ ] 5.2.3 Implement network error handling
    - HTTP::TimeoutError -> NetworkError
    - HTTP::ConnectionError -> NetworkError
    - SocketError -> NetworkError
    - OpenSSL errors -> NetworkError
  - [ ] 5.2.4 Parse NationBuilder API error responses
    - Extract error code and message from response body
    - Handle both JSON and plain text error responses
    - Include original HTTP response in error object
    - Provide helpful error messages
  - [ ] 5.2.5 Ensure error handling tests pass
    - Run ONLY the 6-8 tests written in 5.2.1
    - Use WebMock to stub error responses
    - Verify correct error class raised
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- The 6-8 tests written in 5.2.1 pass
- All HTTP status codes map to correct error classes
- Network errors map to NetworkError
- RateLimitError includes retry_after timestamp
- Error messages are clear and actionable

#### Task Group 5.3: Request/Response Logging
**Dependencies:** Task Group 5.1
**Complexity:** Medium
**Deliverable:** Logging with credential sanitization

- [x] 5.3.0 Complete logging system
  - [ ] 5.3.1 Write 6-8 focused tests for logging
    - Test request logging format (method, URL, headers)
    - Test response logging format (status, timing)
    - Test credential sanitization in Authorization header
    - Test token field sanitization in bodies
    - Test log level configuration (debug, info, warn, error)
    - Test Rails.logger integration
    - Test custom logger support
  - [ ] 5.3.2 Create lib/nationbuilder_api/logger.rb
    - Define Logger wrapper class
    - Auto-detect Rails.logger if available
    - Fall back to Logger.new(STDOUT)
    - Support configurable log level
  - [ ] 5.3.3 Implement request logging
    - INFO level: method, URL, status, timing
    - DEBUG level: headers (sanitized), body (sanitized)
    - Log format: [NationbuilderApi] GET /v2/people/123
    - Include request timing
  - [ ] 5.3.4 Implement response logging
    - INFO level: status code, timing
    - DEBUG level: headers, body (sanitized)
    - Log format: [NationbuilderApi] 200 OK (245ms)
    - Include response size if available
  - [ ] 5.3.5 Implement credential sanitization
    - Replace Authorization header values with [FILTERED]
    - Replace access_token fields with [FILTERED]
    - Replace refresh_token fields with [FILTERED]
    - Replace client_secret fields with [FILTERED]
    - Replace any field matching "token", "secret", "password", "key"
  - [ ] 5.3.6 Integrate logging into HTTP client
    - Log before each request
    - Log after each response
    - Log errors with full context
    - Use configured log level
  - [ ] 5.3.7 Ensure logging tests pass
    - Run ONLY the 6-8 tests written in 5.3.1
    - Use StringIO to capture log output
    - Verify sanitization works
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- The 6-8 tests written in 5.3.1 pass
- Request and response logging works
- All credentials sanitized in logs
- Rails.logger auto-detected
- Log levels configurable

---

### 6. Client & Rails Integration

#### Task Group 6.1: Client Class
**Dependencies:** Task Group 2.1, 2.2, 4.1-4.3, 5.1-5.3
**Complexity:** Medium-High
**Deliverable:** Main Client class integrating all components

- [x] 6.1.0 Complete Client class
  - [ ] 6.1.1 Write 6-8 focused tests for Client
    - Test Client initialization with configuration
    - Test Client validates required configuration
    - Test Client merges instance config over global config
    - Test Client.authorize_url generates OAuth URL
    - Test Client.exchange_code_for_token exchanges authorization code
    - Test Client.refresh_token refreshes expired token
    - Test Client HTTP methods (get, post, patch, put, delete)
    - Test Client integrates token storage adapter
  - [ ] 6.1.2 Create lib/nationbuilder_api/client.rb
    - Define Client class
    - Accept configuration options in initializer
    - Merge instance options over global configuration
    - Validate required configuration
    - Initialize HTTP client, OAuth module, token adapter
  - [ ] 6.1.3 Implement OAuth methods
    - authorize_url(scopes:, state: nil) - generate authorization URL
    - exchange_code_for_token(code:, code_verifier:, identifier:) - token exchange
    - refresh_token(identifier) - refresh expired token
    - Delegate to OAuth module
  - [ ] 6.1.4 Implement HTTP methods
    - get(path, params: {}) - delegate to HttpClient
    - post(path, body: {}) - delegate to HttpClient
    - patch(path, body: {}) - delegate to HttpClient
    - put(path, body: {}) - delegate to HttpClient
    - delete(path) - delegate to HttpClient
  - [ ] 6.1.5 Integrate token adapter
    - Select adapter based on configuration
    - Auto-detect ActiveRecord if available, else Memory
    - Validate adapter implements required interface
    - Pass adapter to OAuth and HttpClient
  - [ ] 6.1.6 Ensure Client tests pass
    - Run ONLY the 6-8 tests written in 6.1.1
    - Verify all components integrated
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- The 6-8 tests written in 6.1.1 pass
- Client initializes with configuration
- OAuth methods work end-to-end
- HTTP methods work with authentication
- Token adapter integrated
- Configuration validation works

#### Task Group 6.2: Rails Engine Integration
**Dependencies:** Task Group 6.1
**Complexity:** Medium
**Deliverable:** Zero-config Rails integration

- [x] 6.2.0 Complete Rails Engine
  - [ ] 6.2.1 Write 4-6 focused tests for Rails Engine
    - Test Engine loads when Rails detected
    - Test Engine sets Rails.logger as default logger
    - Test Engine auto-detects ActiveRecord adapter
    - Test Engine respects Rails environment
    - Test Engine does not load in non-Rails apps
  - [ ] 6.2.2 Create lib/nationbuilder_api/engine.rb
    - Define Engine < Rails::Engine (conditional on Rails constant)
    - Isolate namespace NationbuilderApi
    - Add initializer for logger setup
    - Add initializer for adapter auto-detection
  - [ ] 6.2.3 Implement Rails.logger integration
    - Initializer: Set NationbuilderApi.logger = Rails.logger
    - Respect Rails.application.config.log_level
    - Tag logs with [NationbuilderApi]
  - [ ] 6.2.4 Implement ActiveRecord adapter auto-detection
    - Check if ActiveRecord constant defined
    - Set default token_adapter to :active_record
    - Fall back to :memory if ActiveRecord not available
  - [ ] 6.2.5 Ensure Rails Engine tests pass
    - Run ONLY the 4-6 tests written in 6.2.1
    - Use Rails test app for integration testing
    - Verify zero-config experience
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- The 4-6 tests written in 6.2.1 pass
- Engine loads only when Rails detected
- Rails.logger used automatically
- ActiveRecord adapter auto-detected
- Zero-config Rails integration works

---

### 7. Testing & Documentation

#### Task Group 7.1: Integration Tests & Coverage Review
**Dependencies:** Task Groups 1-6
**Complexity:** Medium
**Deliverable:** Complete test suite with 90%+ coverage

- [x] 7.1.0 Review tests and fill critical gaps
  - [ ] 7.1.1 Review all existing tests
    - Count total tests written in Task Groups 1-6
    - Expected: approximately 40-60 tests
    - Review test coverage report from SimpleCov
    - Identify coverage gaps
  - [ ] 7.1.2 Analyze coverage gaps for Phase 1 only
    - Focus on untested integration points
    - Identify missing end-to-end workflow tests
    - Prioritize OAuth flow, token refresh, error handling
    - Do NOT test future phase features
  - [ ] 7.1.3 Write up to 10 additional integration tests
    - Maximum 10 tests to fill critical gaps
    - Test complete OAuth flow (authorize -> exchange -> API call)
    - Test token refresh during API call
    - Test error handling across components
    - Test adapter switching (ActiveRecord, Redis, Memory)
    - Test Rails vs non-Rails initialization
    - Test configuration precedence (instance > global)
  - [ ] 7.1.4 Run complete test suite
    - Run all tests across all Ruby versions (2.7, 3.0, 3.1, 3.2, 3.3)
    - Verify 90%+ code coverage
    - Verify no real HTTP calls (WebMock enforced)
    - Verify all tests pass on CI

**Acceptance Criteria:**
- Total test count: 50-70 tests maximum
- Code coverage: 90%+ via SimpleCov
- All tests pass on Ruby 2.7-3.3
- No real HTTP calls in test suite
- Integration workflows tested end-to-end

#### Task Group 7.2: Documentation & Examples
**Dependencies:** Task Group 7.1
**Complexity:** Low-Medium
**Deliverable:** README with working examples

- [x] 7.2.0 Complete documentation
  - [ ] 7.2.1 Update README.md
    - Add gem description and features
    - Add installation instructions
    - Add quick start guide (Rails and non-Rails)
    - Add OAuth flow example with code
    - Add configuration examples (global and instance)
    - Add error handling examples
    - Add adapter configuration examples
    - Add scope constants documentation
  - [ ] 7.2.2 Add inline code documentation
    - Document all public methods with YARD format
    - Add @param, @return, @raise tags
    - Add usage examples in method docs
    - Document configuration options
  - [ ] 7.2.3 Create CHANGELOG.md
    - Add v0.1.0 entry with features
    - List all implemented features
    - Note Phase 1 scope and limitations
  - [ ] 7.2.4 Update gemspec metadata
    - Add description, summary, homepage
    - Add source_code_uri, bug_tracker_uri
    - Add changelog_uri, documentation_uri
    - Set license to MIT
  - [ ] 7.2.5 Verify examples work
    - Copy/paste examples from README into test file
    - Ensure examples run without errors
    - Verify examples follow best practices

**Acceptance Criteria:**
- README includes working code examples
- All public APIs documented with YARD
- CHANGELOG.md describes v0.1.0
- Gemspec metadata complete
- Examples verified to work

#### Task Group 7.3: Final Polish & Release Prep
**Dependencies:** Task Group 7.2
**Complexity:** Low
**Deliverable:** Ready for v0.1.0 release

- [x] 7.3.0 Prepare for release
  - [ ] 7.3.1 Run final code quality checks
    - Run `bundle exec standardrb` - ensure no violations
    - Run `bundle exec rake build` - ensure gem builds
    - Check for console.log or debugger statements
    - Verify no TODOs or FIXMEs in code
  - [ ] 7.3.2 Verify CI passes on all Ruby versions
    - Check GitHub Actions CI results
    - Ensure Ruby 2.7, 3.0, 3.1, 3.2, 3.3 all pass
    - Verify code coverage uploaded to CodeCov (if configured)
  - [ ] 7.3.3 Update version and dependencies
    - Set VERSION = "0.1.0" in lib/nationbuilder_api/version.rb
    - Review gemspec dependencies
    - Ensure version constraints are appropriate
    - Update CHANGELOG.md with release date
  - [ ] 7.3.4 Create GitHub release
    - Tag commit with v0.1.0
    - Create GitHub release with changelog
    - Attach gem file to release
  - [ ] 7.3.5 Publish to RubyGems.org
    - Run `gem build nationbuilder_api.gemspec`
    - Run `gem push nationbuilder_api-0.1.0.gem`
    - Verify gem page on RubyGems.org
    - Test installation: `gem install nationbuilder_api`

**Acceptance Criteria:**
- All code quality checks pass
- CI green on all Ruby versions
- VERSION set to 0.1.0
- Gem published to RubyGems.org
- GitHub release created with changelog

---

## Execution Order

Recommended implementation sequence:

1. **Project Setup & Foundation** (Task Group 1.1)
   - Establishes gem structure, testing infrastructure, CI

2. **Configuration & Error Foundation** (Task Groups 2.1-2.2)
   - Configuration system and error hierarchy needed by all other components

3. **Token Storage Adapters** (Task Groups 3.1-3.4)
   - Base interface, then Memory (simplest), Redis, ActiveRecord
   - Parallel implementation after base interface complete

4. **OAuth 2.0 with PKCE** (Task Groups 4.1-4.3)
   - PKCE implementation, token exchange, token refresh
   - Sequential: authorization -> exchange -> refresh

5. **HTTP Client & Logging** (Task Groups 5.1-5.3)
   - HTTP client, error handling middleware, logging
   - Sequential: client -> errors -> logging

6. **Client & Rails Integration** (Task Groups 6.1-6.2)
   - Main Client class integrating all components
   - Rails Engine for automatic Rails integration

7. **Testing & Documentation** (Task Groups 7.1-7.3)
   - Integration tests, documentation, release preparation
   - Sequential: tests -> docs -> release

## Key Milestones

**Milestone 1: Foundation Complete** (After Task Group 2.2)
- Gem builds and tests run
- Configuration system works
- Error hierarchy defined

**Milestone 2: Storage Complete** (After Task Group 3.4)
- All three token adapters functional
- Adapter auto-detection works

**Milestone 3: OAuth Complete** (After Task Group 4.3)
- Authorization URL generation works
- Token exchange works
- Token refresh works

**Milestone 4: HTTP Client Complete** (After Task Group 5.3)
- HTTP client makes authenticated requests
- Error handling works
- Logging works with sanitization

**Milestone 5: Integration Complete** (After Task Group 6.2)
- Main Client class works end-to-end
- Rails integration zero-config

**Milestone 6: v0.1.0 Release Ready** (After Task Group 7.3)
- 90%+ test coverage
- Documentation complete
- Published to RubyGems.org

## Important Notes

- **Test-driven approach**: Each task group starts with writing focused tests (2-8 tests) and ends with running ONLY those tests
- **No exhaustive testing during development**: Tests should cover critical behaviors, not every edge case
- **Final test review**: Task Group 7.1 adds maximum 10 additional tests to fill critical gaps
- **Total test budget**: 50-70 tests maximum for Phase 1
- **Reference architecture**: Follow Pay gem patterns for module structure, adapters, and Rails integration
- **OAuth security**: PKCE-only implementation (no traditional flow)
- **Credential safety**: All logs must sanitize tokens and secrets
- **Ruby compatibility**: Test on Ruby 2.7, 3.0, 3.1, 3.2, 3.3
- **Phase 1 scope**: Core infrastructure only - no API resources (People, Donations, etc.)
- **ActiveRecord note**: Phase 1 provides adapter interface only. Model/migration generation deferred to Phase 4.

## Success Criteria Summary

- OAuth 2.0 flow works end-to-end (authorization -> token -> API access)
- All three token adapters functional (ActiveRecord, Redis, Memory)
- Error hierarchy complete with retryable? logic
- 90%+ test coverage with 50-70 tests maximum
- Rails applications integrate with zero configuration
- Credential sanitization prevents token leaks in logs
- Tests pass on Ruby 2.7-3.3
- Gem published to RubyGems.org as v0.1.0
