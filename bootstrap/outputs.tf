output "state_bucket" {
  description = "Bucket do state remoto (use em envs/<env>/backend.hcl)."
  value       = aws_s3_bucket.state.bucket
}
