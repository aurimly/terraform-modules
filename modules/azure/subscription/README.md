# azure/subscription

Map-keyed module for Azure subscriptions. Each entry either creates a new
subscription under a billing scope (Enterprise Agreement enrollment account,
Microsoft Customer Agreement, or Microsoft Partner Agreement) through the
Subscription Alias API, or adopts an existing subscription under Terraform
management by placing an alias on it.

The managed resource is `azurerm_subscription`. Its resource ID is the alias
resource ID (`/providers/Microsoft.Subscription/aliases/<alias>`), not the
`/subscriptions/<id>` scope — see Outputs.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `subscriptions` | `map(object)` | — | Map of subscriptions keyed by an arbitrary unique ID. |

### `subscriptions` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `subscription_name` | `string` | — | Display name (the subscription's "Name" in the portal); 1–64 chars, cannot contain `<`, `>`, `;` or `|`. Renamed in place (a plain update). Validated client-side. |
| `billing_scope_id` | `string` | — | Billing scope to create the subscription under — see Notes for the three accepted forms. Mutually exclusive with `subscription_id` (XOR enforced per entry). Format validated. |
| `subscription_id` | `string` | — | GUID of an existing subscription to adopt. Mutually exclusive with `billing_scope_id` (XOR enforced per entry). Format validated. |
| `alias` | `string` | `null` | Alias name; the provider generates a GUID when omitted. Changing it forces replacement. Aliases must be unique across entries — the module rejects duplicates at plan time. |
| `workload` | `string` | `null` | `Production` (the API's create-time default) or `DevTest`. Only meaningful at creation; changing it forces replacement, and it is ignored when adopting an existing subscription (`subscription_id` set). |
| `tags` | `map(string)` | `{}` | Tags on the subscription. The tag set is authoritative — see Notes. Provider-enforced limits: 50 tags, keys ≤ 512 chars, values ≤ 256 chars. |

## Outputs

| Name | Description |
|---|---|
| `subscription_ids` | Map of key => subscription GUID (the UUID of the `/subscriptions/<id>` scope). Hand this to other Azure modules, e.g. `azure/subscription-iam`. |
| `alias_ids` | Map of key => alias resource ID (`/providers/Microsoft.Subscription/aliases/<alias>`), the `azurerm_subscription` resource ID and the import ID. |
| `tenant_ids` | Map of key => tenant GUID the subscription belongs to. |

## Example

```hcl
subscriptions = {
  "platform-prod" = {
    subscription_name = "Platform Production"
    billing_scope_id  = "/providers/Microsoft.Billing/billingAccounts/1234567890/enrollmentAccounts/0123456"
    alias             = "platform-prod"
    tags = {
      env = "prod"
    }
  }
  "platform-npd" = {
    subscription_name = "Platform Non-Production"
    billing_scope_id  = "/providers/Microsoft.Billing/billingAccounts/1234567890/billingProfiles/POY3-ZD33-BG7-TGB/invoiceSections/MTT4-OBS7-PJA-TGB"
    workload          = "DevTest"
  }
  "legacy-sub" = {
    subscription_name = "Legacy Example"
    subscription_id   = "12345678-1234-5678-9012-123456789012"
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not subscription names — multiple
  entries can share a display name. Give the `alias` a stable human-readable
  value (path-safe, unique); it is the only addressable handle in the Azure
  alias API and shows up in the import ID.
- Exactly one of `billing_scope_id` or `subscription_id` per entry. Both
  paths go through the same alias API: the create path also names and bills
  the new subscription, the adopt path only creates the alias against the
  existing one (and re-activates it first when it sits in a Disabled or
  Warned state; cancelling a subscription and adopting it again is refused).
  - Enrollment Account (EA):
    `/providers/Microsoft.Billing/billingAccounts/<billing-account>/enrollmentAccounts/<enrollment-account>`
  - Microsoft Customer Agreement (MCA):
    `/providers/Microsoft.Billing/billingAccounts/<billing-account>/billingProfiles/<billing-profile>/invoiceSections/<invoice-section>`
  - Microsoft Partner Agreement (MPA):
    `/providers/Microsoft.Billing/billingAccounts/<partner-billing-account>/customers/<customer>`
  The ID-form data sources `azurerm_billing_enrollment_account_scope`,
  `azurerm_billing_mca_account_scope` and `azurerm_billing_mpa_account_scope`
  produce these strings. The caller needs subscription-creation rights on
  the billing scope — e.g. the Subscription Creator role; Azure grants the
  alias creator the Owner role on the new subscription. A cancelled
  subscription's GUID can never be re-used — billing systems keep cancelled
  IDs forever.
- The alias is the resource identity. Azure technically allows several
  aliases per subscription, but the provider supports only one: creating or
  adopting a subscription that already has an alias (or two) fails. The
  `alias` and `workload` attributes are immutable (changing either replaces
  the subscription); `billing_scope_id` is not exposed by the API after
  creation and can never be updated in place.
- Subscription aliases carry their own RBAC scope, separate from the
  subscription. If a pre-existing alias cannot be read or written by the
  caller's principal, applies fail with 401 — an Alias owner or a Global
  Administrator (possibly after elevating global-admin access) must grant
  the caller Owner on the alias scope.
- Destroy is a cancellation, not a deletion: cancelled subscriptions are
  recoverable for 90 days, after which they are hopelessly gone, and a
  subscription that still holds resources cannot be cancelled at all —
  remove everything inside it first (unmanaged resources included). The
  provider's `features { subscription { prevent_cancellation_on_destroy } }`
  block disables the cancel-on-destroy behavior.
- Renaming (subscription_name) is a plain update. `workload` is immutable
  (changing it replaces the subscription); `billing_scope_id` and
  `subscription_id` are the dangerous half of the swap: changing either one
  does nothing on an existing subscription (the update path only renames
  and re-tags — the billing scope is not even exposed by the API after
  creation), while moving an entry from the create path to the adopt path
  *with a different* subscription GUID replaces the resource and thereby
  cancels the created subscription.
- Tags are authoritative for the subscription's tag set: the provider PUTs
  the full configured tag map, so tags added in the portal or CLI are
  removed on the next apply with tag changes. Manage subscription tags here
  or not at all.
- The provider needs `subscription_id` set in its provider block even for
  this resource (required by azurerm since 4.0) — point the provider config
  at any subscription the credentials can read; it does not have to be one
  managed here.
- Cross-tenancy: the alias API is tenant-scoped, so the provider's
  `tenant_id`/`client_id` must belong to the home tenant of the billing
  account; using a foreign tenant's principal usually fails with a
  permissions error.
- `subscription_id` validates loosely (8-4-4-4-12 hex, any casing); the
  module's check mirrors the provider's built-in GUID validation.

## Import

Subscriptions created by this resource (or through the Alias API) import via
the alias resource ID:

```shell
tofu import 'azurerm_subscription.subscription["<key>"]' "/providers/Microsoft.Subscription/aliases/<alias>"
```

A subscription that was never aliased has no alias ID to import. Do not
import it: pass `subscription_id` in the entry and run a plan — the provider
creates an alias against the existing subscription and assumes control
(review the plan carefully; it should show only the new alias resource).
