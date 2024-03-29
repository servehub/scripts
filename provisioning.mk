module ?= 'shell'
docker_registry_ssh ?= 'user@server'
project_name ?= project
project_name_upper ?= $(shell echo "${project_name}" | tr a-z A-Z)
aws_region ?= 'eu-west-1'
tty_enabled ?= -ti
le_email ?= example@example.com

ansible_qa_args ?=
ansible_stage_args ?=
ansible_testnet_args ?=
ansible_live_args ?=

run:
	@echo -ne "\n\033[0;33m===> $$ "
	@echo ${cmd}
	@echo -e "\033[0m"

	@docker run -it --rm ${tty_enabled} \
		-v ${PWD}:/src \
		-w /src/${wd} \
		-e AWS_ACCESS_KEY_ID=$$${project_name_upper}_AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY=$$${project_name_upper}_AWS_SECRET_ACCESS_KEY \
		-e AWS_DEFAULT_REGION=${aws_region} \
		-v /run/host-services/ssh-auth.sock:/run/host-services/ssh-auth.sock \
		-e SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock \
		${args} \
		servehub/provisioning-tools:latest \
			/bin/bash -c "${cmd}" \

terraform-init:
	@make run wd=terraform cmd="terraform init"

terraform-plan:
	@make run wd=terraform cmd="terraform plan"

terraform-apply:
	@make run wd=terraform cmd="terraform apply"

terraform2-init:
	@make run wd=terraform2 cmd="terraform init"

terraform2-plan:
	@make run wd=terraform2 cmd="terraform plan"

terraform2-apply:
	@make run wd=terraform2 cmd="terraform apply"

tag-spot-instances:
	@make run cmd="python scripts/tag-spots.py --region ${aws_region}"

ansible-qa:
	@make run \
		wd=ansible \
		args='-e ANSIBLE_INVENTORY_FILTERS="tag:env=qa,tag:role=*common*,${filter}" ${args}' \
		cmd="ansible-playbook -vv $(if $(play), "${play}.yml", "playbook.yml") ${ansible_qa_args} ${cmd}"

ansible-stage:
	@make run \
		wd=ansible \
		args='-e ANSIBLE_INVENTORY_FILTERS="tag:env=stage,tag:role=*common*,${filter}" ${args}' \
		cmd="ansible-playbook -vv $(if $(play), "${play}.yml", "playbook.yml") ${ansible_stage_args} ${cmd}"

ansible-testnet:
	@make run \
		wd=ansible \
		args='-e ANSIBLE_INVENTORY_FILTERS="tag:env=testnet,tag:role=*common*,${filter}" ${args}' \
		cmd="ansible-playbook -vv $(if $(play), "${play}.yml", "playbook.yml") ${ansible_testnet_args} ${cmd}"

ansible-live:
	@make run \
		wd=ansible \
		args='-e ANSIBLE_INVENTORY_FILTERS="tag:env=live,tag:role=*common*,${filter}" ${args}' \
		cmd="ansible-playbook -vv $(if $(play), "${play}.yml", "playbook.yml") ${ansible_live_args} ${cmd}"

ansible-vpn:
	@make run \
		wd=ansible \
		args='-e ANSIBLE_INVENTORY_FILTERS="tag:role=*vpn*" ${args}' \
		cmd="ansible-playbook -vv $(if $(play), "${play}.yml", "playbook.yml") ${ansible_qa_args} ${cmd}"

ansible-encrypt:
	@make run cmd="ansible-vault encrypt_string --vault-id .secrets/vault-password '${value}' --name='${name}'"

ansible-shell:
	@make run \
		wd=ansible \
		args='-e ANSIBLE_INVENTORY_FILTERS="${filter}"' \
		cmd="ansible -m ${module} -a '${cmd}' -i inventory/ec2.py --vault-id ../.secrets/vault-password --private-key=../.secrets/terraform_rsa all"

awscli:
	@make run cmd="~/.local/bin/aws ${cmd}"

create-user:
	@make run cmd="python scripts/new-user.py --user '${name}' --password '${password}'"

create-db:
	@make run cmd="python scripts/new-db.py --name '${name}' --password '${password}'"

gen-self-signed-ssl-keys:
	docker run --rm -it -v ${PWD}:/home -w /home svagi/openssl req -x509 -nodes -newkey rsa:2048 -keyout ssl.key -out ssl.crt

#
# docker stop compose_journalbeat_1 && rm -f /var/data/journalbeat/journalbeat-pending-queue && docker start compose_journalbeat_1
#
journalbeat-restart:
	@make run \
		wd=ansible \
		args='-e ANSIBLE_INVENTORY_FILTERS="${filter}" ${args}' \
		cmd="ansible -m shell -a 'docker stop compose_journalbeat_1 && rm -f /var/data/journalbeat/journalbeat-pending-queue && docker start compose_journalbeat_1' -i inventory/ec2.py --private-key=../.secrets/terraform_rsa all"

cleanup-docker-registry:
	docker run --rm -ti lhanxetus/deckschrubber \
		-registry http://${docker_registry} -max_repos 256 -month 2 -latest 3 -debug

	ssh ${docker_registry_ssh} \
		'docker exec compose_docker-registry_1 bin/registry garbage-collect /etc/docker/registry/config.yml'

use-serve-configs:
	ln -sf ${PWD}/ansible/files/serve/conf.d /etc/serve
	ln -sf ${PWD}/ansible/files/serve/include.d /etc/serve

generate-secrets:
	ssh-keygen -f ${PWD}/.secrets/terraform_rsa
	ssh-keygen -f ${PWD}/.secrets/copy_db_ssh_key
	ssh-keygen -f ${PWD}/.secrets/github_ci_rsa
	ssh-keygen -f ${PWD}/.secrets/vault-password

	for env in qa stage testnet live; do \
		echo "Generate $$env key: "; \
		openssl genpkey -aes-256-cbc -algorithm RSA -out ${PWD}/.secrets/secrets-$$env-private.key -pkeyopt rsa_keygen_bits:4096 \
			&& openssl rsa -in ${PWD}/.secrets/secrets-$$env-private.key -pubout -out ${PWD}/.secrets/secrets-$$env-public.key; \
		echo ""; \
	done \

prepare-new-server:
	ssh ${ssh} 'echo ${host} | sudo tee /etc/hostname'
	ssh ${ssh} 'sudo hostname `cat /etc/hostname`'
	ssh ${ssh} 'sudo apt-get update && sudo apt-get -y install --fix-missing python-simplejson'

decrypt-secret:
	@echo ""
	@echo -n "$$value" | base64 -D > .in.enc
	-@docker run -ti --rm -v ${PWD}:/home -w /home svagi/openssl rsautl -decrypt -in .in.enc -inkey .secrets/secrets-${env}-private.key
	@echo -e "\n"
	@rm .in.enc

encrypt-secret:
	@echo -ne "\nEnter secret value for encryption: "
	-@read value \
		&& echo -e "\n" \
		&& echo -n "$$value" > .in.enc \
		&& docker run --rm -v ${PWD}:/home -w /home svagi/openssl rsautl -encrypt -in .in.enc -inkey keys/secrets-${env}-public.key -pubin | base64 | pbcopy \
		&& pbpaste

	@echo -e "\n"
	@rm .in.enc

encrypt-qa:
	@make encrypt-secret env=qa

encrypt-stage:
	@make encrypt-secret env=stage

encrypt-testnet:
	@make encrypt-secret env=testnet

encrypt-live:
	@make encrypt-secret env=live

#
# make le-certs domain='*.yandex.ru' hzid=Z1GYPKQAXXYYZZZ
#
le-certs:
	docker run -it --rm \
		-v ${PWD}/.secrets/le/etc:/etc/letsencrypt \
		-v ${PWD}/.secrets/le/lib:/var/lib/letsencrypt \
		certbot/certbot certonly --manual \
		--preferred-challenges dns-01 \
		--server https://acme-v02.api.letsencrypt.org/directory \
		--agree-tos \
		--renew-by-default \
		--manual \
		--manual-public-ip-logging-ok \
		--email "${le_email}" \
		-d '${domain}' \

le-validate:
	echo '{ \
	  "Changes": [{ \
	    "Action": "UPSERT", \
	    "ResourceRecordSet": { \
	      "Type": "TXT", \
	      "Name": "_acme-challenge.'${domain}'", \
	      "TTL": 0, \
	      "ResourceRecords": [{"Value": "\"'${validation}'\""}] \
	    } \
	  }] \
	}' > le-aws-validation.json

	cat le-aws-validation.json

	make awscli cmd="route53 change-resource-record-sets --hosted-zone-id=${hzid} --change-batch=file:///src/le-aws-validation.json" tty_enabled=''

	rm -f le-aws-validation.json
