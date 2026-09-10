# stackit/key_pair

Map-keyed module for STACKIT SSH key pairs. Key pairs are global in the
STACKIT API — they carry no project or region.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `key_pairs` | `map(object)` | — | Map of key pairs keyed by an arbitrary unique ID. |

### `key_pairs` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Key pair name. Servers reference it via their `keypair_name`. Must be non-empty and must not contain a comma (the import ID is the bare name). Changing it replaces the key pair. |
| `public_key` | `string` | — | OpenSSH-format public key (`ssh-rsa`, `ssh-dss`, `ssh-ed25519` or `ecdsa-sha2-nistp256/384/521`). Changing it replaces the key pair. |
| `labels` | `map(string)` | `{}` | Labels attached to the key pair. IaaS label rule: keys 1–63 characters of letters, digits, `.`, `_`, `-`, starting and ending with a letter or digit, no reserved `stackit-` prefix; values follow the same shape or are empty. |

## Outputs

`key_pairs` — map of key pair key => object:

| Attribute | Description |
|---|---|
| `fingerprint` | Public key fingerprint. |
| `id` | The key pair name — also the import ID. |

## Example

```hcl
key_pairs = {
  "deploy" = {
    name       = "deploy-key"
    public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExamplePublicKeyMaterial comment@example"
    labels = {
      "env" = "prod"
    }
  }
  "ci" = {
    name       = "ci-key"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABExamplePublicKeyMaterial comment@example"
  }
}
```

Reference the key from a server entry of `modules/stackit/server`:

```hcl
servers = {
  "app" = {
    project_id    = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    name          = "app-server"
    machine_type  = "s3.2xlarge.8"
    region        = "eu01"
    image_id      = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    keypair_name  = "deploy-key"
  }
}
```

## Notes

- Key pairs are global: no `project_id` or `region` attribute exists.
- Replacing `public_key` does not update servers that were created with
  the old key — the new key is only injected into servers created
  afterwards. The provider warns about this on change; plan rotations
  accordingly.
- `name` must match what servers reference via `keypair_name`.
- The provider enforces no length or character rules on `name`; this
  module only rejects empty names and names containing a comma (which
  would break the comma-joined import ID scheme).
- The IaaS (Compute Engine) service must be enabled on the STACKIT
  project before key pairs can be created — unlike some other STACKIT
  services, creating IaaS resources does not auto-enable it.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_key_pair` ← `{name}`
