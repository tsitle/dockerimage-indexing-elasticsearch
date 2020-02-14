ARG CF_SRC_OS_IMAGE

FROM ${CF_SRC_OS_IMAGE}

ARG CF_ES_VERSION

ENV ELASTIC_CONTAINER true
ENV PATH /usr/share/elasticsearch/bin:$PATH

#
ENV DEBIAN_FRONTEND=noninteractive

RUN \
	apt-get update \
	&& apt-get upgrade -y \
	&& apt-get dist-upgrade -y \
	&& apt-get install -y --no-install-recommends \
			openjdk-8-jre \
			sudo

RUN \
	groupadd -g 1000 elasticsearch \
	&& useradd -u 1000 -g 1000 -d /usr/share/elasticsearch -m elasticsearch

WORKDIR /usr/share/elasticsearch

USER elasticsearch
ENV HOME=/usr/share/elasticsearch

COPY files/elasticsearch-${CF_ES_VERSION}.tgz /usr/share/elasticsearch/
RUN \
	tar zxf elasticsearch-${CF_ES_VERSION}.tgz --strip-components=1 \
	&& rm elasticsearch-${CF_ES_VERSION}.tgz

#
RUN \
	set -ex \
	&& for esdirs in config data logs; do \
		mkdir -p "$esdirs"; \
		chmod 0775 "$esdirs"; \
	done

COPY files/files-es/config/elasticsearch.yml config/
COPY files/files-es/bin/es-docker bin/es-docker

USER root

RUN \
	cp /root/.bashrc . \
	&& chown elasticsearch:elasticsearch .bashrc

RUN \
	chown elasticsearch:elasticsearch \
			config/elasticsearch.yml \
			bin/es-docker \
	&& chmod 0750 bin/es-docker

COPY files/es-docker-wrapper.sh bin/
RUN chmod 0750 bin/es-docker-wrapper.sh

#
ENV DEBIAN_FRONTEND=dialog

VOLUME /usr/share/elasticsearch/data

USER root
CMD ["/bin/bash", "bin/es-docker-wrapper.sh"]

EXPOSE 9200 9300
