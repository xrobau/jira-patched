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
RUN wget -O /tmp/jira.bin ${JIRA_URL} && \
    chmod +x /tmp/jira.bin && \
    /tmp/jira.bin -q -varfile ${JIRA_SCRIPTS}/response.varfile && \
    rm -f /tmp/jira.bin && \
    chown -R 1000.1000 /opt/jira

# Install MySQL database driver
RUN rm -f ${JIRA_INSTALL}/lib/mysql-connector-java*.jar && \
    wget -O /tmp/mysql-connector-java-${MYSQL_DRIVER_VERSION}.tar.gz                                              \
      http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MYSQL_DRIVER_VERSION}.tar.gz      &&  \
    tar xzf /tmp/mysql-connector-java-${MYSQL_DRIVER_VERSION}.tar.gz                                              \
      --directory=/tmp                                                                                        &&  \
    cp /tmp/mysql-connector-java-${MYSQL_DRIVER_VERSION}/mysql-connector-java-${MYSQL_DRIVER_VERSION}-bin.jar     \
      ${JIRA_INSTALL}/lib/mysql-connector-java-${MYSQL_DRIVER_VERSION}-bin.jar && \
    rm -rf /tmp/mysql-conn*

# User and group is added by jira.bin
#RUN grep -q jira:x:1000: /etc/group || addgroup --gid ${CONTAINER_GID} ${CONTAINER_GROUP}
#RUN grep -q jira:x:1000: /etc/passwd || adduser --uid ${CONTAINER_UID} --ingroup ${CONTAINER_GROUP} --home /home/${CONTAINER_USER} --shell /bin/bash ${CONTAINER_USER}

RUN apt-get update && \
	apt-get -y install patch bbe vim && \
	apt-get -y clean && \
	mkdir -p /usr/local/patch/src /usr/local/patch/out

COPY fernflower.jar /usr/local/patch/fernflower.jar
ENV EXTRAS=3.4.6

# This patch alters the Verson2LicenseDecoder.class so it does not check signature
# validation as well as overriding the contents of the licence to allow the
# current version to run.
COPY extras.patch /usr/local/patch
RUN export SRC=/opt/jira/atlassian-jira/WEB-INF/lib/atlassian-extras-${EXTRAS}.jar && \
    cp $SRC $SRC.orig && \
    cd /usr/local/patch && \
    java -jar fernflower.jar -hdc=0 -dgs=1 -rsy=1 -lit=1 $SRC out/ && \
    cd /usr/local/patch/out && \
    unzip atlassian-extras-${EXTRAS}.jar com/atlassian/extras/decoder/v2/Version2LicenseDecoder.java && \
    patch -p1 < /usr/local/patch/extras.patch && \
    sed -E -i \
	-e '/this.loadLicenseConfig/a properties.setProperty("MaintenanceExpiryDate", "2029-01-01");' \
	-e '/this.loadLicenseConfig/a properties.setProperty("CreationDate", "2028-01-01");' \
	-e '/this.loadLicenseConfig/a properties.setProperty("PurchaseDate", "2028-01-01");' \
	com/atlassian/extras/decoder/v2/Version2LicenseDecoder.java && \
    cp com/atlassian/extras/decoder/v2/Version2LicenseDecoder.java /opt/jira/atlassian-jira/WEB-INF/lib/

# Recompile and put it back in place
RUN cd /opt/jira/atlassian-jira/WEB-INF/lib/ && \
	javac --source 8 --target 8 -cp commons-codec-1.15.jar:atlassian-extras-${EXTRAS}.jar:atlassian-extras-common-${EXTRAS}.jar:atlassian-extras-key-manager-${EXTRAS}.jar \
		Version2LicenseDecoder.java -d . && \
	jar -uf atlassian-extras-${EXTRAS}.jar com/atlassian/extras/decoder/v2/Version2LicenseDecoder.class

# This just changes the ForceLicenseDetector to crash Jira, instead of just
# popping up a warning. Isn't needed, but handy if you're doing other things
# with the licence stuff.
RUN export WI=/opt/jira/atlassian-jira/WEB-INF/ && \
	cd $WI/classes/ && \
	java -jar /usr/local/patch/fernflower.jar -hdc=0 -dgs=1 -rsy=1 -lit=1 com/atlassian/jira/license/CachingForgedLicenseDetectorImpl.class com/atlassian/jira/license/ && \
	ls -al com/atlassian/jira/license/*java && \
	sed -i 's/return true/throw var3/' com/atlassian/jira/license/CachingForgedLicenseDetectorImpl.java && \
	javac --source 8 --target 8 -cp ./:$WI/lib/atlassian-extras-${EXTRAS}.jar:$WI/lib/atlassian-cache-api-5.4.3.jar:$WI/lib/jira-api-8.22.2.jar com/atlassian/jira/license/CachingForgedLicenseDetectorImpl.java -d .


# I couldn't really get this working, it was never happy about the Build Date,
# so I ended up realising it was just easier to override the date in the
# license itself. This also means it's harder for people to cheat and give
# themselves entitlements they're not meant to have.
#ENV API=4.3.7
#RUN cd /opt/jira/atlassian-jira/WEB-INF/lib && \
#	unzip crowd-integration-api-${API}.jar com/atlassian/crowd/util/build/BuildUtils.class && \
#	export SRC=com/atlassian/crowd/util/build/BuildUtils.class && \
#	export CURRENT=$(strings $SRC | grep Parse\ date: | sed -r 's/.+date: ([^ ]+)\..+$/\1/') && \
#	echo "Setting to 2000-01-01 from $CURRENT" && \
#	cp $SRC $SRC.orig && \
#	bbe -o $SRC -e "s/$CURRENT/2000-01-01/" $SRC.orig && \
#	jar -uf crowd-integration-api-${API}.jar $SRC
#
#RUN cd /opt/jira/atlassian-jira/WEB-INF/classes/com/atlassian/jira/util && \
#	cp BuildUtils.class BuildUtils.class.orig && \
#	export CURRENT=$(strings BuildUtils.class | grep Parse\ date: | sed -r 's/.+date: ([^ ]+)\..+$/\1/') && \
#	echo "Setting to 01-01-2000 from $CURRENT" && \
#	bbe -o BuildUtils.class -e "s/$CURRENT/01-01-2000/" BuildUtils.class.orig

USER jira
WORKDIR ${JIRA_HOME}
VOLUME ["/var/atlassian/jira"]
EXPOSE 8080
CMD ["/opt/jira/bin/start-jira.sh", "-fg"]

