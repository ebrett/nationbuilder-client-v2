# NationBuilder Client v2

[![CI](https://github.com/ebrett/nationbuilder-client-v2/actions/workflows/ci.yml/badge.svg)](https://github.com/ebrett/nationbuilder-client-v2/actions/workflows/ci.yml)

A Ruby client for the NationBuilder API v2 with OAuth 2.0 PKCE authentication, flexible token storage, and seamless Rails integration.

## Features

- **OAuth 2.0 with PKCE**: Secure authentication flow with automatic token management
- **Multiple Token Storage Adapters**: ActiveRecord, Redis, or in-memory storage
- **Automatic Token Refresh**: Tokens refresh automatically before expiration
- **Rails Integration**: Zero-config setup with Rails Engine
- **Comprehensive Error Handling**: Retryable error classification and detailed error messages
- **Request/Response Logging**: Automatic credential sanitization for security
- **Multi-Tenant Support**: Instance-based configuration for managing multiple accounts
- **Net::HTTP Standard Library**: No external HTTP dependencies - uses Ruby's built-in Net::HTTP

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'nationbuilder-client-v2'
```

And then execute:

```bash
bundle install
```

Or install it yourself:

```bash
gem install nationbuilder-client-v2
```

## Quick Start

### Rails Application

```ruby
# config/initializers/nationbuilder_api.rb
NationbuilderApi.configure do |config|
  config.client_id = ENV['NATIONBUILDER_CLIENT_ID']
  config.client_secret = ENV['NATIONBUILDER_CLIENT_SECRET']
  config.redirect_uri = 'https://your-app.com/oauth/callback'
end
```

### Non-Rails Application

```ruby
require 'nationbuilder_api'

client = NationbuilderApi::Client.new(
  client_id: ENV['NATIONBUILDER_CLIENT_ID'],
  client_secret: ENV['NATIONBUILDER_CLIENT_SECRET'],
  redirect_uri: 'https://your-app.com/oauth/callback'
)
```

## OAuth Authentication Flow

### 1. Generate Authorization URL

```ruby
client = NationbuilderApi::Client.new(
  client_id: 'your_client_id',
  client_secret: 'your_client_secret',
  redirect_uri: 'https://example.com/callback'
)

# Generate authorization URL with PKCE
auth_data = client.authorize_url(
  scopes: [
    NationbuilderApi::SCOPE_PEOPLE_READ,
    NationbuilderApi::SCOPE_PEOPLE_WRITE
  ]
)

# Redirect user to auth_data[:url]
# Store auth_data[:code_verifier] and auth_data[:state] in session
```

### 2. Exchange Authorization Code for Token

```ruby
# In your OAuth callback handler
token_data = client.exchange_code_for_token(
  code: params[:code],
  code_verifier: session[:code_verifier]
)

# Token is automatically stored in configured adapter
# token_data contains: access_token, refresh_token, expires_at, scopes
```

### 3. Make Authenticated API Requests

```ruby
# Using resource methods (recommended)
person = client.people.show(123)
taggings = client.people.taggings(123)
rsvps = client.people.rsvps(123)
activities = client.people.activities(123)

# Or make direct API calls
people = client.get('/api/v1/people')

# Create a new person
person = client.post('/api/v1/people', body: {
  person: {
    first_name: 'John',
    last_name: 'Doe',
    email: 'john.doe@example.com'
  }
})

# Update a person
client.patch("/api/v1/people/#{person[:id]}", body: {
  person: { first_name: 'Jane' }
})

# Delete a person
client.delete("/api/v1/people/#{person[:id]}")
```

## API Resources

### People Resource

The People resource provides convenient methods for working with NationBuilder people data:

```ruby
# Fetch person details
person = client.people.show(123)
# => { person: { id: 123, first_name: "John", last_name: "Doe", email: "john@example.com", ... } }

# Get person's taggings/subscriptions
taggings = client.people.taggings(123)
# => { results: [{ tag: "volunteer", ... }, { tag: "donor", ... }] }

# Get person's event RSVPs (uses V2 API with JSON:API format)
rsvps = client.people.rsvps(123)
# => { data: [...], included: [... event details ...] }

# Exclude event details from RSVP response
rsvps = client.people.rsvps(123, include_event: false)
# => { data: [...] }

# Get person's recent activities
# Note: This endpoint may not be available on all NationBuilder accounts
activities = client.people.activities(123)
# => { results: [{ type: "email_sent", created_at: "...", ... }] }
```

## Configuration Options

### Global Configuration

```ruby
NationbuilderApi.configure do |config|
  # Required
  config.client_id = 'your_client_id'
  config.client_secret = 'your_client_secret'
  config.redirect_uri = 'https://example.com/callback'

  # Optional
  config.base_url = 'https://api.nationbuilder.com/v2' # Default
  config.token_adapter = :active_record # :memory, :redis, or custom adapter
  config.timeout = 30 # HTTP timeout in seconds
  config.log_level = :info # :debug, :info, :warn, :error
end
```

### Instance Configuration

```ruby
# Instance configuration overrides global configuration
client = NationbuilderApi::Client.new(
  client_id: 'custom_client_id',
  timeout: 60,
  token_adapter: :redis
)
```

## Token Storage Adapters

### Memory Adapter (Default for non-Rails)

```ruby
client = NationbuilderApi::Client.new(
  # ... other config ...
  token_adapter: :memory
)
```

Stores tokens in memory. **Not suitable for production** - tokens are lost on restart.

### ActiveRecord Adapter (Default for Rails)

```ruby
# Automatically used if ActiveRecord is available

client = NationbuilderApi::Client.new(
  # ... other config ...
  token_adapter: :active_record
)
```

Requires a model with the following structure:

```ruby
# app/models/nationbuilder_api_token.rb
class NationbuilderApiToken < ApplicationRecord
  # Columns:
  # - identifier: string (index)
  # - access_token: text
  # - refresh_token: text
  # - expires_at: datetime
  # - scopes: text (JSON array)
  # - token_type: string
end
```

### Redis Adapter

```ruby
# Add Redis gem to Gemfile
gem 'redis'

# Configure client
client = NationbuilderApi::Client.new(
  # ... other config ...
  token_adapter: :redis
)

# Or with custom Redis client
redis_client = Redis.new(url: ENV['REDIS_URL'])
adapter = NationbuilderApi::TokenStorage::Redis.new(redis_client)

client = NationbuilderApi::Client.new(
  # ... other config ...
  token_adapter: adapter
)
```

## OAuth Scopes

Use predefined scope constants for type safety:

```ruby
NationbuilderApi::SCOPE_PEOPLE_READ      # "people:read"
NationbuilderApi::SCOPE_PEOPLE_WRITE     # "people:write"
NationbuilderApi::SCOPE_DONATIONS_READ   # "donations:read"
NationbuilderApi::SCOPE_DONATIONS_WRITE  # "donations:write"
NationbuilderApi::SCOPE_EVENTS_READ      # "events:read"
NationbuilderApi::SCOPE_EVENTS_WRITE     # "events:write"
NationbuilderApi::SCOPE_LISTS_READ       # "lists:read"
NationbuilderApi::SCOPE_LISTS_WRITE      # "lists:write"
NationbuilderApi::SCOPE_TAGS_READ        # "tags:read"
NationbuilderApi::SCOPE_TAGS_WRITE       # "tags:write"
```

## Error Handling

All errors inherit from `NationbuilderApi::Error` and include a `retryable?` method:

```ruby
begin
  client.get('/people')
rescue NationbuilderApi::RateLimitError => e
  # Rate limit exceeded - wait and retry
  sleep_time = e.retry_after - Time.now
  sleep(sleep_time) if sleep_time > 0
  retry if e.retryable?
rescue NationbuilderApi::AuthenticationError => e
  # Token expired or invalid - re-authenticate
  redirect_to oauth_authorization_path
rescue NationbuilderApi::NetworkError => e
  # Network timeout or connection error - safe to retry
  retry if e.retryable?
rescue NationbuilderApi::ServerError => e
  # 5xx server error - safe to retry
  retry if e.retryable?
rescue NationbuilderApi::Error => e
  # Other errors (validation, not found, etc.) - don't retry
  Rails.logger.error("NationBuilder API error: #{e.message}")
end
```

### Error Classes

- `ConfigurationError` - Missing or invalid configuration (not retryable)
- `AuthenticationError` - OAuth/token failures (not retryable)
- `AuthorizationError` - Insufficient permissions (not retryable)
- `ValidationError` - Invalid request parameters (not retryable)
- `NotFoundError` - Resource not found (not retryable)
- `RateLimitError` - Rate limit exceeded (retryable, includes `retry_after`)
- `ServerError` - 5xx server errors (retryable)
- `NetworkError` - Timeouts, connection failures (retryable)

## Multi-Tenant Usage

Manage multiple NationBuilder accounts using identifiers:

```ruby
# Account 1
client1 = NationbuilderApi::Client.new(
  client_id: 'client_id',
  client_secret: 'client_secret',
  redirect_uri: 'https://example.com/callback',
  identifier: 'account_1'
)

# Account 2
client2 = NationbuilderApi::Client.new(
  client_id: 'client_id',
  client_secret: 'client_secret',
  redirect_uri: 'https://example.com/callback',
  identifier: 'account_2'
)

# Each client uses separate tokens
client1.get('/people') # Uses account_1 token
client2.get('/people') # Uses account_2 token
```

## Logging

Logs automatically sanitize credentials:

```ruby
# Debug logging shows full request/response (sanitized)
NationbuilderApi.configure do |config|
  config.log_level = :debug
end

# Custom logger
NationbuilderApi.configure do |config|
  config.logger = Logger.new('log/nationbuilder_api.log')
end
```

## Development

After checking out the repo:

```bash
bundle install
bundle exec rspec      # Run tests
bundle exec standardrb # Run linter
bundle exec rake build # Build gem
```

## Testing

```bash
bundle exec rspec
```

Test coverage target: 90%+

## Contributing

1. Fork it (https://github.com/ebrett/nationbuilder-client-v2/fork)
2. Create your feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -am 'Add my feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Create a Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Version

Current version: **0.2.0** (Phase 2 - People API Resource)

### Roadmap

- **Phase 1 (v0.1.0)** ✅ OAuth, token management, HTTP client infrastructure
- **Phase 2 (v0.2.0)** ✅ People API resource (show, taggings, rsvps, activities)
- **Phase 3 (v0.3.0)** - Additional resources (Donations, Events, Tags), pagination, rate limiting
- **Phase 4 (v1.0.0)** - Webhooks, batch operations, Rails generators, comprehensive docs, testing utilities
