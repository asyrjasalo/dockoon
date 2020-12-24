# dockoon

Includes:

- Alpine Linux / Debian (slim)
- Node.js 14
- [mockoon-cli](https://github.com/mockoon/cli)
- [proxy to jsonplaceholder](https://jsonplaceholder.typicode.com/) at [:8080](https://localhost:8080)

## Setup

Install [mockoon](https://mockoon.com/) to edit 'apis.json' via GUI. On OS X:

    brew bundle

## Run mockoon-cli on Docker

Build a new image based on `Dockerfile` and run it:

    ./dockoon

Append any `mockoon` CLI arguments:

    ./dockoon list

Pass variable `BUILD_ARGS` to include additional `docker build` arguments:

    BUILD_ARGS="--build-arg FROM_IMAGE=asyrjasalo/mockoon:slimbuster" \
      ./dockoon

Pass variable `RUN_ARGS` to include additional `docker run` arguments.

## Build a base image

Alpine Linux:

    docker/build_and_test_image

Debian Buster (slim):

    IMAGE_KIND="slimbuster" docker/build_and_test_image

Pass variable `BUILD_DIR` to override the directory path where `Dockerfile` is.

## Push the base image

Remember to `docker login` first.

Push the image to the private Docker registry:

    REGISTRY_URL=https://your.azurecr.io \
      docker/tag_and_push_image

Tag and push the image as 'alpine' to [Docker Hub](https://hub.docker.com):

    REGISTRY_URL="$USER" \
      docker/tag_and_push_image

Tag and push the image as 'slimbuster' (note: build on Debian image first):

    REGISTRY_URL="$USER" \
    IMAGE_KIND=slimbuster \
      docker/tag_and_push_image
