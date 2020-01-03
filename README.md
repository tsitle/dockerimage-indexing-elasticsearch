# Elasticsearch Docker Image for AMD64 and AARCH64

Provides an Elasticsearch server.

## Elasticsearch TCP Port
The service is listening on TCP ports 9200 and 9300 by default.

## Docker Container usage
The following command will start an Elasticsearch server that is listening on ports 9206 and 9306.

```
$ docker run \
		--rm \
		-d \
		-v "$(pwd)/mpdata/es":"/usr/share/elasticsearch/data" \
		-p "9206:9200" \
		-p "9306:9300" \
		-e "xpack.security.enabled=false" \
		-e "ES_JAVA_OPTS=-Xms512m -Xmx512m" \
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

Without the environment variable **ES_JAVA_OPTS** set in the command above Elasticsearch will require 2GB of RAM.  
When using Docker on a Mac you'll then need to increase the amount of RAM (memory)
that Docker can use. To do so navigate to the prefences of the Docker Desktop app
and set the memory limit to something greater than 2GB in the "Advanced" tab.  
Otherwise Elasticsearch will crash as soon as it receives a connection.
