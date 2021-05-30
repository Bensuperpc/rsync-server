#//////////////////////////////////////////////////////////////
#//   ____                                                   //
#//  | __ )  ___ _ __  ___ _   _ _ __   ___ _ __ _ __   ___  //
#//  |  _ \ / _ \ '_ \/ __| | | | '_ \ / _ \ '__| '_ \ / __| //
#//  | |_) |  __/ | | \__ \ |_| | |_) |  __/ |  | |_) | (__  //
#//  |____/ \___|_| |_|___/\__,_| .__/ \___|_|  | .__/ \___| //
#//                             |_|             |_|          //
#//////////////////////////////////////////////////////////////
#//                                                          //
#//  Script, 2021                                            //
#//  Created: 30, May, 2021                                  //
#//  Modified: 30, May, 2021                                 //
#//  file: -                                                 //
#//  -                                                       //
#//  Source: https://github.com/axiom-data-science/rsync-server                                               //
#//          https://www.docker.com/blog/getting-started-with-docker-for-arm-on-linux/
#//          https://schinckel.net/2021/02/12/docker-%2B-makefile/
#//          https://www.padok.fr/en/blog/multi-architectures-docker-iot
#//  OS: ALL                                                 //
#//  CPU: ALL                                                //
#//                                                          //
#//////////////////////////////////////////////////////////////
BASE_IMAGE := debian:buster-slim
IMAGE_NAME := bensuperpc/rsync-server
DOCKERFILE := Dockerfile

DOCKER := docker

TAG := $(shell date '+%Y%m%d')-$(shell git rev-parse --short HEAD)
DATE_FULL := $(shell date +%Y-%m-%d_%H:%M:%S)
UUID := $(shell cat /proc/sys/kernel/random/uuid)

#Not in debian buster : riscv64

ARCH_LIST := linux/amd64 linux/arm64 linux/ppc64le linux/s390x linux/386 linux/arm/v7 linux/arm/v6
comma:= ,
COM_ARCH_LIST:= $(subst $() $(),$(comma),$(ARCH_LIST))

$(ARCH_LIST): $(DOCKERFILE)
	$(DOCKER) buildx build . -f $(DOCKERFILE) -t $(IMAGE_NAME):$(TAG) -t $(IMAGE_NAME):latest \
	--build-arg BUILD_DATE=$(DATE_FULL) --build-arg DOCKER_IMAGE=$(BASE_IMAGE) --platform $@ --push

	
all: $(DOCKERFILE)
	$(DOCKER) buildx build . -f $(DOCKERFILE) -t $(IMAGE_NAME):$(TAG) -t $(IMAGE_NAME):latest \
	--build-arg BUILD_DATE=$(DATE_FULL) --build-arg DOCKER_IMAGE=$(BASE_IMAGE) --platform $(COM_ARCH_LIST) --push

push: all

# https://github.com/linuxkit/linuxkit/tree/master/pkg/binfmt
qemu:
	export DOCKER_CLI_EXPERIMENTAL=enabled
	docker run -d --name buildkitd --privileged moby/buildkit:latest
	export BUILDKIT_HOST=docker-container://buildkitd
	$(DOCKER) buildx create --driver-opt image=moby/buildkit:master --use

clean:
	$(DOCKER) images --filter='reference=$(IMAGE_NAME)' --format='{{.Repository}}:{{.Tag}}' | xargs -r $(DOCKER) rmi -f

.PHONY: build push clean qemu_x86 $(ARCH_LIST) armv5 armv6 armv7 armv8