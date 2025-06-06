# Terraform Runner Image

This repo contains the Dockerfile for building the default Spacelift Terraform runner image.

## Docker Repository

The image is pushed to the `public.ecr.aws/spacelift/runner-terraform` public repository. It
is also pushed to the `ghcr.io/spacelift-io/runner-terraform` as a backup in case of issues
with ECR.

## Images

We publish three images. The default has `aws` CLI v2 included, the others
`gcloud` and `az` respectively.
This is because `gcloud` and `az` are very large packages and we want to keep the image size down.

- `spacelift-io/runner-terraform:latest` -> with `aws` CLI
- `spacelift-io/runner-terraform:gcp-latest` -> with `gcloud` CLI
- `spacelift-io/runner-terraform:azure-latest` -> with `az` CLI

### FIPS

All the tags have a `-fips` variant that has been installed with the latest FIPS compliant OpenSSL (3.1.2 at the time of writing).
You are still responsible to run these images on a FIPS hardened host ensuring youre only communicating with FIPS enabled endpoints.

- `spacelift-io/runner-terraform:latest-fips` -> with `aws` CLI & FIPS OpenSSL
- `spacelift-io/runner-terraform:gcp-latest-fips` -> with `gcloud` CLI & FIPS OpenSSL
- `spacelift-io/runner-terraform:azure-latest-fips` -> with `az` CLI & FIPS OpenSSL

## Branch Model

All changes merged to `main` branch are automatically built and pushed to the Docker repository with the `future` tag.

Once it is considered stable, we can release it as `latest` by creating a tag (semver) and pushing it to the
repository. Example:

```bash
$ git tag -a v1.1.0 -m "Release v1.1.0"
$ git push origin v1.1.0
```

We also have a weekly cron job that re-runs the `main` branch just to have the latest package updates.

