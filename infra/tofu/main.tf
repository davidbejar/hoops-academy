locals {
  # k3s on the Kubernetes minor kind runs (kindest/node v1.36, inside Envoy Gateway v1.10's 1.34-1.37 range). Bump the
  # three values together: the install script of the release's git tag and the amd64 binary of its release page
  # (sha256sum-amd64.txt). Sources: ADR-0050.
  k3s = {
    version               = "v1.36.6+k3s1"
    install_script_sha256 = "46177d4c99440b4c0311b67233823a8e8a2fc09693f6c89af1a7161e152fbfad"
    binary_sha256         = "66ceb8e67edfa547195135d74783bfadc2ecc04a91059e90ae5f70a3dbc98c15"
  }

  min_memory_gib = 8
  # Outside k3s's pod (10.42.0.0/16) and service (10.43.0.0/16) ranges.
  vpc_cidr     = "172.20.0.0/16"
  vswitch_cidr = cidrsubnet(local.vpc_cidr, 8, 1)
  zone_id      = data.alicloud_zones.available.ids[0]

  public_ip = alicloud_eip_address.public.ip_address
  # sslip.io / nip.io answer <a-b-c-d>.<suffix> (and every name under it) with a.b.c.d (decision 78).
  hostname = "${replace(local.public_ip, ".", "-")}.${var.dns_suffix}"

  web_ports = { http = 80, https = 443 }
  tags      = merge({ project = "hoops-academy", managed-by = "opentofu" }, var.tags)
}

# ---------------------------------------------------------------------------------------------------------------------
# Lookups: a zone that sells the instance type, the type's size, the newest Ubuntu 24.04 system image.

data "alicloud_zones" "available" {
  available_instance_type     = var.instance_type
  available_resource_creation = "VSwitch"

  lifecycle {
    postcondition {
      condition     = length(self.ids) > 0
      error_message = "No zone of ${var.region} sells ${var.instance_type} for a VSwitch instance right now: pick another instance_type (docs/runbooks/cloud.md, step 2)."
    }
  }
}

data "alicloud_instance_types" "selected" {
  instance_type = var.instance_type

  lifecycle {
    postcondition {
      condition     = length(self.instance_types) == 1 && try(self.instance_types[0].memory_size >= local.min_memory_gib, false)
      error_message = "${var.instance_type} must exist and have at least ${local.min_memory_gib} GiB of memory: the stack (three JVM services, Keycloak, two PostgreSQL, Redpanda, Envoy) needs about 8 GiB."
    }
  }
}

data "alicloud_images" "ubuntu" {
  owners        = "system"
  name_regex    = "^ubuntu_24_04_x64_20G_alibase_[0-9]{8}\\.vhd$"
  most_recent   = true
  architecture  = "x86_64"
  os_type       = "linux"
  instance_type = var.instance_type

  lifecycle {
    postcondition {
      condition     = length(self.ids) > 0
      error_message = "No Ubuntu 24.04 x86_64 system image for ${var.instance_type} in ${var.region}."
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Network: one VPC, one vSwitch, one security group. Inbound: SSH and the Kubernetes API from admin_cidrs only, HTTP and
# HTTPS from everyone; nothing else (the NodePort range stays closed). Outbound: the security group's default (all), k3s
# pulls its images from ghcr.io, quay.io and docker.io.

resource "alicloud_vpc" "this" {
  vpc_name    = var.name
  cidr_block  = local.vpc_cidr
  description = "Hoops Academy k3s (WP104)"
  tags        = local.tags
}

resource "alicloud_vswitch" "this" {
  vswitch_name = var.name
  vpc_id       = alicloud_vpc.this.id
  cidr_block   = local.vswitch_cidr
  zone_id      = local.zone_id
  tags         = local.tags
}

resource "alicloud_security_group" "this" {
  security_group_name = var.name
  vpc_id              = alicloud_vpc.this.id
  description         = "Hoops Academy k3s: 22 and 6443 from the admin CIDRs, 80 and 443 public"
  tags                = local.tags
}

resource "alicloud_security_group_rule" "ssh" {
  for_each = toset(var.admin_cidrs)

  security_group_id = alicloud_security_group.this.id
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet" # VPC security groups: the rule applies to every interface
  policy            = "accept"
  port_range        = "22/22"
  cidr_ip           = each.value
  description       = "SSH from an admin CIDR"
}

resource "alicloud_security_group_rule" "kube_api" {
  for_each = toset(var.admin_cidrs)

  security_group_id = alicloud_security_group.this.id
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "6443/6443"
  cidr_ip           = each.value
  description       = "Kubernetes API (k3s) from an admin CIDR"
}

resource "alicloud_security_group_rule" "web" {
  for_each = local.web_ports

  security_group_id = alicloud_security_group.this.id
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "${each.value}/${each.value}"
  cidr_ip           = "0.0.0.0/0" # the public web app (Envoy Gateway); SSH and the API never get this
  description       = "Envoy Gateway ${each.key} (public)"
}

# ---------------------------------------------------------------------------------------------------------------------
# Access and address: the admin's public key; an EIP that outlives the instance, so the hostname, the API certificate and
# the Keycloak issuer survive a rebuild.

resource "alicloud_ecs_key_pair" "admin" {
  key_pair_name = "${var.name}-admin"
  public_key    = trimspace(var.ssh_public_key)
  tags          = local.tags
}

resource "alicloud_eip_address" "public" {
  address_name         = "${var.name}-k3s"
  description          = "Hoops Academy k3s (WP104): the deployment's public address and wildcard name"
  payment_type         = "PayAsYouGo"
  internet_charge_type = "PayByTraffic"
  bandwidth            = tostring(var.eip_bandwidth_mbps)
  isp                  = "BGP"
  tags                 = local.tags
}

# ---------------------------------------------------------------------------------------------------------------------
# The VM: k3s from cloud-init (templates/cloud-init.yaml.tftpl), no password, no public IP of its own, metadata only in
# security-enhanced mode (IMDSv2: no SSRF path to the instance's metadata), encrypted system disk.

resource "alicloud_instance" "k3s" {
  instance_name        = "${var.name}-k3s"
  host_name            = "${var.name}-k3s"
  instance_type        = var.instance_type
  instance_charge_type = "PostPaid"
  image_id             = data.alicloud_images.ubuntu.ids[0]
  vswitch_id           = alicloud_vswitch.this.id
  security_groups      = [alicloud_security_group.this.id]
  key_name             = alicloud_ecs_key_pair.admin.key_pair_name

  internet_max_bandwidth_out = 0

  system_disk_category  = var.system_disk_category
  system_disk_size      = var.system_disk_size_gib
  system_disk_encrypted = var.system_disk_encrypted

  http_endpoint       = "enabled"
  http_tokens         = "required"
  deletion_protection = false

  user_data = base64encode(templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
    public_ip             = local.public_ip
    hostname              = local.hostname
    k3s_version           = local.k3s.version
    install_script_sha256 = local.k3s.install_script_sha256
    binary_sha256         = local.k3s.binary_sha256
  }))

  tags        = local.tags
  volume_tags = local.tags

  lifecycle {
    # A newer Ubuntu image (most_recent) would replace the system disk in place, wiping k3s and every volume; cloud-init
    # runs only on the first boot anyway. Rebuild on purpose with `tofu apply -replace=alicloud_instance.k3s`.
    ignore_changes = [image_id, user_data]
  }
}

resource "alicloud_eip_association" "k3s" {
  allocation_id = alicloud_eip_address.public.id
  instance_id   = alicloud_instance.k3s.id
}
