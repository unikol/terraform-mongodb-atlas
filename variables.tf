variable "MONGODB_ATLAS_ORGANIZATION_ID" {
  default = "Is not variable there"
  type    = string
}
variable "MONGODB_ATLAS_PUBLIC_KEY" {
  default = "Is not variable there"
  type    = string
}
variable "MONGODB_ATLAS_PRIVATE_KEY" {
  default = "Is not variable there"
  type    = string
}
variable "MONGODB_ATLAS_DB_PASSWORD" {
  description = "Password for MongoDB Atlas database user bob"
  type        = string
  sensitive   = true
}