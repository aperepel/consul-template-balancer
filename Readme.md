# Consul template integrated with HAProxy

A build used for demos - don't use in production.

An awesome [Consul Template](https://hashicorp.com/blog/introducing-consul-template.html) project
updates HAProxy configuration in near-realtime and reloads the balancer config based on Consul cluster
membership changes. For this demo, the focus is on a single service (farm of servers), not a major
deployment with multiple virtual hosts, there are plenty of high-quality HAProxy base images you can use,
but they come with more set up complexity.

## Components
- Consul
- Registrator
- Consul Template
- HAProxy


## Running
It's a multi-step process, instructions below will let you observe things in different terminals. Otherwise these can be wrapped in [Docker Compose](https://docs.docker.com/compose/) for a 1-liner startup.

#### Find out the Docker network IP
```bash
BRIDGE_IP=$(docker run --rm debian:jessie ip ro | grep default | cut -d" " -f 3)
```

#### Start Consul
Bind to all interfaces for easier interaction of boot2docker and tools on a Mac (otherwise just use `${BRIDGE_IP}` instead of `0.0.0.0`)
```bash
docker run -d \
    -h node1 \
    --name=consul \
    -p 0.0.0.0:53:53/udp \
    -p 0.0.0.0:8400:8400 \
    -p 0.0.0.0:8500:8500 \
    sequenceiq/consul:v0.5.0 -server -bootstrap -advertise $BRIDGE_IP
```

#### Start Registrator
```bash
docker run -d --name=registrator -v /var/run/docker.sock:/tmp/docker.sock gliderlabs/registrator consul://$BRIDGE_IP:8500
```

To see Registrator in action:
```bash
docker logs -f registrator
```

#### Start HAProxy with Consul Template

Listen on port 80 and manage
```bash
docker run -d --name consul_templ -p 80:80 -v `pwd`:/consul-template aperepel/consul-template-haproxy
```


(Optional) Mapping the volume:

```bash
docker run -d --name consul_templ -p 80:80 -v `pwd`:/consul-template aperepel/consul-template-haproxy
```

*Note:* you can also map the `haproxy.cfg.tmpl` file only, but mapping a directory will let you easily monitor the template processing results in `haproxy.cfg`.



#### Start backend web servers

If you're happy with basic HAProxy settings as listed in the next section, not much more to do other than launching a container and giving it a `SERVICE_NAME=web` environment variable - *this is important*, as Consul Template will be using this name for discovery by default.

```bash
docker run -d -P --name node1 -h node1 -e SERVICE_NAME=web jlordiales/python-micro-service:latest
docker run -d -P --name node2 -h node2 -e SERVICE_NAME=web jlordiales/python-micro-service:latest
docker run -d -P --name node3 -h node3 -e SERVICE_NAME=web jlordiales/python-micro-service:latest
```

Go to your host exposed address, for boot2docker this will be http://192.168.59.103/haproxy. Watch how it greets you from different node every time (round-robin balancer).

*Tip:* this image doesn't care what you are running, as long as it talks HTTP (but see below, this can be customized).



#### Running with a custom template

Current local directory should have a file `haproxy.cfg.tmpl` like this (feel free to modify):
```
defaults
   mode http
   timeout client  5000ms

frontend  http
   bind *:80
   option http-server-close
   option forwardfor header X-Real-IP
   use_backend tomcat
   stats enable
   stats uri /haproxy

backend tomcat
  timeout connect 5000ms
  timeout server  5000ms
  balance roundrobin
  {{range service "web"}}
  server {{.Name}}.{{.Port}} {{.Address}}:{{.Port}} check{{end}}
```


## Extras
There's a lot of moving pieces, here's a trick to help one make more sense of it all:
- Mounted a directory with a custom template, as recommended above
- Keep the `registrator` terminal visible and follow its logs with `docker logs -f registrator`
- Open the `haproxy.cfg` file in a text editor which supports auto-refresh (e.g. [Atom](https://atom.io/) is great at this)
- Open a browser and go to HAProxy stats (available at your host's addrss, for boot2docker this is usually http://192.168.59.103/haproxy)
- (Good idea) turn on a 1s auto-refresh for the HAProxy stats page (e.g. any browser extension like [Auto Refresh Plus](https://chrome.google.com/webstore/detail/auto-refresh-plus/hgeljhfekpckiiplhkigfehkdpldcggm?hl=en) will do)
- Kill, start and stop containers at will:
```bash
docker kill node2
docker stop node1 node3
docker start node1 node2 node3
```
Watch events processed in the registrator window, observe changes to the `haproxy.cfg` file (list of servers available), notice how HAProxy stats page updates the backend servers list on config reloads.

If you want to get into this image's shell (there's no `bash` installed, only `sh`):
```bash
# assuming we named the container 'consul_templ'
docker exec -it consul_templ sh
```
