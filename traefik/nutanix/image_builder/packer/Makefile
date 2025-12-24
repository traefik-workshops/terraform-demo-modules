.PHONY: clean build-binaries packer-build-arm64 packer-build-amd64 all

# Relative path to traefik-hub repo
HUB_DIR := ../../../../traefik-hub
BIN_DIR := bin

clean:
	rm -rf $(BIN_DIR) images

build-binaries:
	@echo "Building binaries in $(HUB_DIR)..."
	$(MAKE) -C $(HUB_DIR) build-linux-amd64 build-linux-arm64
	@echo "Copying binaries to $(BIN_DIR)..."
	mkdir -p $(BIN_DIR)/amd64 $(BIN_DIR)/arm64
	cp $(HUB_DIR)/dist/linux/amd64/traefik-hub $(BIN_DIR)/amd64/
	cp $(HUB_DIR)/dist/linux/arm64/traefik-hub $(BIN_DIR)/arm64/

packer-build-arm64: build-binaries
	packer build -var 'arch=arm64' .

packer-build-amd64: build-binaries
	packer build -var 'arch=amd64' .

all: packer-build-arm64 packer-build-amd64
