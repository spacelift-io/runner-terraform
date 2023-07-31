target "aws" {
    target = "aws"
    platforms = ["linux/amd64", "linux/arm64"]
    args = {"BASE_IMAGE": "alpine:3.18"}
}
