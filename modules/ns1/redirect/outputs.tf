output "redirect_ids" {
  description = "Map of redirect key => redirect UUID."
  value       = { for key, redirect in ns1_redirect.redirect : key => redirect.id }
}

output "redirect_targets" {
  description = "Map of redirect key => target URL."
  value       = { for key, redirect in ns1_redirect.redirect : key => redirect.target }
}
