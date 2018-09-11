SHELL:=/bin/bash

user ?= ubuntu
postgres_image ?= postgres:10.2
postgres_host ?= localhost
docker_image ?= docker.example.com/tests/postgres-snapshot:latest

postgres_container ?= compose_stolon-proxy_1
postgres_port ?= 25432

#
# Dump QA database and create new image with snapshot
#
clear-and-run:
	rm -rf ${PWD}/data
	-docker stop postgres_stapshot
	-docker stop postgres

	docker run --rm --name postgres_stapshot -p 5432:5432 -v ${PWD}/data:/var/lib/postgresql/data ${postgres_image}

update-snapshot:
	ssh ${user}@${postgres_host} \
		'docker exec ${postgres_container} /bin/bash -c "pg_dumpall --host=127.0.0.1 --port=${postgres_port} -U postgres"' > ${PWD}/backup-all.sql

	mv ${PWD}/backup-all.sql ${PWD}/data/backup-all.sql
	docker exec -ti postgres_stapshot bash -c 'psql -U postgres < /var/lib/postgresql/data/backup-all.sql'

build-and-push:
	-docker stop postgres_stapshot
	-rm ${PWD}/data/backup-all.sql

	echo 'FROM ${postgres_image}' > Dockerfile
	echo '' >> Dockerfile
	echo 'COPY ./data /var/lib/postgresql/data' >> Dockerfile

	docker build -t ${docker_image} .
	docker push ${docker_image}
