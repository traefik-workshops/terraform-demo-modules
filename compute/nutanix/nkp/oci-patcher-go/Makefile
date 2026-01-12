
IMAGE_NAME ?= zalbiraw/oci-patcher
TAG ?= v8

.PHONY: all
all: build

.PHONY: tidy
tidy:
	go mod tidy

.PHONY: build
build: tidy
	go build -o oci-patcher main.go

.PHONY: docker-build
docker-build:
	docker buildx build --platform linux/amd64,linux/arm64 -t $(IMAGE_NAME):$(TAG) .

.PHONY: docker-push
docker-push:
	docker buildx build --platform linux/amd64,linux/arm64 -t $(IMAGE_NAME):$(TAG) --push .

.PHONY: help
help:
	@echo "Available targets:"
	@echo "  build         - Build the Go binary locally"
	@echo "  docker-build  - Build the Docker image"
	@echo "  docker-push   - Push the Docker image to $(IMAGE_NAME):$(TAG)"
	@echo "  tidy          - Run go mod tidy"
