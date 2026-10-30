resource "google_essential_contacts_contact" "contact" {
  for_each = var.contacts

  parent                              = each.value.parent
  email                               = each.value.email
  language_tag                        = each.value.language_tag
  notification_category_subscriptions = each.value.notification_category_subscriptions
  deletion_policy                     = each.value.deletion_policy
}
