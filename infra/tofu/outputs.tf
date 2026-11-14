# What deploy/cloud/*.sh and the runbook read (`tofu -chdir=infra/tofu output -json`). No secret among them.

output "public_ip" {
  description = "The EIP: the deployment's only public address."
  value       = local.public_ip
}

output "hostname" {
  description = "Wildcard DNS name of the EIP (<a-b-c-d>.sslip.io): the Gateway hostname and the base of global.publicUrl."
  value       = local.hostname
}

output "wildcard_hostname" {
  description = "Every name under hostname resolves to the EIP as well (room for more hosts later)."
  value       = "*.${local.hostname}"
}

output "public_url" {
  description = "global.publicUrl and keycloak.publicUrl of the chart (HTTPS; self-signed until the TLS slice)."
  value       = "https://${local.hostname}"
}

output "ssh_command" {
  description = "Log in with the key pair (only from admin_cidrs)."
  value       = "ssh root@${local.public_ip}"
}

output "kubeconfig_command" {
  description = "Fetch the k3s kubeconfig over SSH, pointed at the public API (only from admin_cidrs)."
  value       = "deploy/cloud/kubeconfig.sh   # writes ~/.kube/hoops-cloud.yaml (context hoops-cloud) for root@${local.public_ip}"
}

output "k3s_version" {
  description = "k3s version cloud-init installs."
  value       = local.k3s.version
}

output "instance_type" {
  description = "ECS instance type."
  value       = alicloud_instance.k3s.instance_type
}

output "zone_id" {
  description = "Zone of the vSwitch and the instance."
  value       = local.zone_id
}

output "region" {
  description = "Region id."
  value       = var.region
}
