output "images" {
  description = "Map of image key => object with `image_id` (UUID, feed into server `image_id` or volume `source.id`), `checksum_algorithm`, `checksum_digest`, `protected`, `scope` and `id` (\"{project_id},{region},{image_id}\", the import ID)."
  value = { for k, i in stackit_image.image : k => {
    image_id           = i.image_id
    checksum_algorithm = i.checksum != null ? i.checksum.algorithm : null
    checksum_digest    = i.checksum != null ? i.checksum.digest : null
    protected          = i.protected
    scope              = i.scope
    id                 = i.id
  } }
}
