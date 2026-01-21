target "aws" {
    target = "aws"
    platforms = ["linux/amd64", "linux/arm64"]
    args = {"BASE_IMAGE": "alpine:3.23"}
}

target "gcp" {
    target = "gcp"
    platforms = ["linux/amd64", "linux/arm64"]
    args = {"BASE_IMAGE": "gcr.io/google.com/cloudsdktool/google-cloud-cli:alpine"}
}

target "azure" {
    target = "azure"
    platforms = ["linux/amd64", "linux/arm64"]
    args = {"BASE_IMAGE": "alpine:3.23"}
}

target "aws-fips" {
    target = "aws"
    platforms = ["linux/amd64", "linux/arm64"]
    args = {
        "BASE_IMAGE": "ghcr.io/spacelift-io/alpine-fips:base-latest"
    }
}

target "gcp-fips" {
    target = "gcp"
    platforms = ["linux/amd64", "linux/arm64"]
    args = {
        "BASE_IMAGE": "ghcr.io/spacelift-io/alpine-fips:gcp-latest"
    }
}

target "azure-fips" {
    target = "azure"
    platforms = ["linux/amd64", "linux/arm64"]
    args = {
        "BASE_IMAGE": "ghcr.io/spacelift-io/alpine-fips:base-latest"
    }
}