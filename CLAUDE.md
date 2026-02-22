# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project Overview

`nationbuilder-client-v2` is a Ruby gem providing a client for the NationBuilder API v2 with OAuth 2.0 PKCE authentication, flexible token storage adapters, and Rails integration.

- **Gem name:** `nationbuilder-client-v2`
- **Version:** 0.2.0 (pre-release)
- **Required Ruby:** >= 3.2.0

## Tech Stack

- Ruby 3.2+ with Net::HTTP (no external HTTP dependencies)
- RSpec for testing, SimpleCov for coverage (threshold: 90%)
- StandardRB for linting (`bundle exec standardrb` or `bundle exec rake lint`)
- WebMock + VCR for HTTP stubbing in specs

## Key Paths

| Path | Purpose |
|------|---------|
| `lib/nationbuilder_api/` | Core gem source |
| `lib/nationbuilder_api/resources/` | API resource classes (People, Tags, Donations, Events) |
| `lib/nationbuilder_api/token_storage/` | Storage adapters (Memory, Redis, ActiveRecord) |
| `lib/nationbuilder_api/response_objects/` | Typed response wrappers |
| `spec/` | RSpec test suite |
| `.standard.yml` | StandardRB linter configuration |
| `nationbuilder-client-v2.gemspec` | Gem specification |

## Common Commands

```bash
bundle exec rspec          # Run full test suite
bundle exec rake lint      # Run StandardRB linter
bundle exec standardrb     # Run linter directly
bundle exec rake build     # Build gem package
```

## Issue Tracking

Tasks for this project are tracked in Obsidian:

**`~/vaults/knowledge-base/01_Projects/Citizen/NationBuilder Gem Tasks.md`**
