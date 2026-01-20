.PHONY: clean build-binaries packer-build-arm64 packer-build-amd64 all

BIN_DIR := bin

clean:
	rm -rf $(BIN_DIR) images

build-binaries:
	@if [ -n "$(HUB_DIR)" ] && [ -d "$(HUB_DIR)" ]; then \
		echo "Building binaries from source in $(HUB_DIR)..."; \
		$(MAKE) -C $(HUB_DIR) build-linux-amd64 build-linux-arm64; \
		mkdir -p $(BIN_DIR)/amd64 $(BIN_DIR)/arm64; \
		cp $(HUB_DIR)/dist/linux/amd64/traefik-hub $(BIN_DIR)/amd64/; \
		cp $(HUB_DIR)/dist/linux/arm64/traefik-hub $(BIN_DIR)/arm64/; \
	else \
		echo "Extracting binaries from Docker image traefik/hub-agent:$(HUB_VERSION)..."; \
		mkdir -p $(BIN_DIR)/amd64 $(BIN_DIR)/arm64; \
		docker pull --platform linux/amd64 traefik/hub-agent:$(HUB_VERSION); \
		docker rm -f temp-traefik-amd64 || true; \
		docker create --name temp-traefik-amd64 --platform linux/amd64 traefik/hub-agent:$(HUB_VERSION); \
		docker cp temp-traefik-amd64:/traefik-hub $(BIN_DIR)/amd64/traefik-hub; \
		docker rm temp-traefik-amd64; \
		docker pull --platform linux/arm64 traefik/hub-agent:$(HUB_VERSION); \
		docker rm -f temp-traefik-arm64 || true; \
		docker create --name temp-traefik-arm64 --platform linux/arm64 traefik/hub-agent:$(HUB_VERSION); \
		docker cp temp-traefik-arm64:/traefik-hub $(BIN_DIR)/arm64/traefik-hub; \
		docker rm temp-traefik-arm64; \
	fi

packer-build-arm64: build-binaries
	packer init .
	packer build -var 'arch=arm64' .

packer-build-amd64: build-binaries
	packer init .
	packer build -var 'arch=amd64' .

all: packer-build-arm64 packer-build-amd64
