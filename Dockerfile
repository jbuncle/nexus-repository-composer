# At time of writing, 3.76 is compatible with the composer plugin; newer versions have issues
ARG NEXUS_VERSION=3.76.0

# Build stage: compile the Nexus composer bundle using Maven
FROM maven:3-jdk-8 AS build
ENV MAVEN_OPTS="-Xmx1024m"
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*
COPY . /nexus-repository-composer/
RUN cd /nexus-repository-composer/ && mvn clean package -PbuildKar

# Final stage: deploy the bundle on the Nexus image
FROM sonatype/nexus3:$NEXUS_VERSION
ARG DEPLOY_DIR=/opt/sonatype/nexus/deploy/

USER root
COPY --from=build /nexus-repository-composer/nexus-repository-composer/target/nexus-repository-composer-*-bundle.kar ${DEPLOY_DIR}
USER nexus

# Optionally add the Nexus DB Migrator for upgrades
ADD https://download.sonatype.com/nexus/nxrm3-migrator/nexus-db-migrator-3.70.4-02.jar /opt/sonatype/nexus/nexus-db-migrator-3.70.4-02.jar

# To upgrade:
# docker-compose run --rm --user=root nexus bash
# find /nexus-data/backup -mindepth 1 -not -name '*.bak' -exec rm -rf {} +
# cd /nexus-data/backup
# java -Xmx2G -Xms2G -XX:+UseG1GC -XX:MaxDirectMemorySize=28672M --add-opens java.base/sun.nio.ch=ALL-UNNAMED \
#      -jar /opt/sonatype/nexus/nexus-db-migrator-3.70.4-02.jar --migration_type=h2
