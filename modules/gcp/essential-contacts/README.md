# gcp/essential-contacts

Map-keyed module for Google Cloud essential contacts. Each entry creates one
`google_essential_contacts_contact` at the given parent — organization,
folder, or project — subscribed to one or more notification categories.
The API allows **one contact per (parent, email)**; carry several categories
on one contact row (the API rejects a second contact with the same email and
points to UpdateContact for new subscriptions).

## Auth

Organization- and folder-parented contacts on user-ADC runs need
`user_project_override = true` plus `billing_project = "<consumer project>"`
in the provider configuration; the Essential Contacts API 403s otherwise
(provider docs warning). The consumer project must have
`essentialcontacts.googleapis.com` enabled.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `contacts` | `map(object)` | `{}` | Contacts keyed by an arbitrary identifier (typically the notification category). |

### `contacts` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `email` | `string` | — | Notification recipient. Does not need to be a Google account. |
| `parent` | `string` | — | `organizations/{numeric id}`, `folders/{numeric id}` or `projects/{project_id}`. |
| `notification_category_subscriptions` | `list(string)` | — | Non-empty subset of `ALL`, `BILLING`, `LEGAL`, `SECURITY`, `SUSPENSION`, `TECHNICAL`. `ALL` cannot combine with others. |
| `language_tag` | `string` | `"en"` | Preferred notification language (ISO 639-1). |
| `deletion_policy` | `string` | `"PREVENT"` | `DELETE` destroys the contact with the unit; `ABANDON` removes it from state and leaves it live; `PREVENT` fails any removal path — flip to `ABANDON`, apply, then drop the entry. |

## Outputs

`contact_names` — map of contacts key => full resource name
(`organizations/{id}/contacts/{contact_id}` or the folder/project
equivalent).

## Import

- `google_essential_contacts_contact` ← `<name>`
  (e.g. `organizations/123456789012/contacts/abc123`)

## Example

```hcl
contacts = {
  "admin" = {
    email                               = "sec@example.com"
    parent                              = "organizations/123456789012"
    notification_category_subscriptions = ["SECURITY", "TECHNICAL", "BILLING"]
  }
}
```
