variable "name" {
  type        = string
  description = "The name of the oracle-db StatefulSet and Service"
  default     = "oracle_23ai_db"
}

variable "namespace" {
  type    = string
  description = "The namespace of the oracle-db StatefulSet and Service"
}

variable "replicas" {
  type    = number
  default = 1
}

variable "storage_size" {
  type    = string
  default = "50Gi"
}

variable "image" {
  type    = string
  default = "container-registry.oracle.com/database/free:latest"
}

variable "service_port" {
  type    = number
  default = 1521
}

variable "container_port" {
  type    = number
  default = 1521
}

variable "oracle_pwd" {
  type        = string
  default     = "topSecretpa33word"
  description = "Oracle database password."
}

variable "oracle_characterset" {
  type    = string
  default = "AL32UTF8"
  description = "Oracle database character set."
}
