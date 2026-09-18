# gcp/vertex-ai-index

Map-keyed module for Google Cloud Vertex AI Vector Search indexes
(`google_vertex_ai_index`).

## Scope

The module creates indexes and manages their algorithm configuration,
update method, CMEK encryption, labels, and destroy protection. The
index contents themselves — JSONL or Parquet delta files in a Cloud
Storage bucket — are managed outside the module (pair with
`gcp/bucket`); the module only points at the delta directory.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `indexes` | `map(object)` | — | Map of indexes keyed by an arbitrary unique ID. |

### `indexes` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `display_name` | `string` | — | Up to 128 UTF-8 characters. |
| `region` | `string` | — | Region of the index, e.g. `europe-west4`; defaults to the provider-level region. Immutable — changing it forces replacement. |
| `project_id` | `string` | — | Project the index lives in; defaults to the provider-level project. |
| `description` | `string` | — | Free-form description. |
| `labels` | `map(string)` | `{}` | Keys/values up to 64 characters, no uppercase ASCII letters or spaces (validated); international characters allowed, matching the provider. Non-authoritative: labels set outside the config are left alone. |
| `index_update_method` | `string` | — | `BATCH_UPDATE` (provider default) or `STREAM_UPDATE` (case-sensitive, validated). Immutable — changing it forces replacement. |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (case-sensitive, validated). Provider default is `DELETE` — omitting it permits destroy; use `PREVENT` as the destroy guard. |
| `encryption_spec` | `object` | — | CMEK: `{kms_key_name}`. Immutable — changing it forces replacement. |
| `metadata` | `object` | — | Required; see the `metadata` object table. |
| `metadata.config` | `object` | — | Required; see the `config` object table. The whole block is immutable — changing it forces replacement. |

### `metadata` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `contents_delta_uri` | `string` | — | `gs://` Cloud Storage directory holding the delta files (validated). Required here although the provider marks it optional: the Matching Engine API rejects index creation without it. Changing it triggers a content rebuild (long-running; 180-minute timeout at the provider). |
| `is_complete_overwrite` | `bool` | `false` | Replace all existing index content with the data from `contents_delta_uri` on update. |

The expected file structure and format is described in Google's
[input data format](https://cloud.google.com/vertex-ai/docs/matching-engine/using-matching-engine#input-data-format)
documentation.

### `config` object (`metadata`)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `dimensions` | `number` | — | Number of dimensions of the input vectors; at least 1 (validated). |
| `approximate_neighbors_count` | `number` | — | Neighbors to find via approximate search before exact reordering. Required when tree-AH is used (validated) — the API rejects tree-AH without it. |
| `shard_size` | `string` | — | `SHARD_SIZE_SMALL` (2 GB), `SHARD_SIZE_MEDIUM` (20 GB) or `SHARD_SIZE_LARGE` (50 GB) (case-sensitive, validated). Immutable — changing it forces replacement. |
| `distance_measure_type` | `string` | — | `SQUARED_L2_DISTANCE`, `L1_DISTANCE`, `COSINE_DISTANCE` or `DOT_PRODUCT_DISTANCE` (case-sensitive, validated); provider default `DOT_PRODUCT_DISTANCE`. |
| `feature_norm_type` | `string` | — | `UNIT_L2_NORM` or `NONE` (case-sensitive, validated); provider default `NONE`. |
| `algorithm_config` | `object` | — | At most one of `tree_ah_config` or `brute_force_config` (validated). |

### `algorithm_config` object (`config`)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `tree_ah_config` | `object` | — | Tree-AH algorithm (shallow tree + asymmetric hashing): `{leaf_node_embedding_count, leaf_nodes_to_search_percent}`. Requires `approximate_neighbors_count` on `config`. |
| `brute_force_config` | `object` | — | Brute-force linear search; empty block (`{}`). |

`tree_ah_config` attributes: `leaf_node_embedding_count` — embeddings per
leaf node, provider default 1000; `leaf_nodes_to_search_percent` —
percentage of leaf nodes any query may search, 1–100 (validated),
provider default 10.

## Outputs

`index_ids` — map of index key => index id
(`projects/{project}/locations/{region}/indexes/{name}`). Wire this into
the `vertex-ai-index-endpoint` module's `deployed_indexes[*].index`.
`index_names` — map of index key => resource name of the index
(Google-assigned).
`index_deployed_indexes` — map of index key => `deployed_indexes` list
(output-only pointers to deployed indexes created from this index:
`{deployed_index_id, index_endpoint}`).
`index_stats` — map of index key => `{shards_count, vectors_count}`;
populated once the index contains data.
`index_update_times` — map of index key => last update timestamp
(RFC3339 UTC "Zulu" format). Compare against the
`vertex-ai-index-endpoint` module's `deployed_index_sync_times` to check
whether a deployed index has caught up with a batch update.

## Example

```hcl
indexes = {
  "treeah" = {
    display_name = "example-treeah-index"
    region       = "europe-west4"
    metadata = {
      contents_delta_uri = "gs://example-bucket/index-delta"
      config = {
        dimensions                  = 128
        approximate_neighbors_count = 100
        shard_size                  = "SHARD_SIZE_SMALL"
        distance_measure_type       = "DOT_PRODUCT_DISTANCE"
        algorithm_config = {
          tree_ah_config = {
            leaf_node_embedding_count    = 1000
            leaf_nodes_to_search_percent = 10
          }
        }
      }
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not resource names.
- Pair with `gcp/project-services` (`aiplatform.googleapis.com`) and
  `gcp/bucket` (the delta files); when using CMEK, with `gcp/kms` — the
  key must be in the same region as the index, and the Vertex AI service
  agent needs `roles/cloudkms.cryptoKeyEncrypterDecrypter` on the key
  (consumer-side).
- `BATCH_UPDATE` (default) updates content by calling `indexes.patch`
  with the GCS delta files under `contents_delta_uri`. `STREAM_UPDATE`
  applies upserts/deletes via the API to deployed indexes in near real
  time. `index_update_method` is immutable — changing it replaces the
  index.
- A `metadata.config` change (dimensions, shard size) or an
  `encryption_spec` change replaces the index. Replacing an index that
  has deployed indexes destroys the Terraform-managed deployed indexes
  first (a downtime window), then the index; the API refuses to delete
  an index whose deployed indexes are still live, so out-of-band
  deployments block deletion entirely. Plan `deletion_policy` and
  deployment churn accordingly.
- A `contents_delta_uri` change is a long-running content rebuild
  (180-minute create/update/delete timeouts at the provider) and cannot
  be combined with other field updates in one API call. Do not combine a
  contents change with a `display_name`/`labels`/etc. change in one
  apply — apply them separately.
- `deletion_policy` defaults to `DELETE` at the provider: omitting it
  permits `destroy`. Set `PREVENT` where destroy should fail.

## Import

`google_vertex_ai_index` ←
`projects/{project}/locations/{region}/indexes/{name}`,
`{project}/{region}/{name}`, `{region}/{name}`, or `{name}`.
