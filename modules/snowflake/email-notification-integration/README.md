# snowflake/email-notification-integration

Map-keyed module for Snowflake email notification integrations. Each entry
creates one `snowflake_email_notification_integration` — an account-level
object SQL can call (`SYSTEM$SEND_EMAIL`) to send email, typically from
alerts (and other SQL; resource monitors email directly via `notify_users`).

The integration resource is a **provider preview feature**
(`snowflake_email_notification_integration_resource`): enable it in the
provider configuration on the consumer unit with
`preview_features_enabled = ["snowflake_email_notification_integration_resource"]`,
or the resource is unknown to Terraform entirely. Preview features can change
without a provider major bump.

Requires the `snowflake` provider (`snowflakedb/snowflake`, Terraform-only —
OpenTofu is not tested against it) version 2.0.0 or newer.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `integrations` | `map(object)` | `{}` | Map of email notification integrations keyed by an arbitrary unique ID. |

Plan-time validation: `allowed_recipients` entries look like email addresses,
and names are unique across entries case-insensitively (Snowflake-enforced
uniqueness among integrations).

### `integrations` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Integration identifier; unique among integrations in the account. Referenced from SQL exactly as written (e.g. the first argument of `SYSTEM$SEND_EMAIL`). |
| `enabled` | `bool` | — | `true` for the integration to function; `false` suspends it. Provider-required. |
| `allowed_recipients` | `list(string)` | `null` | Email addresses allowed as recipients. Each address must first exist as a user in the account with a verified email, or apply fails. |
| `comment` | `string` | `null` | Free-form description shown in `SHOW INTEGRATIONS`. |

## Outputs

| Name | Description |
|---|---|
| `integration_fully_qualified_names` | Map of key => fully qualified name — pass into alert actions or other SQL (`SYSTEM$SEND_EMAIL`), and mention in GRANT statements. |
| `integration_ids` | Map of key => Terraform provider ID (constructed identifier for data sources, grants and imports). |

## Example

```hcl
integrations = {
  "monitoring" = {
    name               = "NTF_MONITORING"
    enabled            = true
    allowed_recipients = ["oncall@example.com", "ops@example.com"]
    comment            = "on-call notifications for monitoring alerts"
  }
}
```

## Notes

- The role running Terraform needs CREATE INTEGRATION on the account.
- Sending works only to `allowed_recipients`, and only when every recipient
  matches a user's verified email in this account — the check is account-local.
- The integration authorizes sends; it does not grant the privilege to call
  `SYSTEM$SEND_EMAIL`. Bind `integration_fully_qualified_names["<key>"]` to
  roles with a consecutive grant (usage grants wiring is deferred from this
  round).

## Import

`terraform import 'snowflake_email_notification_integration.integration["<key>"]' <name>`
