variable "product_id" {
  description = "Property Manager product. [ION => Fresca, ION Premier => SPM, DSA => Site_Accel]"
  type        = string
  default     = "Site_Accel"
}

variable "cpcode_id" {
  description = "Default CP Code id."
  type        = number
  default     = null
}

variable "cpcode_name" {
  description = "Default CP Code name. Will be the property name (var.name) if null."
  type        = string
  default     = null
}

variable "default_origin" {
  description = "Default origin server for all properties"
  type        = string
}
variable "forward_host_header" {
  description = "Host header to be forwarded to the origin server. Possible fixed values are ORIGIN_HOSTNAME or REQUEST_HOST_HEADER. But the user can also select any host header they would like to use as a custom value."
  type        = string
  default     = "REQUEST_HOST_HEADER"
}

variable "additional_origins" {
  description = "Additional origins for the property. For now the match is only by hostname. The field forward_host_header allows specifying a custom host header for each additional origin.Possible fixed values are ORIGIN_HOSTNAME or REQUEST_HOST_HEADER. But the user can also select any host header they would like to use as a custom value."
  type = map(object({
    origin_name         = string
    forward_host_header = string
    hostname_match      = list(string)
    path_match          = list(string)
  }))
}

variable "sure_route_test_object" {
  description = "Test object path for SureRoute"
  type        = string
  default     = "/akamai/testobject.html"
}




