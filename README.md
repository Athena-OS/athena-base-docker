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
* fakechroot
* fakeroot

```
sudo pacman -S make devtools docker fakechroot fakeroot
```

Make sure your user can directly interact with Docker (i.e. `docker info` works).

### Usage
Run `make image-base` to build the `base` image with the
`base` meta package installed. You can also run `make image-base-devel` to
build the image `base-devel` which additionally has the `base-devel` group installed.

Then, push the image by:
```
docker push athenaos/base:latest
docker push athenaos/base-devel:latest
```

<!-- ## Pipeline

### Daily builds

Daily images are build with scheduled [GitLab CI](https://gitlab.archlinux.org/archlinux/archlinux-docker/-/blob/master/.gitlab-ci.yml) using our own runner infrastructure. Initially root filesystem archives are constructed and provided in our [package registry](https://gitlab.archlinux.org/archlinux/archlinux-docker/-/packages). The released multi-stage Dockerfile downloads those archives and verifies their integrity before unpacking it into a Docker image layer. Images are built using [kaniko](https://github.com/GoogleContainerTools/kaniko) to avoid using privileged Docker containers, which also publishes them to our DockerHub repository.

### Weekly releases

Weekly releases to the official DockerHub library use the same pipeline as daily builds. Updates are provided as automatic [pull requests](https://github.com/docker-library/official-images/pulls?q=is%3Apr+archlinux+is%3Aclosed+author%3Aarchlinux-github) to the [official-images library](https://github.com/docker-library/official-images/blob/master/library/archlinux), whose GitHub pipeline will build the images using our provided rootfs archives and Dockerfiles.

### Development

Changes in Git feature branches are built and tested using the pipeline as well. Development images are uploaded to our [GitLab Container Registry](https://gitlab.archlinux.org/archlinux/archlinux-docker/container_registry). -->
