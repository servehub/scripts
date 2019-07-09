SHELL:=/bin/bash

version ?= 1.4.1

build-provisioning-tools:
	docker build -t servehub/provisioning-tools:${version} -t servehub/provisioning-tools:latest .

push-provisioning-tools:
	docker push servehub/provisioning-tools:${version}
	docker push servehub/provisioning-tools:latest
