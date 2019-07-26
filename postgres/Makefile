SHELL:=/bin/bash

user ?= ubuntu
postgres_image ?= servehub/stolon
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

	docker run --rm --name postgres_stapshot -p 5432:5432 -v ${PWD}/data:/var/lib/postgresql/data ${postgres_image} -c 'wal_level=minimal' -c 'max_wal_size=80MB' -c 'min_wal_size=40MB' -c 'max_wal_senders=0' -c 'wal_keep_segments=0'

update-snapshot:
	ssh ${user}@${postgres_host} \
		'docker exec ${postgres_container} /bin/bash -c "pg_dumpall --host=127.0.0.1 --port=${postgres_port} -U postgres" | gzip > /tmp/dbdump.gz'

	scp ${user}@${postgres_host}:/tmp/dbdump.gz ./dump.gz

	gunzip dump.gz
	mv ${PWD}/dump ${PWD}/data/backup-all.sql
	docker exec -ti postgres_stapshot bash -c 'psql -U postgres < /var/lib/postgresql/data/backup-all.sql'

build-and-push:
	-docker stop postgres_stapshot
	-rm ${PWD}/data/backup-all.sql

	echo 'FROM ${postgres_image}' > Dockerfile
	echo '' >> Dockerfile
	echo 'COPY --chown=postgres ./data /var/lib/postgresql/data' >> Dockerfile

	docker build -t ${docker_image} .
	docker push ${docker_image}
