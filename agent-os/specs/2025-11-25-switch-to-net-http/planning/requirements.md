# Spec Requirements: Switch to Net::HTTP

## Initial Description

Switch NationBuilder API Gem from http gem to Net::HTTP

The nationbuilder_api gem currently uses two different HTTP libraries:
- Net::HTTP for OAuth token exchange (working correctly with SSL configuration)
- http gem for API requests (having SSL configuration issues)

We need to standardize on Net::HTTP for consistency and reliability.

## Requirements Discussion

### First Round Questions

**Q1: Response Object Compatibility - The code expects specific response methods like response.status (integer), response.status.code (integer), response.headers.to_h, and response.body.to_s. Should we create a wrapper object to maintain this interface, or update all calling code?**

**Answer:** Create a wrapper object to maintain interface compatibility. The code expects:
- response.status (integer) - line 57 shows response.status passed to logger
- response.status.code (integer) - line 140 shows response.status.code
- response.headers.to_h - line 57
- response.body.to_s - lines 57, 161

Solution: Create a simple wrapper class that adapts Net::HTTP responses to match the expected interface.

**Q2: Error Handling - Should we keep the existing rescue clause (HTTP::Error, SocketError, OpenSSL::SSL::SSLError) and add Net::HTTP-specific errors, or completely replace it?**

**Answer:** Keep current rescue clause but add Net::HTTP errors:
```ruby
rescue HTTP::Error, Net::OpenTimeout, Net::ReadTimeout, SocketError, OpenSSL::SSL::SSLError, Errno::ECONNREFUSED => e
```
Remove HTTP::Error after testing confirms Net::HTTP errors are caught.

**Q3: JSON Request Body Handling - Net::HTTP doesn't have a json: parameter like the http gem. Should we manually serialize the body with JSON.generate and set Content-Type header?**

**Answer:** Yes, correct. Manually serialize with `request.body = JSON.generate(body)` and set `request["Content-Type"] = "application/json"` in execute_request.

**Q4: Query Parameter Handling - For GET requests with params, should we append them to the URI manually using URI.encode_www_form?**

**Answer:** Yes, append manually:
```ruby
if params.any?
  uri.query = URI.encode_www_form(params)
end
```

**Q5: Timeout Configuration - Should we use the configured config.timeout value (line 65) or a different approach for Net::HTTP timeouts?**

**Answer:** Use config.timeout (line 65 shows this is the intended behavior). OAuth uses 30 as hardcoded, but HttpClient should respect the configured value for flexibility.

**Q6: Response Body Access - Should we always call .to_s on response.body for consistency (as done on line 161), or is this unnecessary with Net::HTTP?**

**Answer:** Keep .to_s for safety (line 161 uses it). It's defensive programming and doesn't hurt.

**Q7: SSL Context Approach - Should we follow oauth.rb's simpler approach of directly setting http.verify_mode = OpenSSL::SSL::VERIFY_NONE, or use the SSLContext wrapper pattern from the current code?**

**Answer:** Follow oauth.rb's simpler approach:
```ruby
http.verify_mode = OpenSSL::SSL::VERIFY_NONE
```
No need for SSLContext wrapper - direct assignment is cleaner.

**Q8: Test Coverage - Are there existing tests for HttpClient that should still pass after this change?**

**Answer:** Check for tests in `/Users/bmc/Code/Active/Ruby/nationbuilder_api/spec/` - if tests exist, they should still pass. If not, tests are out of scope for this change.

**Q9: Scope Boundaries - To confirm, we're ONLY modifying lib/nationbuilder_api/http_client.rb and nationbuilder_api.gemspec. No changes to tests, documentation, or dependent code, correct?**

**Answer:** Correct - ONLY modify:
- lib/nationbuilder_api/http_client.rb
- nationbuilder_api.gemspec
- No tests, docs, or dependent code in this spec

**Q10: Existing Code Reuse - Are there other files in the codebase with similar Net::HTTP patterns we should reference besides oauth.rb?**

**Answer:** Only oauth.rb (lines 138-155) - it's the reference pattern. No other files needed.

### Existing Code to Reference

**Similar Features Identified:**
- Feature: OAuth Token Exchange - Path: `lib/nationbuilder_api/oauth.rb`
- Method to reference: `make_token_request` (lines 138-155)
- Pattern demonstrates:
  - Net::HTTP instance creation: `Net::HTTP.new(uri.host, uri.port)`
  - SSL configuration: `http.use_ssl = true`
  - Timeout settings: `http.read_timeout = 30` and `http.open_timeout = 30`
  - Development/test SSL verification bypass: `http.verify_mode = OpenSSL::SSL::VERIFY_NONE`
  - Request creation and execution: `request = Net::HTTP::Post.new(uri)` then `http.request(request)`

### Follow-up Questions

No follow-up questions were needed. User provided comprehensive technical details in initial answers.

## Visual Assets

### Files Provided:
No visual assets provided.

### Visual Insights:
Not applicable - this is a technical refactoring of HTTP library dependencies. No UI or visual components involved.

## Requirements Summary

### Functional Requirements

**Core HTTP Operations:**
- Replace http gem with Net::HTTP for all API requests (GET, POST, PATCH, PUT, DELETE)
- Maintain identical external interface - all method signatures remain unchanged
- Preserve existing error handling behavior with enhanced Net::HTTP error coverage
- Continue supporting configurable timeouts via config.timeout
- Maintain request/response logging with same data structure

**Response Interface Compatibility:**
- Create ResponseWrapper class to adapt Net::HTTP responses to expected interface
- Provide response.status that returns ResponseStatus object
- ResponseStatus.code returns integer status code
- ResponseStatus.to_i returns integer status code
- Provide response.headers as hash
- Provide response.body as string

**Request Handling:**
- GET requests: Append query parameters using URI.encode_www_form
- POST/PATCH/PUT requests: Manually serialize JSON body and set Content-Type header
- DELETE requests: No body required
- All requests: Apply configured timeout values
- All requests: Set standard headers (Accept, Content-Type, User-Agent, Authorization)

**SSL Configuration:**
- Enable SSL for all HTTPS connections
- Disable SSL verification in Rails development and test environments only
- Use simple direct assignment approach: `http.verify_mode = OpenSSL::SSL::VERIFY_NONE`
- Follow pattern established in oauth.rb (lines 146-148)

**Error Handling:**
- Catch Net::OpenTimeout, Net::ReadTimeout for timeout scenarios
- Catch SocketError for network connectivity issues
- Catch OpenSSL::SSL::SSLError for SSL/TLS problems
- Catch Errno::ECONNREFUSED for connection failures
- Temporarily keep HTTP::Error in rescue clause, remove after testing confirms Net::HTTP errors work
- Wrap all errors in NetworkError with descriptive message including HTTP method and path

### Reusability Opportunities

**Code Patterns from oauth.rb:**
- Net::HTTP instance creation and configuration (lines 139-148)
- Request object creation pattern (line 150)
- Form data vs JSON body handling (line 152 shows form data, adapt for JSON)
- Response execution pattern (line 154)
- Success/failure response checking (line 158 uses Net::HTTPSuccess)

**No additional components identified** - HttpClient is self-contained and oauth.rb provides all needed reference patterns.

### Scope Boundaries

**In Scope:**
- Modify `lib/nationbuilder_api/http_client.rb`:
  - Replace http gem require with Net::HTTP and URI requires
  - Add ResponseWrapper and ResponseStatus classes
  - Rewrite execute_request method to use Net::HTTP
  - Update error rescue clause to include Net::HTTP errors
  - Update handle_response to work with wrapped responses
- Modify `nationbuilder_api.gemspec`:
  - Remove `spec.add_dependency "http", "~> 5.0"` line

**Out of Scope:**
- Test file modifications (tests should continue passing without changes)
- Documentation updates
- Changes to other files in the codebase
- Changes to oauth.rb (already uses Net::HTTP correctly)
- Client.rb or other dependent files
- README or changelog updates
- Adding new features or capabilities
- Performance optimization beyond maintaining current behavior

### Technical Considerations

**Integration Points:**
- HttpClient is called by Client class for all API operations
- Logger expects same response structure (status integer, headers hash, body string)
- OAuth module expects token_adapter interface remains unchanged
- Error classes expect response object with body and code methods

**Existing System Constraints:**
- Must maintain Ruby 2.7+ compatibility
- Must work with both standalone Ruby and Rails applications
- Must respect Rails environment detection for SSL configuration
- Must preserve configurable timeout values from Configuration object
- Must maintain existing exception hierarchy (NetworkError, AuthenticationError, etc.)

**Technology Preferences:**
- Use standard library Net::HTTP (already required by oauth.rb)
- Follow Ruby stdlib conventions for Net::HTTP usage
- Minimize external dependencies (removing http gem dependency)
- Use URI module for URL and query parameter handling

**Similar Code Patterns to Follow:**
- OAuth.make_token_request (lines 138-155) - primary reference implementation
- Net::HTTP configuration: set use_ssl, timeouts, and verify_mode on http instance
- Request creation: Use Net::HTTP::Get, Net::HTTP::Post, etc. classes
- Header setting: Use request["Header-Name"] = value syntax
- Response checking: Use response.is_a?(Net::HTTPSuccess) for 2xx status codes
- Error extraction: Access response.code and response.body directly

**Response Wrapper Implementation Specification:**
```ruby
# Simple wrapper to maintain interface compatibility
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

**Key Implementation Details:**
- ResponseWrapper.headers uses to_hash to convert Net::HTTP headers to hash
- ResponseWrapper.body returns string directly from net_http_response.body
- ResponseStatus.code returns integer (converted from string via to_i)
- ResponseStatus provides to_i for compatibility where status is treated as integer
- Wrapper classes defined within HttpClient class scope
- Net::HTTP response.code is a string, must convert to integer for status codes
