output "firewalls" {
  description = "Map of firewall key => object with `id` (string of the numeric firewall ID, also the import ID) and `applied_to` (list of provider attribute objects: `label_selector` and `server` — one of the two is empty depending on the attachment kind; values are read back raw, e.g. `server = 0` for label-attached firewalls)."
  value = { for k, f in hcloud_firewall.firewall : k => {
    id         = tostring(f.id)
    applied_to = f.apply_to
  } }
}
