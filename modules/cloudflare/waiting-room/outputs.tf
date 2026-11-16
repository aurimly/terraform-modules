output "waiting_room_ids" {
  description = "Map of room key => waiting room ID."
  value       = { for key, room in cloudflare_waiting_room.waiting_room : key => room.id }
}

output "event_ids" {
  description = "Map of \"<room-key>.<event-key>\" => event ID (the import identifier is <zone_id>/<waiting_room_id>/<this ID>)."
  value       = { for key, event in cloudflare_waiting_room_event.event : key => event.id }
}
