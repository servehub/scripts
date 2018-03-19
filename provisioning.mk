module ?= 'shell'
docker_registry_ssh ?= 'user@server'

test:
	echo '${docker_registry_ssh}'

run:
	@echo -ne "\n\033[0;33m===> $$ "
	@echo ${cmd}
	@echo -e "\033[0m"

	docker run --rm -ti \
		-v ${PWD}:/src \
		-w /src/${wd} \
		-e AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY \
		${args} \
		servehub/provisioning-tools:1.0 \
			/bin/bash -c "${cmd}" \

terraform-init:
	@make run wd=terraform cmd="terraform init"

terraform-plan:
	@make run wd=terraform cmd="terraform plan"

terraform-apply:
	@make run wd=terraform cmd="terraform apply"

tag-spot-instances:
	@make run cmd="python scripts/tag-spots.py --region eu-central-1"

ansible-qa:
	@make run \
		wd=ansible \
		args='-e ANSIBLE_INVENTORY_FILTERS="tag:env=qa,tag:role=*common*" ${args}' \
		cmd="ansible-playbook -vv playbook.yml --vault-id ../.secrets/vault-password --private-key=../.secrets/terraform_rsa ${cmd}"

ansible-live:
	@make run \
		wd=ansible \
		args='-e ANSIBLE_INVENTORY_FILTERS="tag:env=live,tag:role=*common*" ${args}' \
		cmd="ansible-playbook -vv playbook.yml --vault-id ../.secrets/vault-password --private-key=../.secrets/terraform_rsa ${cmd}"

ansible-vpn:
	@make run \
		wd=ansible \
		args='-e ANSIBLE_INVENTORY_FILTERS="tag:role=openvpn-server"' \
		cmd="ansible-playbook -vv openvpn.yml --vault-id ../.secrets/vault-password --private-key=../.secrets/terraform_rsa ${cmd}"

ansible-encrypt:
	@make run cmd="ansible-vault encrypt_string --vault-id .secrets/vault-password '${value}' --name='${name}'"

ansible-shell:
	@make run \
		wd=ansible \
		args='-e ANSIBLE_INVENTORY_FILTERS="${filter}"' \
		cmd="ansible -m ${module} -a '${cmd}' -i inventory/ec2.py --vault-id ../.secrets/vault-password --private-key=../.secrets/terraform_rsa all"

create-user:
	$(eval sha512 = `python -c "import passlib.hash; print passlib.hash.sha512_crypt.using(rounds=5000).hash('${pass}')"`)
	$(eval sha1 = `python -c "import sha, base64; print base64.b64encode(sha.new('${pass}').digest())"`)
	@echo '{ user: "'${name}'", sha512: "'${sha512}'", sha1: "'${sha1}'" }'

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
