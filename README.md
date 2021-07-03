# dockoon

[The Docker images](https://hub.docker.com/r/asyrjasalo/mockoon) include:

- Alpine Linux (`mockoon:alpine`) or Debian Buster (`mockoon:slimbuster`) base
- Node.js 14 running as non-root user
- Latest [@mockoon/cli](https://www.npmjs.com/package/@mockoon/cli)

## Setup

Install development dependencies:

    brew bundle

If casks are not available for your OS, you can download Mockoon
[from the official page](https://mockoon.com/#download).

Then use Mockoon to edit `apis.json` via GUI.

## Running locally

Build and run proxy to [jsonplaceholder](https://jsonplaceholder.typicode.com/)
at [:8080](https://localhost:8080) from `Dockerfile`:

    ./dockoon

Any `mockoon` CLI arguments are accepted:

    ./dockoon start --data https://file-server/apis.json --index 0 --port 8080

Pass variable `BUILD_ARGS` to include additional `docker build` arguments:

    BUILD_ARGS="--build-arg FROM_IMAGE=asyrjasalo/mockoon:slimbuster" \
      ./dockoon

Pass variable `RUN_ARGS` to include additional `docker run` arguments:

    RUN_ARGS="-p 4000:4000" \
      ./dockoon start --data apis.json --name jsonplaceholder --port 4000

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

## Cloud deployment

See `terraform/README.md` for running on Azure Container Instances.

## Contributing

On Git commit, hooks in `.pre-commit-config.yaml` will be installed and ran.
