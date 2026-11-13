output "widget_sitekeys" {
  description = "Map of widget key => sitekey (the public identifier used in the frontend snippet; the widget's ID equals the sitekey, so it doubles as the import identifier)."
  value       = { for key, widget in cloudflare_turnstile_widget.widget : key => widget.sitekey }
}

output "widget_secret_keys" {
  description = "Map of widget key => secret key (sensitive). Persisted in state like any output — prefer fetching secrets via the API for environments where state storage is not trusted."
  value       = { for key, widget in cloudflare_turnstile_widget.widget : key => widget.secret }
  sensitive   = true
}
