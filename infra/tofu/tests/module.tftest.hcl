# OpenTofu tests of the k3s module (WP104, ADR-0050). Every run is a `plan` against the mocked Alibaba Cloud provider below:
# no credential, no API call, nothing created. The mocks stand in for what the real data sources return in
# ap-southeast-5; the address is from TEST-NET-3 (RFC 5737). Sections: inputs, network, instance, outputs.

mock_provider "alicloud" {
  mock_data "alicloud_zones" {
    defaults = {
      ids = ["ap-southeast-5a", "ap-southeast-5b"]
    }
  }

  # Complete objects: OpenTofu requires every attribute of a mocked object.
  mock_data "alicloud_instance_types" {
    defaults = {
      ids = ["ecs.g7.large"]
      instance_types = [
        {
          availability_zones              = []
          burstable_instance              = []
          cpu_core_count                  = 2
          eni_amount                      = 0
          eni_ipv6_address_quantity       = 0
          eni_private_ip_address_quantity = 0
          eni_quantity                    = 0
          family                          = "ecs.g7"
          gpu                             = []
          id                              = "ecs.g7.large"
          local_storage                   = []
          maximum_queue_number_per_eni    = 0
          memory_size                     = 8
          nvme_support                    = ""
          price                           = ""
          primary_eni_queue_number        = 0
          secondary_eni_queue_number      = 0
          total_eni_queue_quantity        = 0
        },
      ]
    }
  }

  mock_data "alicloud_images" {
    defaults = {
      ids = ["ubuntu_24_04_x64_20G_alibase_20261016.vhd"]
    }
  }

  mock_resource "alicloud_eip_address" {
    defaults = {
      ip_address = "203.0.113.10"
    }
  }
}

variables {
  state_passphrase = "tofu-test-only-not-a-real-passphrase"
  admin_cidrs      = ["198.51.100.7/32"]
  ssh_public_key   = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHRvZnUtdGVzdC1vbmx5LW5vdC1hLXJlYWwta2V5 tofu-test"
}


# --------------------------------------------------------------------------------------------------------------------
# Input guards (WP104, ADR-0050): no world-open admin access, never a mainland region, a public key only, a state
# passphrase long enough for OpenTofu's pbkdf2 key provider, a known wildcard DNS service.
run "defaults_target_jakarta_with_sslip_io" {
  command = plan

  assert {
    condition     = var.region == "ap-southeast-5"
    error_message = "The default region is Indonesia (Jakarta), ap-southeast-5 (decision 76)."
  }
  assert {
    condition     = var.dns_suffix == "sslip.io"
    error_message = "The default wildcard DNS service is sslip.io (decision 78)."
  }
}

run "refuses_ssh_and_api_open_to_the_world" {
  command = plan
  variables {
    admin_cidrs = ["0.0.0.0/0"]
  }
  expect_failures = [var.admin_cidrs]
}

run "refuses_an_admin_cidr_wider_than_a_slash_16" {
  command = plan
  variables {
    admin_cidrs = ["198.51.100.7/32", "100.64.0.0/10"]
  }
  expect_failures = [var.admin_cidrs]
}

run "refuses_no_admin_cidr" {
  command = plan
  variables {
    admin_cidrs = []
  }
  expect_failures = [var.admin_cidrs]
}

run "refuses_a_malformed_admin_cidr" {
  command = plan
  variables {
    admin_cidrs = ["198.51.100.7"]
  }
  expect_failures = [var.admin_cidrs]
}

run "refuses_a_mainland_china_region" {
  command = plan
  variables {
    region = "cn-hangzhou"
  }
  expect_failures = [var.region]
}

run "accepts_hong_kong" {
  command = plan
  variables {
    region = "cn-hongkong"
  }
  assert {
    condition     = var.region == "cn-hongkong"
    error_message = "Hong Kong is outside mainland China (no ICP filing) and allowed."
  }
}

run "refuses_something_that_is_not_an_ssh_public_key" {
  command = plan
  variables {
    ssh_public_key = "AAAAC3NzaC1lZDI1NTE5AAAAIHRvZnUtdGVzdC1vbmx5LW5vdC1hLXJlYWwta2V5"
  }
  expect_failures = [var.ssh_public_key]
}

run "refuses_a_short_state_passphrase" {
  command = plan
  variables {
    state_passphrase = "too-short"
  }
  expect_failures = [var.state_passphrase]
}

run "refuses_an_unknown_wildcard_dns_service" {
  command = plan
  variables {
    dns_suffix = "example.com"
  }
  expect_failures = [var.dns_suffix]
}

run "refuses_a_system_disk_too_small_for_images_and_volumes" {
  command = plan
  variables {
    system_disk_size_gib = 30
  }
  expect_failures = [var.system_disk_size_gib]
}


# --------------------------------------------------------------------------------------------------------------------
# Security group (WP104, ADR-0050): SSH and the Kubernetes API only from the admin CIDRs, the web ports for everyone,
# nothing else.
run "ssh_only_from_the_admin_cidrs" {
  command = plan

  assert {
    condition     = toset([for r in alicloud_security_group_rule.ssh : r.cidr_ip]) == toset(var.admin_cidrs)
    error_message = "SSH must be open to exactly the admin CIDRs."
  }
  assert {
    condition = alltrue([for r in alicloud_security_group_rule.ssh :
    r.type == "ingress" && r.ip_protocol == "tcp" && r.port_range == "22/22" && r.policy == "accept" && r.nic_type == "intranet"])
    error_message = "SSH rules must accept tcp 22 inbound and nothing else."
  }
}

run "kubernetes_api_only_from_the_admin_cidrs" {
  command = plan

  assert {
    condition     = toset([for r in alicloud_security_group_rule.kube_api : r.cidr_ip]) == toset(var.admin_cidrs)
    error_message = "The Kubernetes API must be open to exactly the admin CIDRs."
  }
  assert {
    condition = alltrue([for r in alicloud_security_group_rule.kube_api :
    r.type == "ingress" && r.ip_protocol == "tcp" && r.port_range == "6443/6443" && r.policy == "accept" && r.nic_type == "intranet"])
    error_message = "Kubernetes API rules must accept tcp 6443 inbound and nothing else."
  }
}

run "web_ports_open_to_everyone_and_nothing_else_is" {
  command = plan

  assert {
    condition     = toset([for r in alicloud_security_group_rule.web : r.port_range]) == toset(["80/80", "443/443"])
    error_message = "The web rules must be exactly HTTP 80 and HTTPS 443."
  }
  assert {
    condition     = alltrue([for r in alicloud_security_group_rule.web : r.type == "ingress" && r.ip_protocol == "tcp" && r.cidr_ip == "0.0.0.0/0" && r.policy == "accept" && r.nic_type == "intranet"])
    error_message = "HTTP and HTTPS are public (tcp from 0.0.0.0/0)."
  }
  assert {
    condition = alltrue([for r in concat(values(alicloud_security_group_rule.ssh), values(alicloud_security_group_rule.kube_api), values(alicloud_security_group_rule.web)) :
    r.cidr_ip != "0.0.0.0/0" || contains(["80/80", "443/443"], r.port_range)])
    error_message = "Only 80 and 443 may be open to 0.0.0.0/0 (no NodePort range, no SSH, no API)."
  }
  assert {
    condition = alltrue([for r in concat(values(alicloud_security_group_rule.ssh), values(alicloud_security_group_rule.kube_api), values(alicloud_security_group_rule.web)) :
    r.security_group_id == alicloud_security_group.this.id])
    error_message = "Every rule belongs to the instance's security group."
  }
}

run "one_vpc_one_vswitch_in_a_zone_that_sells_the_instance_type" {
  command = plan

  assert {
    condition     = alicloud_vswitch.this.zone_id == "ap-southeast-5a"
    error_message = "The vSwitch goes into the first zone that sells the instance type."
  }
  assert {
    condition     = alicloud_vswitch.this.vpc_id == alicloud_vpc.this.id && alicloud_security_group.this.vpc_id == alicloud_vpc.this.id
    error_message = "vSwitch and security group belong to the module's VPC."
  }
  assert {
    condition     = cidrsubnet(alicloud_vpc.this.cidr_block, 8, 1) == alicloud_vswitch.this.cidr_block
    error_message = "The vSwitch CIDR lies inside the VPC CIDR."
  }
  assert {
    # k3s uses 10.42.0.0/16 for pods and 10.43.0.0/16 for services: the VPC must not overlap them
    condition     = !startswith(alicloud_vpc.this.cidr_block, "10.")
    error_message = "The VPC CIDR must not overlap the k3s pod and service CIDRs (10.42/16, 10.43/16)."
  }
}


# --------------------------------------------------------------------------------------------------------------------
# The k3s VM (WP104, ADR-0050): sized for the whole stack (8 GiB), a current Ubuntu 24.04 image, key-only SSH, no public
# address of its own (the EIP is the address), IMDSv2 only, encrypted system disk, k3s pinned and verified by cloud-init.
run "sized_for_the_whole_stack" {
  command = plan

  assert {
    condition     = alicloud_instance.k3s.instance_type == var.instance_type && var.instance_type == "ecs.g7.large"
    error_message = "Default instance type: ecs.g7.large (2 vCPU, 8 GiB)."
  }
  assert {
    condition     = data.alicloud_instance_types.selected.instance_types[0].memory_size >= 8
    error_message = "The instance type must have at least 8 GiB of memory."
  }
  assert {
    condition     = alicloud_instance.k3s.system_disk_size >= 60 && alicloud_instance.k3s.system_disk_encrypted == true
    error_message = "System disk: at least 60 GiB (images and the local-path volumes live there), encrypted."
  }
  assert {
    condition     = alicloud_instance.k3s.instance_charge_type == "PostPaid" && alicloud_instance.k3s.deletion_protection == false
    error_message = "Pay-as-you-go and destroyable: a test deployment is torn down with tofu destroy."
  }
}

run "refuses_an_instance_type_with_less_than_8_gib" {
  command = plan
  variables {
    instance_type = "ecs.g7.medium"
  }
  override_data {
    target = data.alicloud_instance_types.selected
    values = {
      ids = ["ecs.g7.medium"]
      instance_types = [
        {
          availability_zones              = []
          burstable_instance              = []
          cpu_core_count                  = 1
          eni_amount                      = 0
          eni_ipv6_address_quantity       = 0
          eni_private_ip_address_quantity = 0
          eni_quantity                    = 0
          family                          = "ecs.g7"
          gpu                             = []
          id                              = "ecs.g7.medium"
          local_storage                   = []
          maximum_queue_number_per_eni    = 0
          memory_size                     = 4
          nvme_support                    = ""
          price                           = ""
          primary_eni_queue_number        = 0
          secondary_eni_queue_number      = 0
          total_eni_queue_quantity        = 0
        },
      ]
    }
  }
  expect_failures = [data.alicloud_instance_types.selected]
}

run "refuses_an_instance_type_the_region_does_not_sell" {
  command = plan
  override_data {
    target = data.alicloud_zones.available
    values = {
      ids   = []
      zones = []
    }
  }
  expect_failures = [data.alicloud_zones.available]
}

run "current_ubuntu_lts_image_that_never_rebuilds_the_disk_by_itself" {
  command = plan

  assert {
    condition     = alicloud_instance.k3s.image_id == "ubuntu_24_04_x64_20G_alibase_20261016.vhd"
    error_message = "The image is the newest Ubuntu 24.04 x64 system image the data source found."
  }
  assert {
    condition     = data.alicloud_images.ubuntu.owners == "system" && data.alicloud_images.ubuntu.most_recent == true
    error_message = "Only Alibaba Cloud system images, the most recent one."
  }
}

run "key_only_access_imds_v2_and_no_own_public_address" {
  command = plan

  assert {
    condition     = alicloud_instance.k3s.key_name == alicloud_ecs_key_pair.admin.key_pair_name
    error_message = "Login with the module's key pair."
  }
  assert {
    condition     = alicloud_ecs_key_pair.admin.public_key == var.ssh_public_key
    error_message = "The key pair holds the given public key."
  }
  assert {
    condition     = alicloud_instance.k3s.password == null && alicloud_instance.k3s.kms_encrypted_password == null
    error_message = "No instance password, ever."
  }
  assert {
    condition     = alicloud_instance.k3s.http_tokens == "required" && alicloud_instance.k3s.http_endpoint == "enabled"
    error_message = "Instance metadata only in security-enhanced mode (IMDSv2)."
  }
  assert {
    condition     = alicloud_instance.k3s.internet_max_bandwidth_out == 0
    error_message = "No ephemeral public IP: the EIP is the only public address."
  }
  assert {
    condition     = alicloud_instance.k3s.security_groups == toset([alicloud_security_group.this.id]) && alicloud_instance.k3s.vswitch_id == alicloud_vswitch.this.id
    error_message = "The instance sits in the module's vSwitch behind the module's security group only."
  }
}

run "eip_is_the_stable_public_address" {
  command = plan

  assert {
    condition     = alicloud_eip_association.k3s.allocation_id == alicloud_eip_address.public.id && alicloud_eip_association.k3s.instance_id == alicloud_instance.k3s.id
    error_message = "The EIP is bound to the instance."
  }
  assert {
    condition     = alicloud_eip_address.public.payment_type == "PayAsYouGo" && alicloud_eip_address.public.internet_charge_type == "PayByTraffic"
    error_message = "EIP: pay-as-you-go, billed by traffic."
  }
  assert {
    condition     = alicloud_eip_address.public.bandwidth == tostring(var.eip_bandwidth_mbps)
    error_message = "EIP bandwidth cap from var.eip_bandwidth_mbps."
  }
}

run "cloud_init_installs_the_pinned_k3s_without_traefik" {
  command = plan

  assert {
    condition     = startswith(base64decode(alicloud_instance.k3s.user_data), "#cloud-config\n")
    error_message = "user_data is a base64-encoded cloud-config document."
  }
  assert {
    condition     = output.k3s_version == "v1.36.6+k3s1" && strcontains(base64decode(alicloud_instance.k3s.user_data), "K3S_VERSION='v1.36.6+k3s1'")
    error_message = "k3s is pinned (v1.36.6+k3s1, the Kubernetes minor kind runs)."
  }
  assert {
    condition = alltrue([for h in ["46177d4c99440b4c0311b67233823a8e8a2fc09693f6c89af1a7161e152fbfad", "66ceb8e67edfa547195135d74783bfadc2ecc04a91059e90ae5f70a3dbc98c15"] :
    strcontains(base64decode(alicloud_instance.k3s.user_data), h)])
    error_message = "The install script and the k3s binary are verified against pinned SHA-256 sums."
  }
  assert {
    condition     = strcontains(base64decode(alicloud_instance.k3s.user_data), "disable:\n        - traefik\n")
    error_message = "k3s's bundled Traefik is off (Envoy Gateway is the edge)."
  }
  assert {
    condition     = !strcontains(base64decode(alicloud_instance.k3s.user_data), "servicelb")
    error_message = "ServiceLB stays on (it gives Envoy's LoadBalancer Service the node's ports 80 and 443)."
  }
  assert {
    condition = alltrue([for s in ["- 203.0.113.10\n", "- 203-0-113-10.sslip.io\n", "node-external-ip: 203.0.113.10\n", "secrets-encryption: true\n", "write-kubeconfig-mode: \"0600\"\n"] :
    strcontains(base64decode(alicloud_instance.k3s.user_data), s)])
    error_message = "k3s config: API certificate for the EIP and the hostname, external IP, encrypted Secrets, private kubeconfig."
  }
  assert {
    condition     = strcontains(base64decode(alicloud_instance.k3s.user_data), "PasswordAuthentication no\n") && strcontains(base64decode(alicloud_instance.k3s.user_data), "ssh_pwauth: false\n")
    error_message = "SSH: keys only."
  }
}


# --------------------------------------------------------------------------------------------------------------------
# Outputs (WP104, ADR-0050, decision 78): the deployment is reached by a free wildcard DNS name derived from the EIP;
# OpenTofu manages no DNS record.
run "hostname_is_derived_from_the_address" {
  command = plan

  assert {
    condition     = output.public_ip == "203.0.113.10"
    error_message = "public_ip is the EIP."
  }
  assert {
    condition     = output.hostname == "203-0-113-10.sslip.io"
    error_message = "hostname = the dashed EIP under sslip.io, got ${output.hostname}."
  }
  assert {
    condition     = output.wildcard_hostname == "*.203-0-113-10.sslip.io"
    error_message = "wildcard_hostname covers every name under the hostname."
  }
  assert {
    condition     = output.public_url == "https://203-0-113-10.sslip.io"
    error_message = "public_url is the HTTPS URL of the hostname (global.publicUrl of the chart)."
  }
}

run "nip_io_works_the_same_way" {
  command = plan
  variables {
    dns_suffix = "nip.io"
  }

  assert {
    condition     = output.hostname == "203-0-113-10.nip.io" && output.public_url == "https://203-0-113-10.nip.io"
    error_message = "nip.io gives the same dashed name."
  }
}

run "tells_how_to_reach_the_machine_and_the_cluster" {
  command = plan

  assert {
    condition     = output.ssh_command == "ssh root@203.0.113.10"
    error_message = "ssh_command logs in with the key pair."
  }
  assert {
    condition     = strcontains(output.kubeconfig_command, "deploy/cloud/kubeconfig.sh")
    error_message = "kubeconfig_command points at the script that fetches and rewrites the kubeconfig."
  }
  assert {
    condition     = output.instance_type == "ecs.g7.large" && output.zone_id == "ap-southeast-5a" && output.region == "ap-southeast-5"
    error_message = "Instance type, zone and region are reported."
  }
}
