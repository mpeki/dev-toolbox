IMAGE ?= dev-toolbox
VERSION ?= $(shell git describe --always --dirty --tags 2>/dev/null || echo "undefined")
# Allow to override image registry.
REGISTRY ?= macp
.NOTPARALLEL:

DOCKER_BUILD := docker build --build-arg VERSION=${VERSION}
ifdef JENKINS_HOME
	DOCKER_BUILD += --build-arg USERNAME=$(shell whoami)
	DOCKER_BUILD += --build-arg USER_UID=$(shell id -u)
	DOCKER_BUILD += --build-arg USER_GID=$(shell id -g)
endif

.PHONY: docker
docker:
	$(DOCKER_BUILD) -f Dockerfile -t $(REGISTRY)/$(IMAGE):latest -t $(IMAGE):latest -t $(REGISTRY)/$(IMAGE):${VERSION} -t $(IMAGE):${VERSION} .

.PHONY: docker-push
docker-push:
	docker push $(REGISTRY)/$(IMAGE):${VERSION}

.PHONY: test
test:
	@type java >/dev/null 2>&1 || { echo >&2 "I require java but it's not installed. Aborting."; exit 1; }
	@type docker >/dev/null 2>&1 || { echo >&2 "I require docker but it's not installed. Aborting."; exit 1; }
	@type node >/dev/null 2>&1 || { echo >&2 "I require node but it's not installed. Aborting."; exit 1; }
	@type npm >/dev/null 2>&1 || { echo >&2 "I require npm but it's not installed. Aborting."; exit 1; }
	@type semantic-release >/dev/null 2>&1 || { echo >&2 "I require semantic-release but it's not installed. Aborting."; exit 1; }
	@type curl >/dev/null 2>&1 || { echo >&2 "I require curl but it's not installed. Aborting."; exit 1; }
	@type ssh >/dev/null 2>&1 || { echo >&2 "I require ssh but it's not installed. Aborting."; exit 1; }
	@type aws >/dev/null 2>&1 || { echo >&2 "I require awscli but it's not installed. Aborting."; exit 1; }
	@type mvn >/dev/null 2>&1 || { echo >&2 "I require mvn but it's not installed. Aborting."; exit 1; }
	@type jq >/dev/null 2>&1 || { echo >&2 "I require jq but it's not installed. Aborting."; exit 1; }
