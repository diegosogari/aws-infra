# Use time-based UUIDs for events and resources.
# Use additional encryption for sensitive data on a per-tenant basis,
#   storing the key in the authentication service and providing it as
#   a user claim as part of the authentication flow.

resource "aws_dynamodb_table" "demo_events" {
  name           = "demo-events"
  billing_mode   = "PROVISIONED"
  read_capacity  = 10
  write_capacity = 10
  hash_key       = "ResourceUuid"
  range_key      = "EventPath" # [resource_type]:[event_type]:[event_uuid]

  attribute {
    name = "ResourceUuid"
    type = "S"
  }

  attribute {
    name = "EventPath"
    type = "S"
  }

  # additional attributes:
  #   EventData (json)
}

resource "aws_dynamodb_table" "demo_resources" {
  name           = "demo-resources"
  billing_mode   = "PROVISIONED"
  read_capacity  = 10
  write_capacity = 10
  hash_key       = "TenantUuid"
  range_key      = "ResourcePath" # [resource_type]:[resource_uuid][:[subresource_type]:[subresource_uuid]...]

  attribute {
    name = "TenantUuid"
    type = "S"
  }

  attribute {
    name = "ResourcePath"
    type = "S"
  }

  # additional attributes:
  #   SnapshotData (json)
  #   SnapshotVersion (event_uuid)
  #   CurrentVersion (event_uuid)
  #   LastTriggeringEvent (event_uuid)
}
