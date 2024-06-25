BUILD_DIR := build
LITECOIN_VERSION := $(LITECOIN_VERSION)
IMAGE_NAME := $(IMAGE_NAME)
TAG := $(TAG)
DOCKER_FILE := $(DOCKER_FILE)


.PHONY: all clean docker-build

all: clean docker-build

docker-build:
	@echo "Building $(IMAGE_NAME):$(TAG) Docker image..."
	DOCKER_BUILDKIT=0 docker build --no-cache --pull --build-arg LITECOIN_VERSION=$(LITECOIN_VERSION) -t $(IMAGE_NAME):$(TAG) -f $(DOCKER_FILE) .

clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)

