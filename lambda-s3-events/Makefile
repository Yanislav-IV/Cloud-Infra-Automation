# Variables
IMAGE_NAME := $(IMAGE_NAME)
TAG := $(TAG)


.PHONY: all clean docker-build

all: clean docker-build

docker-build:
	@echo "Building $(IMAGE_NAME):$(TAG) Docker image..."
	DOCKER_BUILDKIT=0 docker build --no-cache --pull -t $(IMAGE_NAME):$(TAG) .

clean:
	@echo "Cleaning build artifacts..."
	rm -rf build
