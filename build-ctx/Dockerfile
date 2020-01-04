ARG CF_DEBIAN_RELEASE
ARG CF_DEBIAN_VERSION
ARG CF_CPUARCH_DEB_DIST

FROM tsle/os-debian-${CF_DEBIAN_RELEASE}-${CF_CPUARCH_DEB_DIST}:${CF_DEBIAN_VERSION}

ARG CF_CPUARCH_DEB_DIST

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
			openjdk-11-jre \
			sudo \
			p7zip

# Replace OpenJDK's built-in CA certificate keystore with the one from the OS
# vendor. The latter is superior in several ways.
# REF: https://github.com/elastic/elasticsearch-docker/issues/171
#RUN \
#	[ -f /etc/pki/ca-trust/extracted/java/cacerts ] \
#	&& ln -sf /etc/pki/ca-trust/extracted/java/cacerts /opt/jdk-11.0.1/lib/security/cacerts

RUN \
	groupadd -g 1000 elasticsearch \
	&& useradd -u 1000 -g 1000 -d /usr/share/elasticsearch -m elasticsearch

WORKDIR /usr/share/elasticsearch

USER elasticsearch
ENV HOME=/usr/share/elasticsearch

COPY files/elasticsearch-${CF_ES_VERSION}.tar.7z* /usr/share/elasticsearch/
RUN \
	7zr x -so "elasticsearch-${CF_ES_VERSION}.tar.7z.001" | tar xf - --strip-components=1 \
	&& rm elasticsearch-${CF_ES_VERSION}.tar.7z*

ENV PATH /usr/share/elasticsearch/bin:$PATH

#
RUN \
	set -ex \
	&& for esdirs in config data logs; do \
		mkdir -p "$esdirs"; \
		chmod 0775 "$esdirs"; \
	done

#
COPY files/ingest-user-agent-${CF_ES_VERSION}.zip /opt/ingest-user-agent.zip
COPY files/ingest-geoip-${CF_ES_VERSION}.zip /opt/ingest-geoip.zip

RUN \
	for PLUGIN in ingest-user-agent ingest-geoip; do \
		elasticsearch-plugin install --batch file:///opt/$PLUGIN.zip \
		|| exit 1; \
	done

COPY files/files-es/config/elasticsearch.yml files/files-es/config/log4j2.properties config/
COPY files/files-es/bin/docker-entrypoint.sh /usr/local/bin/

USER root

RUN \
	for PLUGIN in ingest-user-agent ingest-geoip; do \
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
		# remove unsupported JVM opts in ARM64
		mv config/jvm.options config/jvm.options.orig \
		&& sed -e 's/\(.*UseAVX=.*\)/#\1/' config/jvm.options.orig > config/jvm.options \
		|| exit 1; \
	fi

RUN \
	chown elasticsearch:elasticsearch \
			config/elasticsearch.yml \
			config/log4j2.properties \
	&& chmod 0755 /usr/local/bin/docker-entrypoint.sh

COPY files/es-docker-wrapper.sh bin/
RUN chmod 0750 bin/es-docker-wrapper.sh

#
ENV DEBIAN_FRONTEND=dialog

VOLUME /usr/share/elasticsearch/data

#ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
# Dummy overridable parameter parsed by entrypoint
#CMD ["eswrapper"]

USER root
CMD ["/bin/bash", "bin/es-docker-wrapper.sh"]

EXPOSE 9200 9300
