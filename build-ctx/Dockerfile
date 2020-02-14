ARG CF_SRC_OS_IMAGE

FROM ${CF_SRC_OS_IMAGE}

ARG CF_CPUARCH_DEB_DIST

ARG CF_ES_VERSION

ENV ELASTIC_CONTAINER true
ENV PATH /usr/share/elasticsearch/bin:$PATH
#ENV JAVA_HOME /usr/lib/jvm/jre-1.8.0-openjdk

#
ENV DEBIAN_FRONTEND=noninteractive

#RUN yum update -y && yum install -y java-1.8.0-openjdk-headless wget which && yum clean all
RUN \
	apt-get update \
	&& apt-get upgrade -y \
	&& apt-get dist-upgrade -y \
	&& apt-get install -y --no-install-recommends \
			openjdk-11-jre \
			sudo

#RUN groupadd -g 1000 elasticsearch && adduser -u 1000 -g 1000 -d /usr/share/elasticsearch elasticsearch
RUN \
	groupadd -g 1000 elasticsearch \
	&& useradd -u 1000 -g 1000 -d /usr/share/elasticsearch -m elasticsearch

WORKDIR /usr/share/elasticsearch

USER elasticsearch
ENV HOME=/usr/share/elasticsearch

# Download and extract defined ES version.
#RUN curl -fsSL https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${CF_ES_VERSION}.tar.gz | \
#    tar zx --strip-components=1

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

# Install x-pack and also the ingest-{agent,geoip} modules required for Filebeat
#RUN for PLUGIN in x-pack ingest-user-agent ingest-geoip; do \
#      elasticsearch-plugin install --batch "$PLUGIN"; \
#    done

COPY files/x-pack-${CF_ES_VERSION}.zip /opt/x-pack.zip
COPY files/ingest-user-agent-${CF_ES_VERSION}.zip /opt/ingest-user-agent.zip
COPY files/ingest-geoip-${CF_ES_VERSION}.zip /opt/ingest-geoip.zip

RUN \
	for PLUGIN in x-pack ingest-user-agent ingest-geoip; do \
		elasticsearch-plugin install --batch file:///opt/$PLUGIN.zip \
		|| exit 1; \
	done

COPY files/files-es/elasticsearch.yml files/files-es/log4j2.properties config/
COPY files/files-es/x-pack/log4j2.properties config/x-pack/
COPY files/files-es/bin/es-docker bin/es-docker

USER root

RUN \
	for PLUGIN in x-pack ingest-user-agent ingest-geoip; do \
		rm /opt/$PLUGIN.zip; \
	done

RUN \
	cp /root/.bashrc . \
	&& chown elasticsearch:elasticsearch .bashrc \
	|| exit 1; \
	#
	if [ "$CF_CPUARCH_DEB_DIST" != "amd64" ]; then \
		/bin/echo -e "\n# X-Pack is not supported on AARCH64/ARMV7L/X86" >> config/elasticsearch.yml; \
		/bin/echo "xpack.ml.enabled: false" >> config/elasticsearch.yml; \
	fi

RUN chown elasticsearch:elasticsearch \
      config/elasticsearch.yml \
      config/log4j2.properties \
      config/x-pack/log4j2.properties \
      bin/es-docker && \
    chmod 0750 bin/es-docker

COPY files/es-docker-wrapper.sh bin/
RUN chmod 0750 bin/es-docker-wrapper.sh

#
ENV DEBIAN_FRONTEND=dialog

VOLUME /usr/share/elasticsearch/data

#USER elasticsearch
#CMD ["/bin/bash", "bin/es-docker"]
USER root
CMD ["/bin/bash", "bin/es-docker-wrapper.sh"]

EXPOSE 9200 9300
