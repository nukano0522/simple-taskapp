NAMESPACE := simple-taskapp
DOCKER_REGISTRY := nukano0522
IMAGE_TAG := v0.1.4-test
APP_NAME := simple-taskapp-flask-web
DOCKERFILE_PATH := .
K8S_DEPLOYMENT_NAME := web-deployment

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