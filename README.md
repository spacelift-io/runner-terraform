# Spacelift CDKTF AWS Runner Image

This repo contains the Dockerfile for building our Spacelift CDKTF AWS runner image, which contains all the necessary tools for our Spacelift pipeline.

## Docker Repository

The image is pushed to the `ghcr.io/stabl-energy/spacelift-runner-cdktf` public repository.

## Branch Model

All changes merged to `main` branch are automatically built and pushed to the Docker repository with the `future` tag.

Once it is considered stable, we can release it as `latest` by creating a tag (semver) and pushing it to the
repository. Example:

```bash
$ git tag -a v1.1.0 -m "Release v1.1.0"
$ git push origin v1.1.0
```

We also have a weekly cron job that re-runs the `main` branch just to have the latest package updates.
