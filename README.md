# Spacelift CDKTF AWS Runner Image

This repo contains the Dockerfile for building our Spacelift CDKTF AWS runner image, which contains all the necessary tools for our Spacelift pipeline.

The runner image builds the following tools for the different spacelift runners to use:
* Terraform 
* Bun
* Node
* AWS CLI
* Infracost
* Regula

We build these tools ourselves to override the default behaviour of the spacelift runners and to accomodate the use of CDKTF instead of regular terraform. 

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

From there we use this latest image to build seperate image for the different components of our infrastrucutre, which are:
* [SBC infrastructure](https://github.com/Stabl-Energy/SBC-Infrastructure/blob/test/Dockerfile)
* [Grafana infrastructure](https://github.com/Stabl-Energy/Grafana-Infrastructure/blob/test/Dockerfile)
* [External infrastructure](https://github.com/Stabl-Energy/External-Infrastructure/blob/main/Dockerfile)
* [Management infrastructure](https://github.com/Stabl-Energy/Management-Infrastructure/blob/main/Dockerfile)
* [Spacelift infrastructure](https://github.com/Stabl-Energy/Spacelift-Infrastructure/blob/main/Dockerfile)

