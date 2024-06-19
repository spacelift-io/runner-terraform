target "aws" {
    target = "aws"
    platforms = ["linux/amd64", "linux/arm64"]
    args = {"BASE_IMAGE": "alpine:3.20"}
}

target "gcp" {
    target = "gcp"
    platforms = ["linux/amd64", "linux/arm64"]
    args = {"BASE_IMAGE": "gcr.io/google.com/cloudsdktool/google-cloud-cli:alpine"}
}

target "azure" {
    target = "azure"
    platforms = ["linux/amd64", "linux/arm64"]
    args = {"BASE_IMAGE": "mcr.microsoft.com/azure-cli:latest"}
}

