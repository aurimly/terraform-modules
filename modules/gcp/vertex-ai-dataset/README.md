# gcp/vertex-ai-dataset

Map-keyed module for Google Cloud Vertex AI datasets
(`google_vertex_ai_dataset`).

## Scope

The module creates datasets and manages their metadata schema, CMEK
encryption, labels, and destroy protection. Data ingestion (DataItems)
happens outside Terraform — through the Vertex AI SDK, console, or
pipelines — as the resource exposes no data-import attribute.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `datasets` | `map(object)` | — | Map of datasets keyed by an arbitrary unique ID. |

### `datasets` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `display_name` | `string` | — | Up to 128 UTF-8 characters. |
| `metadata_schema_uri` | `string` | — | `gs://` URI of the dataset metadata schema YAML (validated); schemas are published under `gs://google-cloud-aiplatform/schema/dataset/metadata/`. Immutable — changing it forces replacement. |
| `region` | `string` | — | Region of the dataset, e.g. `europe-west4`; defaults to the provider-level region. |
| `project_id` | `string` | — | Project the dataset lives in; defaults to the provider-level project. |
| `labels` | `map(string)` | `{}` | Keys/values up to 64 characters, no uppercase ASCII letters or spaces (validated); international characters allowed, matching the provider. Non-authoritative: labels set outside the config are left alone. |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (case-sensitive, validated). Provider default is `DELETE` — omitting it permits destroy; use `PREVENT` as the destroy guard. |
| `encryption_spec` | `object` | — | CMEK: `{kms_key_name}`. Immutable — changing it forces replacement. |

### `encryption_spec` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `kms_key_name` | `string` | — | `projects/{project}/locations/{region}/keyRings/{key-ring}/cryptoKeys/{key}` (format validated); the key must be in the same region as the dataset. |

## Outputs

`dataset_ids` — map of dataset key => dataset id
(`projects/{project}/locations/{region}/datasets/{name}`).
`dataset_names` — map of dataset key => resource name of the dataset
(Google-assigned).
`dataset_create_times` — map of dataset key => creation timestamp
(RFC3339 UTC "Zulu" format).

## Example

```hcl
datasets = {
  "images" = {
    display_name        = "example-dataset"
    metadata_schema_uri = "gs://google-cloud-aiplatform/schema/dataset/metadata/image_1.0.0.yaml"
    region              = "europe-west4"
    labels = {
      env = "example"
    }
  }
  "encrypted" = {
    display_name        = "example-cmek-dataset"
    metadata_schema_uri = "gs://google-cloud-aiplatform/schema/dataset/metadata/tabular_1.0.0.yaml"
    deletion_policy     = "PREVENT"
    encryption_spec = {
      kms_key_name = "projects/example-prj/locations/europe-west4/keyRings/example-kr/cryptoKeys/example-key"
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not resource names.
- Pair with `gcp/project-services` (`aiplatform.googleapis.com`) and,
  when using CMEK, with `gcp/kms` — the key must be in the same region
  as the dataset, and the Vertex AI service agent needs
  `roles/cloudkms.cryptoKeyEncrypterDecrypter` on the key (consumer-side).
- The resource has 20-minute create/update/delete timeouts at the
  provider.
- `metadata_schema_uri` and `encryption_spec` are immutable (ForceNew at
  the provider); everything else updates in place.
- Existing datasets cannot be adopted: the resource supports no
  Terraform import, and data ingestion happens outside Terraform.
- `deletion_policy` defaults to `DELETE` at the provider: omitting it
  permits `destroy`. Set `PREVENT` where destroy should fail. There is
  no `force_destroy` attribute — `deletion_policy` is the only control.
- Create the bucket holding the metadata schema YAML via `gcp/bucket`
  when hosting a custom schema; Google-published schemas under
  `gs://google-cloud-aiplatform/` need no bucket.

## Import

Not supported — `google_vertex_ai_dataset` does not support import.
