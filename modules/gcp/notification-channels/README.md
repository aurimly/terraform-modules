# gcp/notification-channels

Map-keyed module for Google Cloud Monitoring notification channels
(`google_monitoring_notification_channel`), the delivery targets that
`gcp/monitoring` alert policies reference.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `channels` | `map(object)` | — | Map of channels keyed by an arbitrary unique ID. |

### `channels` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `type` | `string` | — | Channel type as in the channel descriptor, e.g. `email`, `slack`, `pagerduty`, `webhook_basicauth`, `sms`; the descriptor per type at https://cloud.google.com/monitoring/api/ref_v3/rest/v3/projects.notificationChannelDescriptors/list defines required labels. |
| `display_name` | `string` | — | Required here (validated, non-empty); human-readable name. |
| `project_id` | `string` | — | Project the channel lives in; defaults to the provider-level project. |
| `description` | `string` | — | Free-form description. |
| `enabled` | `bool` | — | Set `false` to mute delivery without detaching policies. |
| `force_delete` | `bool` | — | `true` deletes even when alert policies still reference the channel (policies get updated); `false` (default) makes the delete fail instead. |
| `labels` | `map(string)` | `{}` | Channel-type-specific configuration fields, e.g. `{email_address = ...}` for email, `{channel_name = "#alerts"}` for slack. |
| `user_labels` | `map(string)` | `{}` | Organizational labels (≤ 64 entries, lowercase keys starting with a letter). |
| `sensitive_labels` | `object` | — | Secrets kept out of plain `labels`: `{auth_token, password, service_key}` — or the `_wo`/`_wo_version` write-only variants; see the secrets note. |

## Outputs

`channel_names` — map of channel key => full REST resource name
(`projects/{project}/notificationChannels/{id}`); pass these straight into
`gcp/monitoring` alert policies' `notification_channels`.
`channel_ids` — map of channel key => channel id.
`channel_verification_statuses` — map of channel key => verification
status.

## Example

```hcl
channels = {
  "emails" = {
    type         = "email"
    display_name = "example-team-mailbox"
    labels       = { email_address = "oncall@example.com" }
    user_labels  = { owner = "platform" }
  }
  "slack-oncall" = {
    type         = "slack"
    display_name = "example-slack-oncall"
    labels       = { channel_name = "#alerts" }
    sensitive_labels = {
      auth_token = "xoxb-example"
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not channel names.
- Sensitive values (`auth_token`, `password`, `service_key`) may be set
  either in `labels` or `sensitive_labels`, never both (validated). Use
  the `*_wo` write-only variants plus the matching `_version` to keep the
  value out of state entirely (validated).
- Type-specific label requirements vary; when bootstrapping a new channel
  type, create it once via the console and import to learn the schema
  (see Import).
- This module does not expose `deletion_policy`; it retains the provider
  default of `DELETE`.

## Import

`google_monitoring_notification_channel` ← the full resource name
`projects/{project}/notificationChannels/{id}` (no denominator-free
form here).
