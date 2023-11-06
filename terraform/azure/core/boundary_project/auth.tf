resource "boundary_scope" "project" {
  name                     = var.scope_name
  description              = "Environment scope"
  scope_id                 = var.org_id
  auto_create_admin_role   = true
  auto_create_default_role = true
}