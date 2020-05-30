PREFIX=docker-machine-driver-kvm
GO_VERSION=1.14.3
GO_LINUX_AMD64_SHA256=1c39eac4ae95781b066c144c58e45d6859652247f7515f0d2cba7be7d57d2226
DESCRIBE := $(shell git describe --tags)
MACHINE_VERSION ?= $(DESCRIBE)

TARGETS=$(addprefix $(PREFIX)-, alpine3.4 alpine3.5 ubuntu14.04 ubuntu16.04 centos7, debian10)

build: $(TARGETS)

$(PREFIX)-%: Dockerfile.%
	docker rmi -f $@ >/dev/null  2>&1 || true
	docker rm -f $@-extract > /dev/null 2>&1 || true
	echo "Building binaries for $@"
	mkdir -p artifacts
	docker build \
		--build-arg "BUILD_USER=$$(id -u):$$(id -g)" \
		--build-arg "GO_VERSION=$(GO_VERSION)" \
		--build-arg "GO_LINUX_AMD64_SHA256=$(GO_LINUX_AMD64_SHA256)" \
		--build-arg "BUILD_TARGET=$@" \
		-t $@-build -f $< .
	docker run \
		--user $$(id -u):$$(id -g) \
		-v "$$(pwd):/src:ro" \
		-v "$$(pwd)/artifacts:/artifacts" \
		--rm \
		$@-build \
		sh -c "mkdir -p /artifacts/$@/ && go build -v -mod=readonly -o /artifacts/$@/ ./cmd/docker-machine-driver-kvm"

clean:
	rm -f ./$(PREFIX)-*


release: build
	@echo "Paste the following into the release page on github and upload the binaries..."
	@echo ""
	@for bin in $(PREFIX)-* ; do \
	    target=$$(echo $${bin} | cut -f5- -d-) ; \
	    hash=$$(sha256sum $${bin}) ; \
	    echo "* $${target} - hash: $${hash}" ; \
	    echo '```' ; \
	    echo "  curl -L https://github.com/49nord/docker-machine-kvm/releases/download/$(DESCRIBE)/$${bin} > /usr/local/bin/$(PREFIX) \\ " ; \
	    echo "  chmod +x /usr/local/bin/$(PREFIX)" ; \
	    echo '```' ; \
	done

