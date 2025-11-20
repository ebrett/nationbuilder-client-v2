# Product Roadmap

## Phase 1: Core Infrastructure (v0.1.0 - MVP)

1. [x] OAuth 2.0 Authentication Flow — Implement complete authorization code flow with token exchange, automatic token refresh, and credential storage helpers for both standalone Ruby and Rails applications `M`

2. [x] Base Client Architecture — Build foundational HTTP client using HTTP.rb with configuration management, request/response middleware, base URL handling, and header management for all API calls `M`

3. [x] Comprehensive Error Handling — Create exception hierarchy for API errors including rate limits, validation failures, authentication errors, and network issues with detailed error messages and context `S`

4. [x] Configuration System — Implement flexible configuration supporting environment variables, initializer blocks, and Rails credentials with validation and helpful error messages for missing configuration `S`

5. [x] Request Logging and Debugging — Add configurable logging middleware for request/response inspection with different log levels (debug, info, warn) and sanitization of sensitive data `S`

## Phase 1.5: Technical Debt & Quality Improvements (v0.1.1)

**Priority:** Complete before Phase 2 to ensure solid foundation

6. [ ] Fix Token Adapter Validation — Correct `validate_adapter_interface!` method in client.rb to use `respond_to?` instead of instance_methods set difference for accurate interface validation `S`

7. [ ] Add Redis & ActiveRecord Adapter Tests — Implement comprehensive test suites for Redis and ActiveRecord token storage adapters to match Memory adapter test coverage `M`

8. [ ] Enhance HTTP Error Context — Add request method and path to error messages for improved debugging (e.g., "Authentication failed for GET /people") `S`

9. [ ] Centralize OAuth HTTP Calls — Refactor OAuth module to use HttpClient instead of direct HTTP.post calls for consistent logging and error handling across all HTTP operations `M`

10. [ ] Add Rate Limit Monitoring — Log rate limit headers (X-RateLimit-Remaining, X-RateLimit-Reset) for proactive rate limit monitoring and debugging `S`

11. [ ] Production Memory Adapter Warning — Add runtime warning when Memory adapter is used in production Rails environments to prevent accidental production usage `XS`

12. [ ] Add Explicit Linter Configuration — Create .standard.yml file for explicit StandardRB configuration and team consistency beyond defaults `XS`

13. [ ] Add Network Error Test Coverage — Implement tests for timeout scenarios and network error handling to ensure resilience `S`

## Phase 2: Core Resources (v0.2.0)

14. [ ] People Resource — Implement full CRUD operations for People endpoint including list with filtering/pagination, create, show, update, delete, and search functionality with proper parameter handling `L`

15. [ ] Donations Resource — Build Donations endpoint support with list/filter/pagination, create, show, update operations and proper handling of money values, dates, and donor relationships `M`

16. [ ] Events Resource — Create Events resource with list, create, show, update, delete operations including RSVP management and event-specific filtering capabilities `M`

17. [ ] Tags Resource — Implement tag management with list tags, apply tag to person, remove tag from person, and bulk tagging operations for managing supporter segments `S`

18. [ ] Response Object Pattern — Wrap API responses in typed objects instead of raw hashes for better developer experience and type safety (e.g., Person, Donation objects) `M`

## Phase 3: Advanced API Features (v0.3.0)

19. [ ] Pagination Handling — Build automatic pagination support with iterator interface for transparently handling large result sets across all list endpoints without manual page management `M`

20. [ ] Automatic Retry Logic — Implement intelligent retry with exponential backoff for retryable errors (rate limits, server errors, network failures) with configurable max attempts and backoff strategy `M`

21. [ ] Enhanced Rate Limit Management — Build proactive rate limit management with header tracking, queue management, and automatic request throttling to prevent rate limit errors `M`

22. [ ] Webhook Verification — Create webhook signature verification helpers and request parsing utilities for securely processing NationBuilder webhook callbacks in applications `S`

23. [ ] Batch Operations — Build efficient bulk import/export capabilities with streaming support for processing large datasets without loading everything into memory `L`

24. [ ] Token Encryption at Rest — Add optional encryption for tokens stored in ActiveRecord adapter using Rails encrypted attributes for enhanced security `S`

25. [ ] Request Instrumentation — Add ActiveSupport::Notifications hooks for monitoring request duration, error rates, and API usage metrics `S`

## Phase 4: Developer Experience (v0.4.0)

26. [ ] Rails Integration Generators — Create Rails generators for initializer setup, credential configuration templates, and example controller/service object code with best practices `M`

27. [ ] Comprehensive Documentation — Write complete documentation including getting started guide, OAuth setup walkthrough, resource usage examples, Rails integration guide, and common use case recipes `L`

28. [ ] Testing Utilities — Build RSpec and Minitest test helpers including request stubbing, VCR cassette support, and in-memory mock client for unit testing without network calls `M`

29. [ ] CLI Development Tools — Create command-line interface for OAuth token generation, API endpoint testing, and credential management to streamline local development workflow `M`

30. [ ] Example VCR Cassettes — Provide pre-recorded VCR cassettes for common API scenarios to help developers write tests without making real API calls `S`

31. [ ] Security Best Practices Guide — Document security considerations including token storage, webhook verification, PKCE flow, and HTTPS enforcement in comprehensive security guide `S`

32. [ ] Debug Mode Enhancement — Add enhanced debug mode with detailed request/response logging, timing breakdown, and API usage statistics for troubleshooting `M`

## Phase 5: Extended Resources & Performance (v0.5.0)

33. [ ] Additional Core Resources — Expand API coverage to include Lists, Surveys, Contacts, Sites, and other commonly-used NationBuilder resources with same quality as initial resource implementations `XL`

34. [ ] Custom Resource Extension — Implement extension system allowing developers to easily add support for new API endpoints as NationBuilder expands their API without waiting for gem updates `M`

35. [ ] Connection Pooling — Add HTTP connection pooling for improved performance and reduced connection overhead in high-traffic applications `M`

36. [ ] Request Caching — Implement caching layer with ETags and conditional requests for idempotent operations to reduce API calls and improve response times `M`

37. [ ] Background Job Integration — Add Sidekiq/ActiveJob helpers for asynchronous API operations with automatic retry and failure handling `M`

38. [ ] GraphQL Support — Add support for NationBuilder's GraphQL API (if available) alongside REST API for more efficient data fetching `L`

39. [ ] Multi-Region Support — Add support for NationBuilder instances in different regions with region-aware endpoint configuration `S`

## Code Quality Priorities

**Based on v0.1.0 Code Review:**

### Critical (Must Fix Before v0.1.1)
- Item 6: Token adapter validation bug
- Item 7: Missing adapter test coverage
- Item 8: Enhanced error context

### High (Should Fix Before Phase 2)
- Item 9: Centralize OAuth HTTP calls
- Item 10: Rate limit header logging
- Item 11: Production memory adapter warning

### Medium (Nice to Have)
- Item 12: Explicit linter configuration
- Item 13: Network error test coverage

## Architecture Recommendations

**Based on Standards & Mission:**

### Phase 2 Considerations
1. **Resource Pattern Consistency**: Establish standard CRUD interface that all resources follow
2. **Response Objects**: Move away from raw hashes to typed objects for better DX
3. **Validation Layer**: Add client-side validation before API calls to catch errors early
4. **Documentation**: Maintain Ruby-first approach with practical examples

### Phase 3 Considerations
1. **Retry Strategy**: Implement exponential backoff per error-handling standards
2. **Graceful Degradation**: Design for failure scenarios per standards
3. **Resource Cleanup**: Ensure proper cleanup in ensure/finally blocks

### Performance Goals
- Token refresh: < 100ms (achieved)
- HTTP request overhead: < 50ms
- Memory footprint: < 1MB per 1000 tokens (achieved)
- Connection reuse: Implement pooling in Phase 5

## User Persona Alignment

**Campaign Developer (Primary):**
- ✓ Quick setup achieved (< 2 minutes)
- Phase 2: Resource-based interface for rapid feature development
- Phase 4: CLI tools for OAuth token generation

**Rails Developer (Primary):**
- ✓ Rails integration complete
- Phase 2: ActiveRecord-like resource interface
- Phase 4: Rails generators for boilerplate

**Solo Developer (Secondary):**
- ✓ Copy-paste examples in README
- Phase 4: Comprehensive documentation site
- Phase 4: Testing utilities for quick prototypes

> Notes
> - Each item represents a complete, testable feature with comprehensive specs
> - Items are ordered by technical dependencies and architectural foundations
> - All phases include corresponding test coverage and documentation updates
> - Version numbers indicate suggested release milestones but can be adjusted based on development velocity
> - Phase 1.5 items are critical quality improvements identified in v0.1.0 code review
> - Code quality priorities reflect actual issues found in codebase analysis
