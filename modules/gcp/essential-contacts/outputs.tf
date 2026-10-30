output "contact_names" {
  description = "Map of contacts key => full resource name (organizations/{id}/contacts/{contact_id} or the folder/project equivalent)."
  value       = { for k, c in google_essential_contacts_contact.contact : k => c.name }
}
