# Hoops Academy on one k3s VM in Alibaba Cloud, Indonesia (Jakarta) (WP104, ADR-0050, decisions 76-78).
# The outer layer only: network, security group, key pair, VM, public address; k3s comes from cloud-init. The Helm release
# is not managed here (deploy/cloud/install.sh), so no application secret ever enters the state.
# Runbook: docs/runbooks/cloud.md. Checks without a credential: `just tofu-check`.

terraform {
  # Same pin as .opentofu-version (CI installs exactly that version; check.sh compares).
  required_version = "~> 1.13.9"

  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "= 2.2.0"
    }
  }

  # Local state (no backend block), encrypted with a passphrase from the environment (TF_VAR_state_passphrase).
  # enforced: OpenTofu refuses to write an unencrypted state or plan. Never rename the key provider or the method once a
  # state exists (OpenTofu could no longer read it). State, plans and *.tfvars are git-ignored (rule 6).
  encryption {
    key_provider "pbkdf2" "state" {
      passphrase = var.state_passphrase
    }
    method "aes_gcm" "state" {
      keys = key_provider.pbkdf2.state
    }
    state {
      method   = method.aes_gcm.state
      enforced = true
    }
    plan {
      method   = method.aes_gcm.state
      enforced = true
    }
  }
}

# Credentials only from the environment (ALIBABA_CLOUD_ACCESS_KEY_ID / ALIBABA_CLOUD_ACCESS_KEY_SECRET, or a profile in
# ~/.aliyun/config.json via ALIBABA_CLOUD_PROFILE); never in a file of this directory.
provider "alicloud" {
  region = var.region
}
