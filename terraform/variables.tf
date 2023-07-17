variable "latest_image_tag" {
  description = "Tag of the latest pagevigil image"
  type        = string
}
variable "errors_email" {
  description = "Email that will receive errors from PageVigil's Lambda"
  type        = string
}
