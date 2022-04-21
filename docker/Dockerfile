FROM openjdk:jdk-bullseye
MAINTAINER Rob Thomas <xrobau@gmail.com>

ARG JIRA_VERSION
ARG JIRA_FILE
ARG JIRA_URL
ARG CONTAINER_UID=1000
ARG CONTAINER_USER=jira
ARG CONTAINER_GID=1000
ARG CONTAINER_GROUP=jira
ARG LANG_LANGUAGE=en
ARG LANG_COUNTRY=US
ARG BUILD_DATE=undefined

ENV JIRA_USER=jira                            \
    JIRA_GROUP=jira                           \
    JIRA_CONTEXT_PATH=ROOT                    \
    JIRA_HOME=/var/atlassian/jira             \
    JIRA_INSTALL=/opt/jira                    \
    JIRA_SCRIPTS=/usr/local/share/atlassian   \
    MYSQL_DRIVER_VERSION=5.1.46               \
    DOCKERIZE_VERSION=v0.6.1

ENV LANG=${LANG_LANGUAGE}_${LANG_COUNTRY}.UTF-8

COPY imagescripts ${JIRA_SCRIPTS}

# Install Jira
RUN wget -O /tmp/jira.bin ${JIRA_URL}
RUN chmod +x /tmp/jira.bin &&  /tmp/jira.bin -q -varfile ${JIRA_SCRIPTS}/response.varfile
# Install MySQL database driver
RUN rm -f ${JIRA_INSTALL}/lib/mysql-connector-java*.jar
RUN wget -O /tmp/mysql-connector-java-${MYSQL_DRIVER_VERSION}.tar.gz                                              \
      http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MYSQL_DRIVER_VERSION}.tar.gz      &&  \
    tar xzf /tmp/mysql-connector-java-${MYSQL_DRIVER_VERSION}.tar.gz                                              \
      --directory=/tmp                                                                                        &&  \
    cp /tmp/mysql-connector-java-${MYSQL_DRIVER_VERSION}/mysql-connector-java-${MYSQL_DRIVER_VERSION}-bin.jar     \
      ${JIRA_INSTALL}/lib/mysql-connector-java-${MYSQL_DRIVER_VERSION}-bin.jar

# Add group if it doesn't exist
RUN grep -q jira:x:1000: /etc/group || addgroup --gid ${CONTAINER_GID} ${CONTAINER_GROUP}
RUN grep -q jira:x:1000: /etc/passwd || adduser --uid ${CONTAINER_UID} --ingroup ${CONTAINER_GROUP} --home /home/${CONTAINER_USER} --shell /bin/bash ${CONTAINER_USER}

RUN apt-get update && apt-get -y install patch && mkdir /usr/local/patch
RUN mkdir -p /usr/local/patch/src
COPY fernflower.jar /usr/local/patch/fernflower.jar
ENV EXTRAS=3.4.6
COPY extras.patch /usr/local/patch
RUN cp /opt/jira/atlassian-jira/WEB-INF/lib/atlassian-extras-${EXTRAS}.jar /usr/local/patch/src
RUN cd /usr/local/patch && mkdir out && java -jar fernflower.jar -hdc=0 -dgs=1 -rsy=1 -lit=1 src/atlassian-extras-${EXTRAS}.jar out/
RUN cd /usr/local/patch/out && unzip *jar && cp com/atlassian/extras/decoder/v2/Version2LicenseDecoder.java /opt/jira/atlassian-jira/WEB-INF/lib/
RUN cd /opt/jira/atlassian-jira/WEB-INF/lib/ && \
	javac -cp commons-codec-1.15.jar:atlassian-extras-${EXTRAS}.jar:atlassian-extras-common-${EXTRAS}.jar:atlassian-extras-key-manager-${EXTRAS}.jar \
		Version2LicenseDecoder.java -d . && \
	jar -uf atlassian-extras-${EXTRAS}.jar com/atlassian/extras/decoder/v2/Version2LicenseDecoder.class

USER jira
WORKDIR ${JIRA_HOME}
VOLUME ["/var/atlassian/jira"]
EXPOSE 8080
#ENTRYPOINT ["/sbin/tini","--","/usr/local/share/atlassian/docker-entrypoint.sh"]
#CMD ["jira"]
CMD ["/bin/bash"]
