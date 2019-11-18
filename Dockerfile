ARG NEXUS_VERSION=3.19.1

FROM maven:3-jdk-8-alpine AS build
ARG NEXUS_VERSION=3.19.1
ARG NEXUS_BUILD=01

WORKDIR build
COPY ["pom.xml", "./"]
COPY ["nexus-repository-composer", "./nexus-repository-composer"]
COPY ["nexus-repository-composer-it", "./nexus-repository-composer-it"]

RUN sed -i "s/3.19.1-01/${NEXUS_VERSION}-${NEXUS_BUILD}/g" pom.xml && \
    sed -i "s/3.19.1-01/${NEXUS_VERSION}-${NEXUS_BUILD}/g" nexus-repository-composer/pom.xml && \
    sed -i "s/3.19.1-01/${NEXUS_VERSION}-${NEXUS_BUILD}/g" nexus-repository-composer-it/pom.xml && \
    mvn clean package;

FROM sonatype/nexus3:$NEXUS_VERSION
ARG NEXUS_VERSION=3.19.1
ARG NEXUS_BUILD=01
ARG COMPOSER_VERSION=0.0.2
ARG TARGET_DIR=/opt/sonatype/nexus/system/org/sonatype/nexus/plugins/nexus-repository-composer/${COMPOSER_VERSION}/
ARG COMP_VERSION=1.18

USER root
RUN mkdir -p ${TARGET_DIR}; \
    sed -i "s@nexus-repository-maven</feature>@nexus-repository-maven</feature>\n        <feature version=\"${COMPOSER_VERSION}\" prerequisite=\"false\" dependency=\"false\">nexus-repository-composer</feature>@g" /opt/sonatype/nexus/system/org/sonatype/nexus/assemblies/nexus-core-feature/${NEXUS_VERSION}-${NEXUS_BUILD}/nexus-core-feature-${NEXUS_VERSION}-${NEXUS_BUILD}-features.xml; \
    sed -i "s@<feature name=\"nexus-repository-maven\"@<feature name=\"nexus-repository-composer\" description=\"org.sonatype.nexus.plugins:nexus-repository-composer\" version=\"${COMPOSER_VERSION}\">\n        <details>org.sonatype.nexus.plugins:nexus-repository-composer</details>\n        <bundle>mvn:org.sonatype.nexus.plugins/nexus-repository-composer/${COMPOSER_VERSION}</bundle>\n        <bundle>mvn:org.apache.commons/commons-compress/${COMP_VERSION}</bundle>\n    </feature>\n    <feature name=\"nexus-repository-maven\"@g" /opt/sonatype/nexus/system/org/sonatype/nexus/assemblies/nexus-core-feature/${NEXUS_VERSION}-${NEXUS_BUILD}/nexus-core-feature-${NEXUS_VERSION}-${NEXUS_BUILD}-features.xml;
COPY --from=build /build/nexus-repository-composer/target/nexus-repository-composer-${COMPOSER_VERSION}.jar ${TARGET_DIR}
USER nexus

RUN cat /opt/sonatype/nexus/system/org/sonatype/nexus/assemblies/nexus-core-feature/${NEXUS_VERSION}-${NEXUS_BUILD}/nexus-core-feature-${NEXUS_VERSION}-${NEXUS_BUILD}-features.xml


VOLUME /sonatype-work