resource "google_dataflow_job" "job" {
  for_each = var.jobs

  name                         = each.value.name
  project                      = each.value.project_id
  template_gcs_path            = each.value.template_gcs_path
  temp_gcs_location            = each.value.temp_gcs_location
  parameters                   = each.value.parameters
  labels                       = each.value.labels
  transform_name_mapping       = each.value.transform_name_mapping
  max_workers                  = each.value.max_workers
  on_delete                    = each.value.on_delete
  skip_wait_on_job_termination = each.value.skip_wait_on_job_termination
  zone                         = each.value.zone
  region                       = each.value.region
  service_account_email        = each.value.service_account_email
  network                      = each.value.network
  subnetwork                   = each.value.subnetwork
  machine_type                 = each.value.machine_type
  kms_key_name                 = each.value.kms_key_name
  ip_configuration             = each.value.ip_configuration
  additional_experiments       = each.value.additional_experiments
  enable_streaming_engine      = each.value.enable_streaming_engine
  deletion_policy              = each.value.deletion_policy
}
