# dockoon

The Docker images include:

- Node.js 14, on Alpine Linux (`mockoon:alpine`) or Debian Buster (`mockoon:slimbuster`)
- Latest [@mockoon/cli](https://www.npmjs.com/package/@mockoon/cli)
- Proxy to [jsonplaceholder](https://jsonplaceholder.typicode.com/), defaulted at [:8080](https://localhost:8080)

## Setup

Install [mockoon](https://mockoon.com/) to edit 'apis.json' via GUI. On OS X:

    brew bundle

## Run mockoon-cli in Docker

Build a new (Alpine based) image from `Dockerfile` and run it locally:

    ./dockoon

Pass `mockoon` CLI arguments, e.g. to override the default port:

    ./dockoon start --data apis.json --name jsonplaceholder --port 3000

Pass variable `BUILD_ARGS` to include additional `docker build` arguments:

    BUILD_ARGS="--build-arg FROM_IMAGE=asyrjasalo/mockoon:slimbuster" \
      ./dockoon

Pass variable `RUN_ARGS` to include additional `docker run` arguments:

    RUN_ARGS="-v $PWD/imposter.json:/home/app/imposter.json -p 4000:4000" \
      ./dockoon start --data imposter.json --name myfakeapi --port 4000

## Build a base image

Alpine Linux:

    docker/build_and_test_image

Pass variable `BUILD_ARGS` to override the default `docker build` arguments.

Pass `IMAGE_KIND` to build on non-Alpine Dockerfile. For Debian Buster (slim):

    IMAGE_KIND=slimbuster \
      docker/build_and_test_image

Pass `BUILD_DIR` to override the dir path where `Dockerfile.IMAGE_KIND` is in.

## Push the base image

Run `docker login` before the scripts.

Push the image to your private Docker registry:

    REGISTRY_URL=https://your.azurecr.io \
      docker/tag_and_push_image

Tag and push the image `mockoon:alpine` to [Docker Hub](https://hub.docker.com):

    REGISTRY_URL="$USER" \
      docker/tag_and_push_image

Tag and push the image `mockoon:slimbuster` (note: first, build a Debian image):

    REGISTRY_URL="$USER" \
    IMAGE_KIND=slimbuster \
      docker/tag_and_push_image
