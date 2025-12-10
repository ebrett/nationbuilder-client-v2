# Spec: Add `update` method to People Resource

## Problem Statement

The `NationbuilderApi::Resources::People` class currently provides read-only methods (`show`, `taggings`, `rsvps`, `activities`) but lacks an `update` method for modifying person/signup data via the NationBuilder V2 API.

**Current workaround:**
```ruby
# Users must manually construct PATCH requests
client.patch("/api/v2/signups/#{id}", body: {
  data: {
    type: "signup",
    id: id.to_s,
    attributes: { ... }
  }
})
```

This bypasses the resource abstraction and requires users to know:
1. The correct endpoint path (`/api/v2/signups/` not `/api/v2/people/`)
2. The JSON:API request structure
3. The correct resource type (`"signup"` not `"person"`)

## Solution

Add an `update` method to the `People` resource class that:
1. Abstracts the endpoint details
2. Handles JSON:API request formatting
3. Provides a clean, intuitive API
4. Maintains consistency with other resource methods

## Implementation

### File to modify
`lib/nationbuilder_api/resources/people.rb`

### Method signature
```ruby
# Update a person's attributes
# Uses V2 API with JSON:API format
#
# @param id [String, Integer] Person ID
# @param attributes [Hash] Person attributes to update (first_name, last_name, email, phone, mobile, addresses, etc.)
# @return [Hash] Updated person data in JSON:API format
# @raise [ValidationError] If attributes are invalid
# @raise [NotFoundError] If person not found
# @raise [AuthenticationError] If token is invalid/expired
#
# @example Update basic fields
#   client.people.update(123, attributes: {
#     first_name: "John",
#     last_name: "Doe",
#     email: "john@example.com",
#     mobile: "+1234567890"
#   })
#
# @example Update address
#   client.people.update(123, attributes: {
#     primary_address: {
#       address1: "123 Main St",
#       city: "Portland",
#       state: "OR",
#       zip: "97201",
#       country_code: "US"
#     }
#   })
def update(id, attributes:)
  path = "/api/v2/signups/#{id}"
  body = {
    data: {
      type: "signup",
      id: id.to_s,
      attributes: attributes
    }
  }
  patch(path, body: body)
end
```

### Key implementation details

1. **Endpoint:** Use `/api/v2/signups/:id` (not `/api/v2/people/:id`)
   - The V2 API uses "signups" as the canonical resource for person updates
   - The `show` method already uses this endpoint for consistency

2. **Resource type:** Use `"signup"` (not `"person"`)
   - JSON:API requires the correct resource type
   - Matches the response type from the `show` endpoint

3. **Request format:** JSON:API structure
   ```json
   {
     "data": {
       "type": "signup",
       "id": "123",
       "attributes": {
         "first_name": "John",
         ...
       }
     }
   }
   ```

4. **Attributes:** Accept nested structures
   - Direct fields: `first_name`, `last_name`, `email`, `phone`, `mobile`, `employer`, `occupation`, `party`
   - Nested address objects: `primary_address`, `registered_address` with `address1`, `city`, `state`, `zip`, `country_code`

5. **Error handling:** Inherit from `Base` class
   - `ValidationError` for 422 responses
   - `NotFoundError` for 404 responses
   - `AuthenticationError` for 401 responses

## Testing Requirements

### Unit tests
Add to `spec/nationbuilder_api/resources/people_spec.rb` (or equivalent):

1. **Success case:** Update person attributes
   ```ruby
   it "updates a person's attributes" do
     stub_request(:patch, "#{base_url}/api/v2/signups/123")
       .with(
         body: {
           data: {
             type: "signup",
             id: "123",
             attributes: { first_name: "John", mobile: "+1234567890" }
           }
         }.to_json
       )
       .to_return(status: 200, body: { data: { type: "signup", id: "123", attributes: { first_name: "John" } } }.to_json)

     result = client.people.update(123, attributes: { first_name: "John", mobile: "+1234567890" })
     expect(result[:data][:attributes][:first_name]).to eq("John")
   end
   ```

2. **Error cases:**
   - 404 Not Found (person doesn't exist)
   - 422 Validation Error (invalid attributes)
   - 401 Authentication Error (expired token)

3. **Edge cases:**
   - Empty attributes hash
   - Nested address structures
   - String vs integer IDs

## Integration with existing codebase

### Before (current workaround)
```ruby
# In NationBuilderApiService#update_profile
person_attributes = map_profile_params(profile_params)
request_body = {
  data: {
    type: "signup",
    id: user.nationbuilder_id.to_s,
    attributes: person_attributes
  }
}
client.patch("/api/v2/signups/#{user.nationbuilder_id}", body: request_body)
```

### After (using new method)
```ruby
# In NationBuilderApiService#update_profile
person_attributes = map_profile_params(profile_params)
client.people.update(user.nationbuilder_id, attributes: person_attributes)
```

## NationBuilder API Reference

- **Endpoint:** `PATCH /api/v2/signups/:id`
- **Authentication:** Bearer token (OAuth 2.0)
- **Request Content-Type:** `application/json`
- **Request Format:** JSON:API (https://jsonapi.org/)
- **Response Format:** JSON:API

### Supported attributes
- **Identity:** `first_name`, `last_name`, `email`, `phone`, `mobile`
- **Address:** `primary_address`, `registered_address` (nested objects with `address1`, `address2`, `city`, `state`, `zip`, `country_code`)
- **Professional:** `employer`, `occupation`
- **Political:** `party`, `party_member` (boolean)
- **Profile:** `bio`, `profile_image_url_ssl`

### Unsupported in V2 (use V1 API if needed)
- Tags/taggings (read-only in V2, use V1 for modifications)
- Custom fields
- Lists/subscriptions

## Acceptance Criteria

- [ ] `update` method added to `People` resource class
- [ ] Method uses `/api/v2/signups/:id` endpoint
- [ ] Request body uses JSON:API format with `type: "signup"`
- [ ] Method accepts `id` and `attributes:` parameters
- [ ] Method returns parsed JSON:API response
- [ ] Error cases properly raise appropriate exceptions
- [ ] RDoc documentation includes examples
- [ ] Unit tests cover success and error cases
- [ ] Integration test in real app successfully updates person data

## Notes

- The NationBuilder V2 API uses "signups" as the resource name instead of "people" for write operations
- The V1 API used `/api/v1/people/:id` for both reads and writes, but V2 separates these concerns
- Not all person fields are updateable via API (e.g., `id`, `created_at`, `updated_at` are read-only)
- Some fields may require specific permissions or account settings to modify

## Related Files

- Implementation: `lib/nationbuilder_api/resources/people.rb`
- Tests: `spec/nationbuilder_api/resources/people_spec.rb`
- Base class: `lib/nationbuilder_api/resources/base.rb`
- HTTP client: `lib/nationbuilder_api/http_client.rb`
- Consumer: `app/services/nation_builder_api_service.rb` (in citizen-profile-editing app)
