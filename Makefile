# Show status on 0.96" OLED display with I2C on Raspberry Pi & NVIDIA Jetsons

DOCKERHUB_ID:=ibmosquito
SERVICE_NAME:="oled-status"
SERVICE_VERSION:="1.0.0"
PATTERN_NAME:="pattern-oled-status"

# Leave blank for public DockerHub containers
# CONTAINER_CREDS:=-r "registry.wherever.com:myid:mypw"
CONTAINER_CREDS:=

# This statement will automatically configure the ARCH environment variable
ARCH:=$(shell ./helper -a)
GATEWAY:=$(shell ./helper -g)
IPV4_ADDR:=$(shell ./helper -i)

default: build run

build:
	docker build -t $(DOCKERHUB_ID)/$(SERVICE_NAME)_$(ARCH):$(SERVICE_VERSION) -f ./Dockerfile.$(ARCH) .

dev: stop
	docker run -it -v `pwd`:/outside \
	  --privileged \
	  -e ARCH=$(ARCH) \
	  -e GATEWAY=$(GATEWAY) \
	  -e IPV4_ADDR=$(IPV4_ADDR) \
	  --name ${SERVICE_NAME} \
	  $(DOCKERHUB_ID)/$(SERVICE_NAME)_$(ARCH):$(SERVICE_VERSION) /bin/sh

run: stop
	docker run -d \
	  --privileged \
	  --restart unless-stopped \
	  -e ARCH=$(ARCH) \
	  -e GATEWAY=$(GATEWAY) \
	  -e IPV4_ADDR=$(IPV4_ADDR) \
	  --name ${SERVICE_NAME} \
	  $(DOCKERHUB_ID)/$(SERVICE_NAME)_$(ARCH):$(SERVICE_VERSION)

test:
	@echo "Look at the pretty color!"

push:
	docker push $(DOCKERHUB_ID)/$(SERVICE_NAME)_$(ARCH):$(SERVICE_VERSION) 

publish-service:
	@ARCH=$(ARCH) \
	GATEWAY=$(GATEWAY) \
	IPV4_ADDR=$(IPV4_ADDR) \
        SERVICE_NAME="$(SERVICE_NAME)" \
        SERVICE_VERSION="$(SERVICE_VERSION)"\
        SERVICE_CONTAINER="$(DOCKERHUB_ID)/$(SERVICE_NAME)_$(ARCH):$(SERVICE_VERSION)" \
        hzn exchange service publish -O $(CONTAINER_CREDS) -f service.json --pull-image

publish-pattern:
	@ARCH=$(ARCH) \
        SERVICE_NAME="$(SERVICE_NAME)" \
        SERVICE_VERSION="$(SERVICE_VERSION)"\
        PATTERN_NAME="$(PATTERN_NAME)" \
	hzn exchange pattern publish -f pattern.json

stop:
	@docker rm -f ${SERVICE_NAME} >/dev/null 2>&1 || :

clean:
	@docker rmi -f $(DOCKERHUB_ID)/$(SERVICE_NAME)_$(ARCH):$(SERVICE_VERSION) >/dev/null 2>&1 || :

agent-run:
	hzn register --pattern "${HZN_ORG_ID}/$(PATTERN_NAME)"
	hzn policy update -f privileged.json

agent-stop:
	hzn unregister -f

.PHONY: default build dev run push stop clean publish-service publish-pattern agent-run agent-stop

