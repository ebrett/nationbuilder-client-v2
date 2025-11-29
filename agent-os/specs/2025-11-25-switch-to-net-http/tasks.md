# Task Breakdown: Switch to Net::HTTP

## Overview
Total Tasks: 16 tasks across 3 implementation groups + 1 verification group

**Goal:** Replace http gem with Net::HTTP to resolve SSL configuration issues and eliminate external HTTP dependency while maintaining complete backward compatibility.

**Key Files:**
- `lib/nationbuilder_api/http_client.rb` - Complete HTTP client refactoring
- `nationbuilder_api.gemspec` - Remove http gem dependency

## Task List

### Backend Engineering: Response Interface Layer

#### Task Group 1: Response Wrapper Classes
**Dependencies:** None

- [x] 1.0 Create response wrapper infrastructure
  - [x] 1.1 Write 2-6 focused tests for response wrapper classes
    - Test ResponseWrapper.status returns ResponseStatus object
    - Test ResponseWrapper.status.code returns integer status code
    - Test ResponseWrapper.headers returns hash (using to_hash)
    - Test ResponseWrapper.body returns string
    - Test ResponseStatus.to_i returns integer
    - Test that wrapper properly adapts Net::HTTPResponse interface
  - [x] 1.2 Add ResponseWrapper class to HttpClient
    - Location: Inside `NationbuilderApi::HttpClient` class (after `initialize` method)
    - Attributes: `body`, `headers`, `net_http_response`
    - Implementation pattern:
      ```ruby
      class ResponseWrapper
        attr_reader :body, :headers, :net_http_response

        def initialize(net_http_response)
          @net_http_response = net_http_response
          @body = net_http_response.body
          @headers = net_http_response.to_hash
        end

        def status
          ResponseStatus.new(@net_http_response.code.to_i)
        end
      end
      ```
    - Purpose: Adapts Net::HTTPResponse to match http gem interface
    - Key detail: Use `to_hash` not `to_h` for Net::HTTPResponse headers
  - [x] 1.3 Add ResponseStatus class to HttpClient
    - Location: Inside `NationbuilderApi::HttpClient` class (after ResponseWrapper)
    - Attributes: `code`
    - Implementation pattern:
      ```ruby
      class ResponseStatus
        attr_reader :code

        def initialize(code)
          @code = code
        end

        def to_i
          @code
        end
      end
      ```
    - Purpose: Provides status.code interface expected by existing code
    - Key detail: Net::HTTPResponse.code is a string, must convert to integer
  - [x] 1.4 Ensure response wrapper tests pass
    - Run ONLY the 2-6 tests written in 1.1
    - Verify status.code returns correct integer
    - Verify headers.to_h works correctly
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- ResponseWrapper and ResponseStatus classes defined within HttpClient class
- The 2-6 tests written in 1.1 pass
- Wrapper classes maintain interface compatibility with http gem responses
- All attributes are properly initialized from Net::HTTPResponse

### Backend Engineering: HTTP Client Core

#### Task Group 2: Net::HTTP Implementation
**Dependencies:** Task Group 1 (needs response wrapper classes) - COMPLETED

- [x] 2.0 Replace http gem with Net::HTTP
  - [x] 2.1 Write 2-8 focused tests for HTTP client methods
    - Test GET request with query parameters
    - Test POST request with JSON body
    - Test PATCH request with JSON body
    - Test PUT request with JSON body
    - Test DELETE request (no body)
    - Test timeout configuration applied to requests
    - Test SSL verification disabled in Rails dev/test environments
    - Test that responses are properly wrapped
  - [x] 2.2 Update require statements in http_client.rb
    - Remove: `require "http"` (line 3)
    - Add: `require "net/http"` (if not already present)
    - Add: `require "uri"` (if not already present)
    - Keep: `require "json"` (line 4)
    - Reference: See oauth.rb lines 6-8 for Net::HTTP requires
  - [x] 2.3 Rewrite execute_request method using Net::HTTP
    - Location: Lines 64-88 in current implementation
    - Follow pattern from oauth.rb lines 138-155
    - Implementation steps:
      1. Parse URL into URI object: `uri = URI(url)`
      2. Add query parameters for GET: `uri.query = URI.encode_www_form(params) if method == :get && params.any?`
      3. Create Net::HTTP instance: `http = Net::HTTP.new(uri.host, uri.port)`
      4. Configure SSL: `http.use_ssl = true`
      5. Set timeouts: `http.read_timeout = config.timeout` and `http.open_timeout = config.timeout`
      6. Disable SSL verification in dev/test: `http.verify_mode = OpenSSL::SSL::VERIFY_NONE if defined?(Rails) && (Rails.env.development? || Rails.env.test?)`
      7. Create request object based on method: `Net::HTTP::Get.new(uri)`, `Net::HTTP::Post.new(uri)`, etc.
      8. Set headers: `headers.each { |key, value| request[key] = value }`
      9. Set body for POST/PATCH/PUT: `request.body = JSON.generate(body)` and `request["Content-Type"] = "application/json"`
      10. Execute request: `response = http.request(request)`
      11. Wrap response: `ResponseWrapper.new(response)`
    - Key detail: Follow oauth.rb pattern exactly for Net::HTTP configuration
    - Return: ResponseWrapper instance
  - [x] 2.4 Update error handling for Net::HTTP exceptions
    - Location: Line 60 rescue clause
    - Current: `rescue HTTP::Error, SocketError, OpenSSL::SSL::SSLError => e`
    - Updated: `rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, OpenSSL::SSL::SSLError, Errno::ECONNREFUSED => e`
    - Remove HTTP::Error after confirming Net::HTTP errors work
    - Keep error message format: `"Network error for #{method.upcase} #{path}: #{e.message}"`
  - [x] 2.5 Verify handle_response compatibility with wrapped responses
    - Location: Lines 137-158
    - Ensure `response.status.code` works with ResponseWrapper (line 140)
    - Ensure error classes receive proper response object
    - No changes should be needed if ResponseWrapper is correct
  - [x] 2.6 Ensure HTTP client tests pass
    - Run ONLY the 2-8 tests written in 2.1
    - Verify all HTTP methods work correctly
    - Verify timeout configuration applied
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 2.1 pass
- All HTTP methods (GET, POST, PATCH, PUT, DELETE) work correctly
- Query parameters properly encoded for GET requests
- JSON bodies properly serialized for POST/PATCH/PUT
- Timeouts applied using config.timeout value
- SSL verification disabled in Rails dev/test environments
- All responses properly wrapped in ResponseWrapper
- Error handling catches all Net::HTTP exceptions

**Implementation Reference:**
```ruby
def execute_request(method, url, headers:, params:, body:)
  uri = URI(url)

  # Add query parameters for GET requests
  if method == :get && params.any?
    uri.query = URI.encode_www_form(params)
  end

  # Create and configure HTTP client
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.read_timeout = config.timeout
  http.open_timeout = config.timeout

  # Disable SSL verification in development/test environments
  if defined?(Rails) && (Rails.env.development? || Rails.env.test?)
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end

  # Create request object based on method
  request = case method
  when :get
    Net::HTTP::Get.new(uri)
  when :post
    Net::HTTP::Post.new(uri)
  when :patch
    Net::HTTP::Patch.new(uri)
  when :put
    Net::HTTP::Put.new(uri)
  when :delete
    Net::HTTP::Delete.new(uri)
  else
    raise ArgumentError, "Unsupported HTTP method: #{method}"
  end

  # Set headers
  headers.each { |key, value| request[key] = value }

  # Set body for POST/PATCH/PUT requests
  if body && [:post, :patch, :put].include?(method)
    request.body = JSON.generate(body)
    request["Content-Type"] = "application/json"
  end

  # Execute request and wrap response
  response = http.request(request)
  ResponseWrapper.new(response)
end
```

### Dependency Management

#### Task Group 3: Gemspec Update
**Dependencies:** Task Groups 1-2 (HTTP client must work before removing dependency) - COMPLETED

- [x] 3.0 Remove http gem dependency
  - [x] 3.1 Write 2-4 focused tests for gem dependencies
    - Test that gem loads successfully without http gem
    - Test that HttpClient can be instantiated
    - Test that a simple API request works (integration test)
    - Test that oauth.rb still works (uses Net::HTTP)
  - [x] 3.2 Remove http gem from gemspec
    - File: `nationbuilder_api.gemspec`
    - Remove line 36: `spec.add_dependency "http", "~> 5.0"`
    - Keep other dependencies: base64, logger
    - No other changes needed
  - [x] 3.3 Ensure dependency tests pass
    - Run ONLY the 2-4 tests written in 3.1
    - Verify gem loads without http gem
    - Verify basic functionality works
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- The 2-4 tests written in 3.1 pass
- http gem dependency removed from gemspec
- Gem loads successfully without http gem
- No references to http gem remain in codebase

### Testing & Verification

#### Task Group 4: Comprehensive Test Verification
**Dependencies:** Task Groups 1-3 (all implementation complete) - COMPLETED

- [x] 4.0 Verify all existing tests pass and fill critical gaps
  - [x] 4.1 Review tests from Task Groups 1-3
    - Review the 8 tests written for response wrappers (Task 1.1)
    - Review the 7 tests written for HTTP client (Task 2.1)
    - Review the 4 tests written for dependencies (Task 3.1)
    - Total feature-specific tests: 19 tests
  - [x] 4.2 Run all existing RSpec tests for http_client
    - Command: `bundle exec rspec spec/nationbuilder_api/http_client_spec.rb`
    - All 12 existing tests pass WITHOUT modification
    - Tests use WebMock which works with Net::HTTP
    - Coverage verified:
      - GET requests with query parameters
      - POST/PATCH/PUT requests with JSON bodies
      - DELETE requests
      - Error scenarios (401, 403, 404, 422, 429, 500-599)
      - Network timeout errors
      - URL building edge cases
      - User-Agent header format
      - Non-JSON response handling
  - [x] 4.3 Analyze test coverage gaps specific to Net::HTTP changes
    - Identified critical gaps:
      - SSL verification disabled in Rails.env.development? - NOT tested
      - SSL verification disabled in Rails.env.test? - NOT tested
      - SSL verification NOT disabled in Rails.env.production? - NOT tested
    - Already covered:
      - Timeout configuration is tested
      - Response wrapper interface is tested
      - Error handling for Net::HTTP-specific exceptions is tested
  - [x] 4.4 Write up to 5 additional strategic tests maximum (if needed)
    - Added 3 strategic tests to fill critical SSL verification gaps:
      1. SSL verification disabled in Rails development environment
      2. SSL verification disabled in Rails test environment
      3. SSL verification NOT disabled in Rails production environment
    - All 3 new tests pass
    - Tests use mocking to verify Net::HTTP SSL configuration
    - Total new tests: 3 (within the 5 test maximum)
  - [x] 4.5 Run complete test suite for HttpClient
    - Total tests passing: 34 tests
      - 8 response wrapper tests
      - 10 Net::HTTP implementation tests (7 original + 3 new SSL tests)
      - 4 gem dependency tests
      - 12 existing http_client tests
    - All tests pass successfully
    - Test execution time: ~0.03-0.04 seconds
  - [x] 4.6 Prepare manual integration testing documentation
    - Created comprehensive manual test plan: `agent-os/specs/2025-11-25-switch-to-net-http/manual-integration-test-plan.md`
    - Document includes:
      - Step-by-step testing instructions
      - Expected results for each step
      - Success criteria checklist
      - Troubleshooting guide
      - Test results template
    - Manual testing to be performed by user in real Rails application

**Acceptance Criteria:**
- [x] All existing RSpec tests pass without modification (12 tests)
- [x] All feature-specific tests pass (19 tests from Task Groups 1-3)
- [x] 3 additional tests added to fill SSL verification gaps (within 5 test maximum)
- [x] Total test count: 34 tests (12 existing + 19 feature + 3 new)
- [x] Manual integration test plan documented and ready for user execution
- [ ] OAuth login flow works in test application (requires user to execute manual tests)
- [ ] API call to /api/v2/people/me succeeds (requires user to execute manual tests)
- [ ] No SSL verification errors in development environment (requires user to execute manual tests)
- [ ] Request/response logging shows correct data structure (requires user to execute manual tests)
- [ ] Application behavior identical to pre-refactoring state (requires user to execute manual tests)

**Test Summary:**
- **Response Wrapper Tests:** 8 tests passing
- **Net::HTTP Implementation Tests:** 10 tests passing (includes 3 SSL verification tests)
- **Gem Dependency Tests:** 4 tests passing
- **Existing HttpClient Tests:** 12 tests passing
- **Total Automated Tests:** 34 tests passing
- **Manual Integration Tests:** Documented, awaiting user execution

## Execution Order

Recommended implementation sequence:
1. **Response Interface Layer** (Task Group 1) - Foundation classes needed by HTTP client - COMPLETED
2. **HTTP Client Core** (Task Group 2) - Main refactoring work using response wrappers - COMPLETED
3. **Dependency Management** (Task Group 3) - Remove http gem after client works - COMPLETED
4. **Testing & Verification** (Task Group 4) - Comprehensive validation - COMPLETED

## Key Technical Constraints

### Interface Compatibility Requirements
- **Existing code expects:** `response.status.code` returning integer
- **Existing code expects:** `response.headers.to_h` returning hash
- **Existing code expects:** `response.body.to_s` returning string
- **Solution:** ResponseWrapper adapts Net::HTTPResponse to match this interface

### Net::HTTP vs http gem Differences
| Aspect | http gem | Net::HTTP | Solution |
|--------|----------|-----------|----------|
| Response status | `response.status` (integer) | `response.code` (string) | ResponseStatus wrapper with code attribute |
| Headers | `response.headers.to_h` | `response.to_hash` | ResponseWrapper.headers = to_hash |
| Timeout | `.timeout(seconds)` | `.read_timeout=` and `.open_timeout=` | Set both timeouts from config |
| JSON body | `.post(url, json: body)` | `.body = JSON.generate(body)` | Manual serialization |
| Query params | `.get(url, params: params)` | `uri.query = URI.encode_www_form(params)` | Manual encoding |
| SSL config | `.with_socket_options(ssl_context:)` | `.verify_mode = OpenSSL::SSL::VERIFY_NONE` | Direct assignment (simpler) |

### Reference Implementation
- **Primary pattern:** `lib/nationbuilder_api/oauth.rb` lines 138-155
- **Net::HTTP setup:** Lines 139-148 show configuration pattern
- **Request execution:** Lines 150-154 show request creation and execution
- **Response checking:** Line 158 shows success checking with Net::HTTPSuccess

### Critical Success Factors
1. **Zero interface changes** - All public methods maintain exact same signatures
2. **Complete error handling** - Catch all Net::HTTP exception types
3. **SSL configuration** - Must disable verification in dev/test to match oauth.rb behavior
4. **Test compatibility** - WebMock works with Net::HTTP, existing tests should pass unchanged
5. **Logging compatibility** - Response wrapper must support all logging method calls

## Out of Scope

The following are explicitly NOT included in this implementation:
- Modifications to test files (tests should pass without changes)
- Documentation updates (README, CHANGELOG)
- Changes to files other than http_client.rb and gemspec
- Changes to oauth.rb (already uses Net::HTTP correctly)
- Changes to client.rb or other dependent files
- Performance optimization beyond current behavior
- Adding new features or capabilities
- Modifying error class definitions
- Updating logger implementation
- Comprehensive test coverage expansion (only critical gaps)

## Notes

- **WebMock compatibility:** The existing test suite uses WebMock which works with both http gem and Net::HTTP, so tests should pass without modification
- **Rails environment detection:** Use `defined?(Rails) && (Rails.env.development? || Rails.env.test?)` pattern from oauth.rb
- **Timeout values:** Use `config.timeout` for both read_timeout and open_timeout (oauth.rb hardcodes 30, but HttpClient should be configurable)
- **Response body safety:** Keep `.to_s` calls on response.body for defensive programming (line 161)
- **Error message format:** Maintain exact same error message format for NetworkError
- **Status code checking:** Keep same case statement logic in handle_response (lines 140-156)
