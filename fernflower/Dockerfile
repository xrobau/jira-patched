FROM openjdk:jdk-bullseye
MAINTAINER Rob Thomas <xrobau@gmail.com>

RUN cd /usr/local && git clone https://github.com/fesh0r/fernflower
RUN cd /usr/local/fernflower && \
	./gradlew build && \
	./gradlew --stop


