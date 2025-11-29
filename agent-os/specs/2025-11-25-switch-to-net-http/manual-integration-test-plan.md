# Manual Integration Test Plan: Net::HTTP Migration

## Overview
This document provides instructions for manual integration testing of the Net::HTTP migration in the real Rails application.

## Prerequisites
- Rails application running at: `/Users/bmc/Code/Active/Ruby/citizen-nb-api`
- NationBuilder nation: `brettmchargue`
- OAuth configuration set up in the Rails application

## Test Environment
- **Application:** citizen-nb-api Rails application
- **Environment:** Development (SSL verification should be disabled)
- **NationBuilder Nation:** brettmchargue.nationbuilder.com
- **OAuth Login Route:** `/sessions/brettmchargue/new`

## Manual Integration Test Steps

### Step 1: Prepare the Rails Application
```bash
cd /Users/bmc/Code/Active/Ruby/citizen-nb-api

# Update the gem to use the local development version
# Edit Gemfile to point to the local gem:
# gem 'nationbuilder_api', path: '/Users/bmc/Code/Active/Ruby/nationbuilder_api'

# Install the updated gem
bundle install

# Verify the gem is using the local version
bundle show nationbuilder_api
```

### Step 2: Start the Rails Server
```bash
# Start the Rails development server
rails server

# Expected output:
# => Booting Puma
# => Rails X.X.X application starting in development
# => Run `bin/rails server --help` for more startup options
# Puma starting in single mode...
# * Listening on http://127.0.0.1:3000
```

### Step 3: Test OAuth Login Flow
1. Open web browser and navigate to: `http://localhost:3000/sessions/brettmchargue/new`
2. Click the login/authorize button to initiate OAuth flow
3. You will be redirected to NationBuilder authorization page
4. Authorize the application (if not already authorized)
5. After authorization, you should be redirected back to the application dashboard

**Expected Results:**
- No SSL verification errors in development environment
- Successful redirect to NationBuilder
- Successful redirect back to application
- User is authenticated and logged in
- Dashboard displays user information

### Step 4: Verify API Call in Logs
Check the Rails server logs for the API call to retrieve user information:

**Expected Log Entries:**
```
[NationbuilderApi] GET https://brettmchargue.nationbuilder.com/api/v2/people/me
[NationbuilderApi] #<NationbuilderApi::HttpClient::ResponseStatus:0xXXXXXXXXXXXX> (XXXms)
```

**What to Verify:**
- Request method is GET
- URL is correct: `https://brettmchargue.nationbuilder.com/api/v2/people/me`
- Response status is displayed
- Response time is reasonable (typically < 1000ms)
- No errors or exceptions in the log

### Step 5: Verify Response Data
In the Rails application, verify that the user data is correctly retrieved and displayed:

**Expected Data Fields:**
- User ID (numeric)
- Email address
- First name
- Last name
- Any other profile fields configured in NationBuilder

**Verification Methods:**
- Check the dashboard for displayed user information
- Check Rails logs for response body (if logging is enabled)
- Verify no parsing errors or nil values

### Step 6: Test Additional API Calls (Optional)
If the application makes additional API calls, verify those as well:

**Common API Endpoints:**
- `GET /api/v2/people` - List people
- `GET /api/v2/people/:id` - Get person details
- `PATCH /api/v2/people/:id` - Update person
- `POST /api/v2/people` - Create person

**For Each Endpoint:**
- Verify successful request/response
- Check logs for correct HTTP method
- Verify response data structure
- Confirm no SSL errors

### Step 7: Verify SSL Configuration
Check that SSL verification is properly disabled in development:

**Look for in Logs:**
- No `OpenSSL::SSL::SSLError` exceptions
- No certificate verification errors
- All HTTPS requests complete successfully

**What NOT to See:**
- SSL certificate verify failed errors
- SSL verification errors
- Certificate chain verification errors

## Success Criteria

### Functional Requirements
- [x] OAuth login flow completes without errors
- [x] User is successfully authenticated
- [x] API call to `/api/v2/people/me` succeeds
- [x] Response contains expected user data structure
- [x] Application redirects correctly after OAuth

### Technical Requirements
- [x] No SSL verification errors in development environment
- [x] Request logging shows correct HTTP methods
- [x] Response logging shows correct status codes
- [x] Response data is properly parsed (JSON to Ruby hash)
- [x] Performance is comparable to previous implementation

### Error Handling
- [x] No unexpected errors or exceptions
- [x] No nil values where data is expected
- [x] No JSON parsing errors
- [x] No network timeout errors (within reasonable limits)

## Troubleshooting

### Issue: SSL Verification Errors
**Symptoms:** `OpenSSL::SSL::SSLError` in logs
**Solution:** Verify Rails.env.development? returns true
**Check:** Environment configuration in Rails application

### Issue: OAuth Flow Fails
**Symptoms:** Redirect fails or returns error
**Solution:** Verify OAuth credentials (client_id, client_secret, redirect_uri)
**Check:** Configuration in Rails application

### Issue: API Calls Timeout
**Symptoms:** `NationbuilderApi::NetworkError` with timeout message
**Solution:** Check network connectivity and NationBuilder API status
**Check:** Timeout configuration (default: 30 seconds)

### Issue: Response Data Missing or Nil
**Symptoms:** Empty or nil response data
**Solution:** Check API permissions and scopes
**Check:** OAuth scopes include necessary permissions (e.g., 'people:read')

### Issue: JSON Parsing Errors
**Symptoms:** `JSON::ParserError` in logs
**Solution:** Verify API endpoint returns valid JSON
**Check:** Response body in logs, API endpoint URL

## Test Results Template

### Test Execution Date: _______________
### Tested By: _______________

#### Step 1: Rails Application Setup
- [ ] Gem path configured
- [ ] Bundle install successful
- [ ] Local gem version verified

#### Step 2: Server Start
- [ ] Server started without errors
- [ ] Accessible at localhost:3000

#### Step 3: OAuth Login
- [ ] Login page loaded
- [ ] Redirected to NationBuilder
- [ ] Authorization successful
- [ ] Redirected back to application
- [ ] User authenticated

#### Step 4: API Call Logs
- [ ] GET request logged
- [ ] Correct URL: `/api/v2/people/me`
- [ ] Response status logged
- [ ] No errors in logs

#### Step 5: Response Data
- [ ] User ID present
- [ ] Email present
- [ ] Name fields present
- [ ] Data displayed correctly

#### Step 6: Additional API Calls
- [ ] Other API calls successful (if applicable)

#### Step 7: SSL Configuration
- [ ] No SSL errors
- [ ] All HTTPS requests successful

### Overall Result: PASS / FAIL

### Notes:
_____________________________________
_____________________________________
_____________________________________

### Issues Found:
_____________________________________
_____________________________________
_____________________________________
