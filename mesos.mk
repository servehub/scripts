mesos_host ?= 'localhost'

mesos-slave-down:
	$(eval ip=`ping -c 1 ${host} | awk -F'[()]' '/PING/{print $$$$2}'`)
	@echo ' \
		{ \
		  "windows" : [{ \
		    "machine_ids" : [{ "hostname" : "${host}", "ip": "'${ip}'" }], \
		    "unavailability" : { \
		      "start" : { "nanoseconds" : '`date +%s`'000000000 }, \
		      "duration" : { "nanoseconds" : 3600000000000 } \
		    } \
		  }] \
		}' | http -v POST http://${mesos_host}/maintenance/schedule "Content-Type: application/json"

	sleep 3

	@echo ' \
		[ \
		  { "hostname" : "${host}", "ip": "'${ip}'" } \
		]' | http -v POST http://${mesos_host}/machine/down "Content-Type: application/json"

	@make ansible-shell cmd='docker stop compose_mesos-slave_1' filter="tag:host=${host}"

mesos-slave-up:
	$(eval ip=`ping -c 1 ${host} | awk -F'[()]' '/PING/{print $$$$2}'`)
	@echo ' \
		[ \
		  { "hostname" : "${host}", "ip": "'${ip}'" } \
		]' | http -v POST http://${mesos_host}/machine/up "Content-Type: application/json"

	@make ansible-shell cmd='docker start compose_mesos-slave_1' filter="tag:host=${host}"
