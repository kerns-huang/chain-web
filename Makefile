APP=chainweb
CGO_ENABLED ?= 0
GOOS ?= linux
DEBUG_GOGCFLAGS = -gcflags='all=-N -l'
GOGCFLAGS = -ldflags '-s -w'

.PHONY: build
build: clean
	go build -o ${APP} main.go
.PHONY: run
run:
	go run -race main.go

.PHONY: clean
## clean: cleans the binary
clean:
	@echo "Cleaning" \
		&& go clean

.PHONY: setup
## setup: setup go modules
setup:
	@go mod init \
		&& go mod tidy \
		&& go mod vendor

.PHONY: help
## help: prints this help message
help:
	@echo "Usage: \n"
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':'


.PHONY: docker-build
docker-build: build
	docker build -t ${APP} .
    docker tag stringifier stringifier:tag

.PHONY: docker-run
docker-run: docker-build
	docker run -itd -p 8000:8000 --name ${APP} ${APP}

clean-docker:
	# Remove sns-server containers
	docker ps -f name=${APP}-* -aq | xargs docker stop
	docker ps -f name=${APP}-* -aq | xargs docker rm
	# Remove old sns-server images
	docker images -a | grep "${APP}" | awk '{print $3}' | xargs docker rmi

	# remove unused volumes
	 docker volume ls -qf dangling=true | xargs -r docker volume rm

define compile_service
	CGO_ENABLED=$(CGO_ENABLED) GOOS=$(GOOS) GOARCH=$(GOARCH) GOARM=$(GOARM) go build -tags ${BUILD_TAGS} $(2) -o ${BUILD_DIR}/${BINARY_PREFIX}-$(1) cmd/$(1)/main.go
endef

define make_docker_cleanbuild
	docker build --no-cache --build-arg PROJECT_NAME=${PROJECT_NAME} --build-arg BINARY=${BINARY_PREFIX}-$(1) --tag=${IMAGE_PREFIX}-$(1) -f deployments/docker/Dockerfile.cleanbuild .
endef

define make_docker
	docker build --build-arg BINARY=${BINARY_PREFIX}-$(1) --tag=${IMAGE_PREFIX}-$(1) -f deployments/docker/$(2) ./build
endef


cleanbuild_dockers: $(DOCKERS_CLEANBUILD)


login:
	curl -X "POST" "http://localhost:8000/base/login" -H 'Content-Type: application/json; charset=utf-8' -d '{ "password": "123456", "username": "brown"}'
