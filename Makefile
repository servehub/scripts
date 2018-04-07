SHELL:=/bin/bash

version ?= 1.1

release-provisioning-tools:
	docker build -t servehub/provisioning-tools:${version} -t servehub/provisioning-tools:latest .
	docker push servehub/provisioning-tools:${version}
	docker push servehub/provisioning-tools:latest
