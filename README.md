# Terraform Runner Image

This repo contains the Dockerfile for building the default Spacelift Terraform runner image.

## Docker Repository

The image is pushed to the `public.ecr.aws/spacelift/runner-terraform` public repository. It
is also pushed to the `ghcr.io/spacelift-io/runner-terraform` as a backup in case of issues
with ECR.

## Branch Model

This repository uses two main branches:

- `main` - contains the production version of the runner image.
- `future` - used to test development changes.

Pushes to `main` deploy to the `latest` tag, whereas pushes to `future` deploy to the `future`
tag. This means that to use the development version you can use the `public.ecr.aws/spacelift/runner-terraform:future`
image.
