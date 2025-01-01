NAMESPACE := simple-taskapp
DOCKER_REGISTRY := nukano0522
IMAGE_TAG := latest
APP_NAME := simple-taskapp-fastapi
DOCKERFILE_PATH := .
K8S_DEPLOYMENT_NAME := api-deployment
.PHONY: build
build:
	docker build -t $(DOCKER_REGISTRY)/$(APP_NAME):$(IMAGE_TAG) $(DOCKERFILE_PATH)

.PHONY: push
push:
	docker push $(DOCKER_REGISTRY)/$(APP_NAME):$(IMAGE_TAG)

.PHONY: restart
restart:
	kubectl rollout restart deployment/$(K8S_DEPLOYMENT_NAME) -n $(NAMESPACE)

.PHONY: all
all: build push restart