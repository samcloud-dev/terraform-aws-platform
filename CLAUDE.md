# CLAUDE.md: terraform-aws-platform

## What this repo is
Terraform for the AWS foundation (ca-central-1) that hosts FreshTrack
(separate repo: ~/Projects/freshtrack) on single-node k3s for a one-week
household trial. The stack is removed with `terraform destroy` afterwards.
Owner: Samson (DevOps intern, learning). Claude acts as a senior DevOps mentor.

## Working rules
- Explain why before how, in plain words with an analogy; link official docs.
- Ask before every file change; show the proposed diff first.
- Never run git write commands, `terraform apply` or `terraform destroy`.
  Propose them; Samson runs them.
- Never print secrets, tfvars values or state contents. Never commit state,
  private keys or tfvars.

## Platform contract
| Layer | Owner | Provides |
|---|---|---|
| AWS foundation | Terraform (this repo) | VPC module, public subnet, one EC2 host, Elastic IP, security group, IAM instance role, encrypted gp3 disk, outputs for Ansible |
| Host config | Ansible, connecting through SSM (aws_ssm plugin) | OS setup, k3s install, kubeconfig |
| Cluster + app | FreshTrack repo (Argo CD + Helm) | Traefik ingress, TLS, basic auth, OpenBao + ESO + Reloader, Postgres StatefulSet, expiry CronJob |

- Inbound: only 80 and 443, from `allowed_ingress_cidr` (set in the
  git-ignored terraform.tfvars). Limited to Samson's IP until the go-live
  checklist (HTTPS + basic auth working) passes.
- Never open 22 (SSH) or 6443 (k3s API) to the internet. Admin access is via SSM.
- Instance type and disk size are variables: t3.small while learning,
  m7i-flex.large (8 GB) for k3s + FreshTrack. Root disk 30 GiB. IMDSv2 required.
- Elastic IP lives in this stack (released on destroy, so no idle cost);
  the domain name is the stable address.
- IAM role is least-privilege: SSM, plus read/write on the Ansible transfer
  bucket only (and SES only if that email option is chosen).
- Images come from Docker Hub; Terraform holds no registry credentials.
- State lives in S3 with native locking. The bucket is built by bootstrap/,
  which is never destroyed.
- Host data is temporary: pg_dump before `terraform destroy`.
- Monitoring of FreshTrack runs on Minikube, not on this platform.

## Warn before contract-breaking changes
Anything that replaces the instance (`forces replacement`), changes the
public IP, opens a port, widens IAM, or changes the region.

## Decided
- Ansible access: aws_ssm connection plugin (Oct 24). No SSH keys, port 22 stays closed.
- Instance: m7i-flex.large is free-plan eligible; t3.small is the default for learning sessions (Oct 30).
- Elastic IP: Option A, inside the platform stack (Oct 30).

## Open decisions
- Email: SES SMTP credentials vs Gmail App Password
- AMI (AL2023 vs Ubuntu LTS), domain name

## Workflow
Feature branch → fmt / validate / plan (predict the counts first) → PR
(SonarCloud) → merge → apply → verify → destroy.