# Specification: Switch to Net::HTTP

## Goal

Replace the http gem dependency with Ruby's standard library Net::HTTP to resolve SSL configuration issues and standardize HTTP client implementation across the gem. This change eliminates dependency on an external HTTP library while maintaining complete backward compatibility.

## User Stories

- As a gem maintainer, I want to use only standard library HTTP clients so that I can reduce external dependencies and simplify SSL configuration
- As a developer using the gem, I want all API requests to work identically after the change so that my application continues functioning without modifications
- As a developer in development/test environments, I want SSL verification to be disabled automatically so that I can work with local or test NationBuilder instances

## Core Requirements

### HTTP Method Support
- Support all existing HTTP methods: GET, POST, PATCH, PUT, DELETE
- Maintain identical method signatures for all public methods
- Preserve existing URL building logic (handle paths with/without leading slash, base URLs with/without trailing slash)
- Support query parameters for GET requests
- Support JSON request bodies for POST, PATCH, and PUT requests

### Response Interface Compatibility
- Create ResponseWrapper class to adapt Net::HTTP responses to the interface expected by existing code
- Support response.status returning an object with code attribute
- Support response.status.code returning integer status code
- Support response.headers.to_h returning hash of response headers
- Support response.body.to_s returning response body as string

### Error Handling
- Catch Net::OpenTimeout and Net::ReadTimeout for timeout scenarios
- Catch SocketError for network connectivity issues
- Catch OpenSSL::SSL::SSLError for SSL/TLS problems
- Catch Errno::ECONNREFUSED for connection failures
- Wrap all errors in NetworkError with descriptive message
- Maintain existing HTTP status code to error class mapping (401 -> AuthenticationError, 403 -> AuthorizationError, 404 -> NotFoundError, 422 -> ValidationError, 429 -> RateLimitError, 500-599 -> ServerError)

### SSL Configuration
- Enable SSL for all HTTPS connections
- Disable SSL verification only in Rails development and test environments
- Use simple direct assignment: `http.verify_mode = OpenSSL::SSL::VERIFY_NONE`
- Follow the pattern established in oauth.rb

### Timeout Configuration
- Use config.timeout value for both read_timeout and open_timeout
- Apply timeouts to all HTTP requests

### Logging
- Maintain existing request logging with method, URL, headers, and body
- Maintain existing response logging with status, duration, headers, and body
- Ensure response object passed to logger matches expected interface

## Reusable Components

### Existing Code to Leverage

**OAuth Module Pattern (lib/nationbuilder_api/oauth.rb, lines 138-155):**
- Net::HTTP instance creation: `Net::HTTP.new(uri.host, uri.port)`
- SSL configuration: `http.use_ssl = true`
- Timeout settings: `http.read_timeout = 30` and `http.open_timeout = 30`
- Development/test SSL bypass: `http.verify_mode = OpenSSL::SSL::VERIFY_NONE`
- Request creation: `request = Net::HTTP::Post.new(uri)`
- Header setting: `request["Header-Name"] = value`
- Request execution: `http.request(request)`
- Response checking: `response.is_a?(Net::HTTPSuccess)` for 2xx status codes

### New Components Required

**ResponseWrapper Class:**
- Adapts Net::HTTPResponse to match http gem response interface
- Required because existing code expects specific response methods
- Cannot reuse oauth.rb pattern because OAuth directly checks Net::HTTPSuccess

**ResponseStatus Class:**
- Provides code attribute and to_i method for status codes
- Required because existing code calls response.status.code
- Cannot reuse existing code because Net::HTTPResponse.code is a string, not an object

## Technical Approach

### File Modifications

**lib/nationbuilder_api/http_client.rb:**
1. Replace `require "http"` with `require "net/http"` and `require "uri"`
2. Add ResponseWrapper and ResponseStatus classes inside HttpClient class
3. Rewrite execute_request method to use Net::HTTP following oauth.rb pattern
4. Update error rescue clause to include Net::HTTP-specific errors
5. Ensure handle_response works with wrapped responses

**nationbuilder_api.gemspec:**
1. Remove line 36: `spec.add_dependency "http", "~> 5.0"`

### ResponseWrapper Implementation

```ruby
# Wrapper class to maintain interface compatibility with http gem responses
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

# Wrapper for response status to provide code attribute
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

### execute_request Method Implementation Pattern

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

### Error Handling Update

```ruby
rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, OpenSSL::SSL::SSLError, Errno::ECONNREFUSED => e
  raise NetworkError.new("Network error for #{method.upcase} #{path}: #{e.message}", response: nil)
```

## Testing Approach

### Automated Tests
- All existing tests in spec/nationbuilder_api/http_client_spec.rb must pass without modification
- Tests use WebMock to stub HTTP requests, which works with Net::HTTP
- Test coverage includes:
  - GET requests with query parameters
  - POST/PATCH/PUT requests with JSON bodies
  - DELETE requests
  - All error scenarios (401, 403, 404, 422, 429, 500-599)
  - Network timeout errors
  - URL building edge cases
  - User-Agent header format
  - Non-JSON response handling

### Manual Testing
After implementation, verify in test application:
1. Restart Rails server in test app
2. Test OAuth login flow at /sessions/brettmchargue/new
3. Verify successful authentication and redirect to dashboard
4. Check logs for successful API call: `[NationbuilderApi] GET https://brettmchargue.nationbuilder.com/api/v2/people/me`
5. Verify response contains expected user data

## Out of Scope

- Test file modifications (existing tests should pass without changes)
- Documentation updates (README, CHANGELOG)
- Changes to other files beyond http_client.rb and gemspec
- Changes to oauth.rb (already uses Net::HTTP correctly)
- Changes to client.rb or other dependent files
- Performance optimization beyond maintaining current behavior
- Adding new features or capabilities
- Modifying error class definitions
- Updating logger implementation

## Success Criteria

### Functional Requirements Met
- All HTTP methods (GET, POST, PATCH, PUT, DELETE) execute successfully
- Query parameters are properly encoded and sent with GET requests
- JSON request bodies are properly serialized for POST/PATCH/PUT requests
- Response status codes are correctly interpreted (2xx, 4xx, 5xx)
- All custom error classes are raised for appropriate status codes
- Network errors are caught and wrapped in NetworkError
- SSL verification is disabled in development/test environments
- Timeouts are applied using configured values

### Code Quality
- http gem dependency removed from gemspec
- All existing tests pass without modification
- ResponseWrapper classes maintain clean interface compatibility
- Code follows patterns established in oauth.rb
- No new external dependencies added

### Integration Testing
- OAuth login flow completes successfully in test application
- API calls to /api/v2/people/me return expected data
- Request/response logging shows correct data structure
- No SSL verification errors in development environment
- Application behavior is identical to pre-refactoring state

### Performance
- Request execution time remains comparable to http gem implementation
- Memory usage does not significantly increase
- No new timeout or connection issues introduced
