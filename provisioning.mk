module ?= 'shell'
docker_registry_ssh ?= 'user@server'
project_name ?= project
project_name_upper ?= $(shell echo "${project_name}" | tr a-z A-Z)
aws_region ?= 'eu-west-1'
tty_enabled ?= -ti

ansible_qa_args ?=
ansible_live_args ?=

run:
	@echo -ne "\n\033[0;33m===> $$ "
	@echo ${cmd}
	@echo -e "\033[0m"

	docker run --rm ${tty_enabled} \
		-v ${PWD}:/src \
		-w /src/${wd} \
		-e AWS_ACCESS_KEY_ID=$$${project_name_upper}_AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY=$$${project_name_upper}_AWS_SECRET_ACCESS_KEY \
		-e AWS_DEFAULT_REGION=${aws_region} \
		${args} \
		servehub/provisioning-tools:latest \
			/bin/bash -c "${cmd}" \

terraform-init:
	@make run wd=terraform cmd="terraform init"

terraform-plan:
	@make run wd=terraform cmd="terraform plan"

terraform-apply:
	@make run wd=terraform cmd="terraform apply"

tag-spot-instances:
	@make run cmd="python scripts/tag-spots.py --region ${aws_region}"

ansible-qa:
	@make run \
		wd=ansible \
		args='-e ANSIBLE_INVENTORY_FILTERS="tag:env=qa,tag:role=*common*" ${args}' \
		cmd="ansible-playbook -vv playbook.yml ${ansible_qa_args} ${cmd}"

ansible-vpn:
	@make run \
		wd=ansible \
		args='-e ANSIBLE_INVENTORY_FILTERS="tag:role=*vpn*" ${args}' \
		cmd="ansible-playbook -vv playbook.yml ${ansible_qa_args} ${cmd}"

ansible-live:
	@make run \
		wd=ansible \
		args='-e ANSIBLE_INVENTORY_FILTERS="tag:env=live,tag:role=*common*" ${args}' \
		cmd="ansible-playbook -vv playbook.yml ${ansible_live_args} ${cmd}"

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
	@make run cmd="python scripts/new-db.py --name '${name}'"

gen-self-signed-ssl-keys:
	docker run --rm -it -v ${PWD}:/home -w /home svagi/openssl req -x509 -nodes -newkey rsa:2048 -keyout ssl.key -out ssl.crt

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
	ssh-keygen -f ${PWD}/.secrets/ssh_rsa_key
	ssh-keygen -f ${PWD}/.secrets/vault-password
	openssl req -x509 -nodes -newkey rsa:4096 -keyout ${PWD}/.secrets/marathon-secrets-qa.key -out ${PWD}/.secrets/marathon-secrets-qa.cer -subj "/CN=PKCS#7"
	openssl req -x509 -nodes -newkey rsa:4096 -keyout ${PWD}/.secrets/marathon-secrets-live.key -out ${PWD}/.secrets/marathon-secrets-live.cer -subj "/CN=PKCS#7"

prepare-new-server:
	ssh ${ssh} 'echo ${host} | sudo tee /etc/hostname'
	ssh ${ssh} 'sudo hostname $(cat /etc/hostname)'
	ssh ${ssh} 'sudo apt-get update && sudo apt-get -y install --fix-missing python-simplejson'

encrypt-secret:
	@echo -ne "\nEnter secret value for encryption: "
	@read value \
		&& echo -e "\n" \
		&& echo -n "$$value" | openssl smime -encrypt -outform pem .secrets/marathon-secrets-${env}.cer | base64
	@echo ""

encrypt-qa:
	@make encrypt-secret env=qa

encrypt-live:
	@make encrypt-secret env=live
