# Elasticsearch Docker Image for AARCH64, ARMv7l, X86 and X64

Provides an Elasticsearch server.

## Elasticsearch TCP Port
The service is listening on TCP ports 9200 and 9300 by default.

## Docker Container usage
See the related GitHub repository [https://github.com/tsitle/dockercontainer-indexing-elasticsearch](https://github.com/tsitle/dockercontainer-indexing-elasticsearch)
for an example startup script.

The following command will start an Elasticsearch server that is listening on ports 9206 and 9306.

```
$ docker run \
		--rm \
		-d \
		-v "$(pwd)/mpdata/es":"/usr/share/elasticsearch/data" \
		-p "9206:9200" \
		-p "9306:9300" \
		-e "discovery.type=single-node" \
		-e "http.cors.enabled=true" \
		-e "http.cors.allow-origin=/.*/" \
		-e "http.cors.allow-headers=X-Requested-With,X-Auth-Token,Content-Type,Content-Length,Authorization" \
		-e "http.cors.allow-credentials=true" \
		-e "CF_SYSUSR_ES_USER_ID=<YOUR_USER_ID>" \
		-e "CF_SYSUSR_ES_GROUP_ID=<YOUR_GROUP_ID>" \
		--name indexing-elasticsearch-cont \
		indexing-elasticsearch-<ARCH>:<VERSION>
```

--

For a complete AARCH64/ARM64 Docker Elasticsearch/Logstash/Kibana stack see
[https://github.com/gagara/docker-elk-arm64](https://github.com/gagara/docker-elk-arm64)
