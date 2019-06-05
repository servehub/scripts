host ?= 'inf9'
env_domain ?= 'qa.example.com'

mesos-slave-down:
	$(eval ip=`ping -c 1 ${host}.${env_domain} | awk -F'[()]' '/PING/{print $$$$2}'`)

	@echo ' \
		{ \
		  "windows" : [{ \
		    "machine_ids" : [{ "hostname" : "${host}.${env_domain}", "ip": "'${ip}'" }], \
		    "unavailability" : { \
		      "start" : { "nanoseconds" : '`date +%s`'000000000 }, \
		      "duration" : { "nanoseconds" : 3600000000000 } \
		    } \
		  }] \
		}' | http -v POST http://mesos.${env_domain}/master/maintenance/schedule "Content-Type: application/json"

	sleep 3

	@echo ' \
		[ \
		  { "hostname" : "${host}.${env_domain}", "ip": "'${ip}'" } \
		]' | http -v POST http://mesos.${env_domain}/machine/down "Content-Type: application/json"

	sleep 1

	@make ansible-shell cmd='docker-compose -f /etc/compose/mesos-slave.yml down' filter="tag:Name=${host}.${env_domain}"

	curl http://marathon.live.boople.co/v2/tasks \
		| jq '{"ids": [.tasks[] | select(.host == "${host}.${env_domain}").id]}' \
		| http -v POST http://marathon.${env_domain}/v2/tasks/delete

mesos-slave-up:
	$(eval ip=`ping -c 1 ${host}.${env_domain} | awk -F'[()]' '/PING/{print $$$$2}'`)

	@echo ' \
		[ \
		  { "hostname" : "${host}.${env_domain}", "ip": "'${ip}'" } \
		]' | http -v POST http://mesos.${env_domain}/machine/up "Content-Type: application/json"

	@make ansible-shell cmd='docker-compose -f /etc/compose/mesos-slave.yml up -d --force-recreate' filter="tag:Name=${host}.${env_domain}"
