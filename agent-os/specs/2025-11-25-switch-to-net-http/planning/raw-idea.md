# Spec Description

Switch NationBuilder API Gem from http gem to Net::HTTP

## Context

The nationbuilder_api gem currently uses two different HTTP libraries:
- Net::HTTP for OAuth token exchange (working correctly with SSL configuration)
- http gem for API requests (having SSL configuration issues)

We need to standardize on Net::HTTP for consistency and reliability.

## Files to Modify

Located in /Users/bmc/Code/Active/Ruby/nationbuilder_api/:

1. lib/nationbuilder_api/http_client.rb - Main HTTP client for API requests
2. nationbuilder_api.gemspec - Remove http gem dependency
3. lib/nationbuilder_api/oauth.rb - Already uses Net::HTTP (reference for patterns)

## Requirements

### 1. Update HttpClient class

File: lib/nationbuilder_api/http_client.rb

Current behavior using http gem:
- Makes GET/POST/PATCH/PUT/DELETE requests
- Uses HTTP.timeout().headers() chain
- Returns response with .status, .headers, .body

New behavior using Net::HTTP:
- Replace all http gem usage with Net::HTTP
- Follow the same pattern as oauth.rb (lines 138-155) for:
  - Creating Net::HTTP instances
  - Configuring SSL (disable verification in development/test)
  - Setting timeouts
  - Making requests
- Preserve all existing method signatures and return values
- Handle response status codes consistently

SSL Configuration (critical):
```ruby
# In development/test only
if defined?(Rails) && (Rails.env.development? || Rails.env.test?)
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
end
```

### 2. Update gemspec

File: nationbuilder_api.gemspec

Remove the http gem dependency:
```ruby
# Remove this line:
spec.add_dependency "http", "~> 5.0"
```

### 3. Update requires

File: lib/nationbuilder_api/http_client.rb

Change:
```ruby
require "http"  # Remove
require "net/http"  # Add
require "uri"  # Add if needed
```

## Implementation Notes

1. Reference the working OAuth implementation in oauth.rb (method make_token_request, lines 138-155) as a pattern
2. Response handling: Net::HTTP responses differ from http gem:
   - http gem: response.status.code, response.status.success?
   - Net::HTTP: response.code, response.is_a?(Net::HTTPSuccess)
3. Request methods:
   - GET: Net::HTTP::Get.new(uri)
   - POST: Net::HTTP::Post.new(uri) with request.body = json
   - PATCH: Net::HTTP::Patch.new(uri)
   - PUT: Net::HTTP::Put.new(uri)
   - DELETE: Net::HTTP::Delete.new(uri)
4. Headers: Set headers on request object:
   ```ruby
   request["Authorization"] = "Bearer #{token}"
   request["Content-Type"] = "application/json"
   ```
5. Preserve error handling: Keep catching HTTP::Error, SocketError, OpenSSL::SSL::SSLError
   - Update HTTP::Error to appropriate Net::HTTP errors

## Testing

After changes:
1. Restart Rails server in the main app
2. Test OAuth login flow at /sessions/brettmchargue/new
3. Verify it completes successfully and redirects to dashboard
4. Check logs for successful API call: [NationbuilderApi] GET https://brettmchargue.nationbuilder.com/api/v2/people/me

## Acceptance Criteria

- http gem dependency removed from gemspec
- HttpClient uses Net::HTTP exclusively
- SSL verification disabled in development/test environments
- All HTTP methods (GET/POST/PATCH/PUT/DELETE) work correctly
- OAuth login flow completes successfully
- User profile fetch (/people/me) succeeds
- Error handling preserved
- Logging still works

## Context for New Instance

Current branch: nationbuilder-api-gem (git worktree)
Gem location: /Users/bmc/Code/Active/Ruby/nationbuilder_api
Test app: /Users/bmc/Code/Active/Ruby/citizen-nb-api

The OAuth module already uses Net::HTTP successfully - use it as a reference pattern.
