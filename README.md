# Athena OS Docker Image

<!-- [![pipeline status](https://gitlab.archlinux.org/archlinux/archlinux-docker/badges/master/pipeline.svg)](https://gitlab.archlinux.org/archlinux/archlinux-docker/-/commits/master) -->

Athena OS provides Docker images in the [official DockerHub library](https://hub.docker.com/u/athenaos) (`docker pull athenaos/base:latest`).

Images in the official library are updated weekly while our own repository is updated daily.

Two versions of the image are provided: `base` (approx. 135MB) and `base-devel` (approx. 240MB), containing the respective meta package / package group. Both are available as tags with `latest` pointing to `base`.<!-- Additionally, images are tagged with their date and build job number, f.e. `base-devel-20201118.0.9436`. -->

While the images are regularly kept up to date it is strongly recommended running `pacman -Syu` right after starting a container due to the rolling release nature of Athena OS.

## Principles
* Provide the Athena OS experience in a Docker image
* Provide the simplest but complete image to `base` and `base-devel` on a regular basis
* `pacman` needs to work out of the box
* All installed packages have to be kept unmodified

## Building your own image

[This repository](https://github.com/Athena-OS/athena-base-docker) contains all scripts and files needed to create a Docker image for Athena OS.

### Dependencies
Install the following packages:
* make
* devtools
* docker
* docker-buildx
* fakechroot
* fakeroot

```
sudo pacman -S make devtools docker docker-buildx fakechroot fakeroot
```

Make sure your user can directly interact with Docker (i.e. `docker info` works).

### Usage
Run
```
sudo make clean
sudo make athena-base
```
to build the `base` image with the `base` meta package installed. Push the image to Docker Hub by:
```
sudo docker push athenaos/base:latest
```

You can also run
```
sudo make clean
sudo make athena-base-devel
```
to build the image `base-devel` which additionally has the `base-devel` group installed. Push the image to Docker Hub by:
```
sudo docker push athenaos/base-devel:latest
```
If requested, the login must be performed by:
```
sudo docker login
```
To create and run a container from the created image:
```
sudo docker run --rm -it --entrypoint bash athenaos/base
```

### Weekly builds

Weekly images are build with scheduled [GitHub Actions](https://github.com/Athena-OS/athena-base-docker/blob/main/.github/workflows/docker-publish.yml) using our own runner infrastructure. Initially root filesystem archives are constructed and provided in this repository. The released multi-stage Dockerfile downloads those archives and verifies their integrity before unpacking it into a Docker image layer. Images could be built using [kaniko](https://github.com/GoogleContainerTools/kaniko) to avoid using privileged Docker containers, which also publishes them to our Docker Hub repository.

### Development

Changes in Git feature branches are built and tested using the pipeline as well. Development images are uploaded to our [Docker Hub Registry](https://hub.docker.com/u/athenaos).
