# Consul template integrated with HAProxy

A build used for demos - don't use in production.
 
An awesome [Consul Template](https://hashicorp.com/blog/introducing-consul-template.html) project
updates HAProxy configuration in near-realtime and reloads the balancer config based on Consul cluster
membership changes. For this demo, the focus is on a single service (farm of servers), not a major
deployment with multiple virtual hosts, there are plenty of high-quality HAProxy base images you can use,
but they come with more set up complexity.