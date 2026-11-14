# Inputs. Required: admin_cidrs, ssh_public_key, state_passphrase (from TF_VAR_state_passphrase). Example values:
# terraform.tfvars.example (copy to terraform.tfvars, which git ignores).

variable "state_passphrase" {
  description = "Passphrase of the state and plan encryption (pbkdf2 + AES-GCM). Set TF_VAR_state_passphrase; never in a file."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.state_passphrase) >= 16
    error_message = "state_passphrase must be at least 16 characters (OpenTofu's pbkdf2 key provider minimum)."
  }
}

variable "region" {
  description = "Alibaba Cloud region id. Default Indonesia (Jakarta). Never a mainland China region (decision 76: ICP filing, slow or blocked ghcr.io pulls)."
  type        = string
  default     = "ap-southeast-5"

  validation {
    condition     = can(regex("^[a-z]+-[a-z]+(-[0-9]+)?$", var.region)) && (!startswith(var.region, "cn-") || var.region == "cn-hongkong")
    error_message = "region must be an Alibaba Cloud region id outside mainland China (e.g. ap-southeast-5; cn-hongkong is allowed)."
  }
}

variable "name" {
  description = "Name prefix of every resource."
  type        = string
  default     = "hoops"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}$", var.name))
    error_message = "name: 2 to 31 characters, lower-case letters, digits and hyphens, starting with a letter."
  }
}

variable "admin_cidrs" {
  description = "IPv4 CIDRs allowed to reach SSH (22) and the Kubernetes API (6443), e.g. [\"<your public IP>/32\"]. No default on purpose."
  type        = list(string)

  validation {
    condition     = length(var.admin_cidrs) > 0
    error_message = "admin_cidrs needs at least one CIDR (your public address as /32)."
  }
  validation {
    condition     = alltrue([for c in var.admin_cidrs : can(regex("^[0-9]{1,3}(\\.[0-9]{1,3}){3}/[0-9]{1,2}$", c)) && can(cidrnetmask(c))])
    error_message = "Every admin_cidrs entry must be an IPv4 CIDR such as 198.51.100.7/32."
  }
  validation {
    condition     = alltrue([for c in var.admin_cidrs : try(tonumber(split("/", c)[1]) >= 16, false)])
    error_message = "admin_cidrs entries may not be wider than /16 (never 0.0.0.0/0): SSH and the Kubernetes API stay closed to the internet."
  }
}

variable "ssh_public_key" {
  description = "OpenSSH public key (one line) for the instance's key pair; the only way to log in."
  type        = string

  validation {
    condition     = can(regex("^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp(256|384|521)) [A-Za-z0-9+/]+={0,3}( [^\\n]*)?$", trimspace(var.ssh_public_key)))
    error_message = "ssh_public_key must be one OpenSSH public key line (ssh-ed25519 recommended), never a private key."
  }
}

variable "instance_type" {
  description = "ECS instance type. The whole stack needs about 8 GiB (three JVM services, Keycloak, two PostgreSQL, Redpanda, Envoy); the plan fails below 8 GiB or when the region does not sell the type."
  type        = string
  default     = "ecs.g7.large"

  validation {
    condition     = can(regex("^ecs\\.[a-z0-9-]+\\.[a-z0-9]+$", var.instance_type))
    error_message = "instance_type must look like ecs.<family>.<size>, e.g. ecs.g7.large."
  }
}

variable "system_disk_category" {
  description = "System disk category (it holds the OS, the container images and k3s's local-path volumes)."
  type        = string
  default     = "cloud_essd"

  validation {
    condition     = contains(["cloud_essd", "cloud_auto", "cloud_essd_entry", "cloud_efficiency", "cloud_ssd"], var.system_disk_category)
    error_message = "system_disk_category: cloud_essd, cloud_auto, cloud_essd_entry, cloud_efficiency or cloud_ssd."
  }
}

variable "system_disk_size_gib" {
  description = "System disk size in GiB (OS, images, PostgreSQL and Redpanda volumes)."
  type        = number
  default     = 60

  validation {
    condition     = var.system_disk_size_gib >= 40 && var.system_disk_size_gib <= 500 && floor(var.system_disk_size_gib) == var.system_disk_size_gib
    error_message = "system_disk_size_gib: a whole number from 40 to 500."
  }
}

variable "eip_bandwidth_mbps" {
  description = "Bandwidth cap of the EIP in Mbit/s (billed by traffic)."
  type        = number
  default     = 10

  validation {
    condition     = var.eip_bandwidth_mbps >= 1 && var.eip_bandwidth_mbps <= 200 && floor(var.eip_bandwidth_mbps) == var.eip_bandwidth_mbps
    error_message = "eip_bandwidth_mbps: a whole number from 1 to 200."
  }
}

variable "dns_suffix" {
  description = "Free wildcard DNS service that resolves <a-b-c-d>.<suffix> to a.b.c.d (decision 78); OpenTofu manages no DNS record."
  type        = string
  default     = "sslip.io"

  validation {
    condition     = contains(["sslip.io", "nip.io"], var.dns_suffix)
    error_message = "dns_suffix: sslip.io or nip.io."
  }
}

variable "tags" {
  description = "Extra tags on every taggable resource."
  type        = map(string)
  default     = {}
}
