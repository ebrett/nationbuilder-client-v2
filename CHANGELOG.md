# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - TBD

### Added
- OAuth 2.0 authentication with PKCE support
- Authorization URL generation with code challenge/verifier
- Token exchange (authorization code for access token)
- Automatic token refresh when expired
- OAuth scope constants (SCOPE_PEOPLE_READ, SCOPE_PEOPLE_WRITE, etc.)
- Token storage adapters: Memory, Redis, ActiveRecord
- Abstract token storage interface for custom adapters
- HTTP.rb-based HTTP client with automatic authentication
- Comprehensive error hierarchy with retryable? logic
- Configuration system (global and instance-based)
- Request/response logging with credential sanitization
- Rails Engine for zero-config integration
- Support for Ruby 2.7, 3.0, 3.1, 3.2, 3.3

[Unreleased]: https://github.com/bmc/nationbuilder_api/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/bmc/nationbuilder_api/releases/tag/v0.1.0
