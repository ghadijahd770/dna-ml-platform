variable "team_name" {
  description = "Short team name used in resource names, e.g. dna. Comes from the team file name."
  type        = string
}

variable "team" {
  description = "The team's settings, decoded from requests/teams/<team>.yaml."
  type        = any
}

variable "platform" {
  description = "Outputs of the platform stack (location, naming, Log Analytics, action group, CI identity, platform admins)."
  type        = any
}

variable "tenant_id" {
  description = "Entra tenant ID."
  type        = string
}

variable "subscription_id" {
  description = "Subscription ID, used to make globally unique names."
  type        = string
}
