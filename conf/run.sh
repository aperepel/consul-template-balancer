#!/bin/sh

# generate a file from a template for haproxy to pick up
consul-template -consul ${CONSUL_URL} -template /consul-template/haproxy.cfg.tmpl:/consul-template/haproxy.cfg -once
haproxy -f ./haproxy.cfg -p /var/run/haproxy.pid -D

# launch consul-template and hook up a graceful haproxy restart (from haproxy docs)
consul-template -consul ${CONSUL_URL} \
                -template "/consul-template/haproxy.cfg.tmpl:/consul-template/haproxy.cfg:haproxy -D -f ./haproxy.cfg -p /var/run/haproxy.pid -sf \$(cat /var/run/haproxy.pid)"
