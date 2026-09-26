resource "aws_cloudwatch_log_group" "log_group" {
  for_each = var.log_groups

  name                        = each.value.name
  name_prefix                 = each.value.name_prefix
  retention_in_days           = each.value.retention_in_days
  kms_key_id                  = each.value.kms_key_id
  log_group_class             = each.value.log_group_class
  skip_destroy                = each.value.skip_destroy
  deletion_protection_enabled = each.value.deletion_protection_enabled

  tags = each.value.tags
}

resource "aws_cloudwatch_metric_alarm" "alarm" {
  for_each = var.metric_alarms

  alarm_name                = each.value.alarm_name
  alarm_description         = each.value.alarm_description
  namespace                 = each.value.namespace
  metric_name               = each.value.metric_name
  dimensions                = each.value.dimensions
  statistic                 = each.value.statistic
  extended_statistic        = each.value.extended_statistic
  period                    = each.value.period
  evaluation_periods        = each.value.evaluation_periods
  datapoints_to_alarm       = each.value.datapoints_to_alarm
  threshold                 = each.value.threshold
  comparison_operator       = each.value.comparison_operator
  treat_missing_data        = each.value.treat_missing_data
  unit                      = each.value.unit
  actions_enabled           = each.value.actions_enabled
  alarm_actions             = each.value.alarm_actions
  ok_actions                = each.value.ok_actions
  insufficient_data_actions = each.value.insufficient_data_actions

  tags = each.value.tags
}

resource "aws_cloudwatch_dashboard" "dashboard" {
  for_each = var.dashboards

  dashboard_name = each.value.dashboard_name
  dashboard_body = each.value.dashboard_body
}
