# Terraform Runner Image

This repo contains the Dockerfile for building the default Spacelift Terraform runner image.

## Docker Repository

The image is pushed to the `public.ecr.aws/spacelift/runner-terraform` public repository. It
is also pushed to the `ghcr.io/spacelift-io/runner-terraform` as a backup in case of issues
with ECR.

## Branch Model

All changes merged to `main` branch are automatically built and pushed to the Docker repository with the `future` tag.

Once it is considered stable, we can release it as `latest` by creating a tag (semver) and pushing it to the
repository. Example:

```bash
$ git tag -a v1.1.0 -m "Release v1.1.0"
$ git push origin v1.1.0
```

Note: we also have a weekly cron job that re-runs the `main` branch just to have the latest package updates.