# Architecture Decisions: NationBuilder API Phase 1

## Overview
This document captures key architectural decisions made during requirements gathering for the NationBuilder API Ruby gem Phase 1 implementation.

## Decision 1: Use Pay Gem as Architectural Reference

**Context:**
We need to build a Ruby gem with OAuth authentication, multiple storage adapters, and Rails integration. Rather than inventing patterns, we can learn from successful gems in the ecosystem.

**Decision:**
Model the gem architecture after the Pay gem (https://github.com/pay-rails/pay), which successfully implements multi-adapter patterns and seamless Rails integration.

**Rationale:**
- Pay gem is well-established, actively maintained, and widely used in production
- Implements adapter pattern for multiple payment processors (analogous to our token storage needs)
- Proven Rails Engine integration for zero-config setup
- Simple, clear configuration API that developers understand
- Module-level configuration with `mattr_accessor` is Ruby/Rails idiomatic

**Implications:**
- Module structure: `lib/nationbuilder_api.rb` as main entry point with autoload
- Configuration via `NationbuilderApi.setup { |config| ... }` block
- Adapters implement `enabled?` method to check dependency availability
- Rails Engine for automatic Rails integration
- Error hierarchy with simple base class and specific subclasses

## Decision 2: PKCE-Only OAuth Implementation

**Context:**
OAuth 2.0 has two flows: traditional authorization code flow and PKCE (Proof Key for Code Exchange) flow. We need to decide which to support.

**Decision:**
Implement PKCE-only OAuth flow, not traditional flow.

**Rationale:**
- PKCE is the modern OAuth 2.0 best practice recommended by RFC 8252
- More secure against authorization code interception attacks
- Simpler implementation - no client_secret exchange in some flows
- Forward-compatible with OAuth 2.1 requirements
- NationBuilder API v2 supports PKCE

**Implications:**
- Generate PKCE code verifier and code challenge
- Store code verifier during authorization
- Include code_verifier in token exchange request
- Simpler client-side implementation (especially for mobile/SPA use cases)
- Documentation should explain PKCE benefits

## Decision 3: Multiple Token Storage Adapters

**Context:**
Different applications have different persistence needs. Some use ActiveRecord, others Redis, and tests need in-memory storage.

**Decision:**
Provide three token storage adapters out of the box:
1. ActiveRecord adapter (default if ActiveRecord available)
2. Redis adapter
3. Memory adapter (for testing)

**Rationale:**
- Follows Pay gem's successful multi-processor pattern
- ActiveRecord is most common in Rails apps (sensible default)
- Redis supports high-performance, distributed applications
- Memory adapter enables testing without external dependencies
- Abstract interface allows users to implement custom adapters later

**Implications:**
- Define abstract `TokenAdapter` base class with interface methods
- Each adapter implements: `store_token`, `retrieve_token`, `refresh_token`, `delete_token`
- Each adapter includes `enabled?` class method checking dependencies
- Configuration accepts `:token_adapter` option
- Auto-detect ActiveRecord availability and use as default

## Decision 4: Dual Configuration Pattern

**Context:**
Some users want global configuration (one NationBuilder account), others need multiple clients (multi-tenant apps, testing).

**Decision:**
Support both global configuration (`NationbuilderApi.configure`) and instance-based configuration (`Client.new(options)`) with instance taking precedence.

**Rationale:**
- Global config covers 80% use case (single NationBuilder account)
- Instance config enables multi-tenant applications
- Precedence rule (instance > global) is intuitive
- Common pattern in Ruby ecosystem (Faraday, HTTParty, etc.)

**Implications:**
- Module-level `mattr_accessor` for global config
- Client constructor accepts options hash
- Client merges instance options over global config
- Documentation shows both patterns with use case guidance

## Decision 5: Fail-Fast Configuration Validation

**Context:**
Missing configuration can fail at initialization or at first API call. We need to decide when to validate.

**Decision:**
Validate required configuration at initialization time and raise errors immediately.

**Rationale:**
- Fail fast - catch configuration errors before runtime
- Clear error messages at startup easier to debug than mid-operation failures
- Prevents wasted API calls with invalid credentials
- Matches user expectation: "if it initializes, it should work"

**Implications:**
- Validate `client_id`, `client_secret`, and `redirect_uri` presence in `Client#initialize`
- Raise `ConfigurationError` with helpful message indicating missing fields
- Validation runs before any HTTP requests
- Documentation emphasizes required configuration

## Decision 6: No Automatic Retry in Phase 1

**Context:**
Rate limit errors can be retried after waiting. We need to decide if retries should be automatic or manual.

**Decision:**
Phase 1 raises `RateLimitError` with retry-after details. No automatic retry logic.

**Rationale:**
- Keeps Phase 1 scope focused and simpler
- Retry logic requires careful design (exponential backoff, jitter, max retries)
- Applications may want custom retry strategies
- Error includes retry-after timestamp for manual retry implementation
- Deferred to Phase 3 (rate limit management) for robust solution

**Implications:**
- `RateLimitError` includes `retry_after` attribute with timestamp
- Error message indicates when retry can be attempted
- Applications handle retry logic manually
- Phase 3 will add automatic retry with configuration options
- Documentation shows manual retry pattern

## Decision 7: Internal HTTP.rb Middleware Stack

**Context:**
HTTP.rb supports middleware for request/response processing. We need to decide if users can configure it.

**Decision:**
Keep HTTP.rb middleware stack internal and not user-configurable in Phase 1.

**Rationale:**
- Simplifies API surface and reduces configuration complexity
- Middleware needs are covered by logging and error handling
- Can expose in future phase if users request it
- Internal control ensures consistent behavior
- Most users don't need middleware customization

**Implications:**
- Middleware stack configured internally in Client
- Logging middleware handles request/response inspection
- Error handling middleware translates HTTP errors to gem exceptions
- No public API for middleware configuration
- Can add `middleware` configuration option in later phase if needed

## Decision 8: OAuth Scope Constants

**Context:**
OAuth scopes are strings like "people:read". Hard-coding strings is error-prone.

**Decision:**
Provide OAuth scope constants as module constants (e.g., `NationbuilderApi::SCOPE_PEOPLE_READ`).

**Rationale:**
- Prevents typos in scope strings
- Auto-complete in IDEs
- Self-documenting code
- Easy to discover available scopes
- Common pattern (GitHub's Octokit gem does this)

**Implications:**
- Define constants in main module: `SCOPE_PEOPLE_READ = "people:read"`
- Document all available scopes
- Examples in documentation use constants, not strings
- Users can still pass raw strings if needed

## Decision 9: Retryable Error Classification

**Context:**
Some errors are safe to retry (network timeouts), others are not (authentication failures).

**Decision:**
Include `retryable?` method on all error classes to indicate retry safety.

**Rationale:**
- Makes retry logic easier to implement correctly
- Documents error semantics clearly
- Applications can build generic retry logic using this flag
- Foundation for automatic retry in Phase 3

**Implications:**
- All error classes implement `retryable?` method
- Network errors, timeouts, server errors (5xx): `retryable? = true`
- Authentication, authorization, validation errors: `retryable? = false`
- Rate limit errors: `retryable? = true` (with retry-after delay)
- Documentation explains retry semantics

## Decision 10: Credential Sanitization in Logs

**Context:**
Logging requests/responses can expose sensitive credentials (access tokens, client secrets).

**Decision:**
Automatically sanitize credentials in all log output.

**Rationale:**
- Prevents accidental credential leaks in log files
- Security best practice
- Logs should be shareable without exposing secrets
- Debugging still possible with sanitized logs

**Implications:**
- Logging middleware sanitizes Authorization headers
- Replace tokens with `[FILTERED]` in logs
- Sanitize `client_secret` in OAuth requests
- Sanitize any `token` or `secret` fields in request/response bodies
- Document sanitization behavior

## Decision 11: Rails Engine for Zero-Config Integration

**Context:**
Rails applications should work with minimal setup. We need seamless Rails integration.

**Decision:**
Implement Rails Engine for automatic Rails integration when Rails is detected.

**Rationale:**
- Rails Engine is the standard Rails integration pattern
- Enables automatic configuration and initialization
- Auto-detects Rails.logger for logging
- Can add generators, rake tasks, etc. in later phases
- Zero-config experience for Rails users

**Implications:**
- Create `lib/nationbuilder_api/engine.rb` when Rails constant defined
- Engine initializer sets up Rails.logger integration
- Engine can load ActiveRecord adapter automatically if available
- Documentation has separate Rails quick-start guide
- Non-Rails usage remains simple (no Rails dependency)

## Decision 12: Default Base URL with Override

**Context:**
NationBuilder API v2 base URL is `https://api.nationbuilder.com/v2`. We need to decide if this should be configurable.

**Decision:**
Default to `https://api.nationbuilder.com/v2` but allow override via configuration.

**Rationale:**
- 99% of users will use standard API URL (sensible default)
- Override supports testing, development, or future API versions
- Configuration option costs little complexity
- Future-proofs gem for API version changes

**Implications:**
- `base_url` configuration option with default
- Configuration validation ensures URL is valid HTTPS
- Documentation shows override for testing scenarios
- Can support staging/sandbox environments if NationBuilder provides them

## Summary

These architectural decisions establish a foundation that:
- **Follows proven patterns** from successful Ruby gems (Pay, Stripe, Octokit)
- **Balances simplicity and flexibility** (sensible defaults, configuration options)
- **Prioritizes security** (PKCE, credential sanitization, HTTPS only)
- **Enables Rails integration** while supporting standalone Ruby
- **Supports future phases** (adapter extensibility, retryable errors, configuration hooks)

The Pay gem serves as our primary architectural reference, providing battle-tested patterns for adapter-based gems with Rails integration. These decisions keep Phase 1 focused while laying groundwork for resource implementations in Phase 2 and advanced features in Phase 3.
