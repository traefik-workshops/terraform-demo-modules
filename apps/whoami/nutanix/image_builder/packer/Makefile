.PHONY: build-binaries packer-build-arm64 packer-build-amd64 all clean

BIN_DIR := bin

# Architecture definitions for Go and Packer
# We map simple arch names to Go/Packer conventions
#   amd64 -> GOARCH=amd64, PACKER_VAR_arch=amd64
#   arm64 -> GOARCH=arm64, PACKER_VAR_arch=arm64

build-binaries:
	mkdir -p $(BIN_DIR)/amd64 $(BIN_DIR)/arm64
	# Extract Linux AMD64 binary from Docker image
	docker pull --platform linux/amd64 traefik/whoami:v1.10.1
	docker rm -f temp-whoami-amd64 || true
	docker create --name temp-whoami-amd64 --platform linux/amd64 traefik/whoami:v1.10.1
	docker cp temp-whoami-amd64:/whoami $(BIN_DIR)/amd64/whoami
	docker rm temp-whoami-amd64
	
	# Extract Linux ARM64 binary from Docker image
	docker pull --platform linux/arm64 traefik/whoami:v1.10.1
	docker rm -f temp-whoami-arm64 || true
	docker create --name temp-whoami-arm64 --platform linux/arm64 traefik/whoami:v1.10.1
	docker cp temp-whoami-arm64:/whoami $(BIN_DIR)/arm64/whoami
	docker rm temp-whoami-arm64

packer-build-arm64: build-binaries
	packer init .
	packer build -var 'arch=arm64' .

packer-build-amd64: build-binaries
	packer init .
	packer build -var 'arch=amd64' .

all: packer-build-arm64 packer-build-amd64

clean:
	rm -rf $(BIN_DIR) images
