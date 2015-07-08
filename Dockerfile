FROM tomcat

MAINTAINER http://kieker-monitoring.net/support/

RUN \
  apt-get update && \
  apt-get install openjdk-7-jdk git -y

WORKDIR /opt

CMD ["/usr/local/tomcat/bin/catalina.sh", "run"]

EXPOSE 8080

# Set folder variables
ENV KIEKER_FOLDER /opt/kieker
ENV KIEKER_AGENT_FOLDER ${KIEKER_FOLDER}/agent
ENV KIEKER_CONFIG_FOLDER ${KIEKER_FOLDER}/config
ENV KIEKER_LOGS_FOLDER ${KIEKER_FOLDER}/logs
ENV KIEKER_WEBAPPS_FOLDER ${KIEKER_FOLDER}/webapps
ENV KIEKER_TOMCAT_METAINF_FOLDER /usr/local/tomcat/lib/META-INF
ENV KIEKER_TOMCAT_WEBAPPS_FOLDER /usr/local/tomcat/webapps

ENV KIEKER_EUREKA_FOLDER ${KIEKER_FOLDER}/eureka
ENV KIEKER_EUREKA_GIT "https://github.com/Netflix/eureka"

# Set other variables
ENV KIEKER_MONITORING_PROPERTIES kieker.monitoring.properties
ENV KIEKER_AGENT_JAR agent.jar
ENV KIEKER_AOP aop.xml

COPY ${KIEKER_MONITORING_PROPERTIES} ${KIEKER_CONFIG_FOLDER}/${KIEKER_MONITORING_PROPERTIES}
COPY ${KIEKER_AOP} ${KIEKER_CONFIG_FOLDER}/${KIEKER_AOP}

RUN \
  mkdir -p ${KIEKER_AGENT_FOLDER} && \
  mkdir -p ${KIEKER_LOGS_FOLDER} && \
  mkdir -p ${KIEKER_TOMCAT_METAINF_FOLDER} && \
  ln -s ${KIEKER_TOMCAT_WEBAPPS_FOLDER} ${KIEKER_WEBAPPS_FOLDER}

RUN  \
  git clone ${KIEKER_EUREKA_GIT} ${KIEKER_EUREKA_FOLDER} && \
  cd ${KIEKER_EUREKA_FOLDER} && \
  ./gradlew -x check -x test clean war  && \
  cp ${KIEKER_EUREKA_FOLDER}/eureka-server/build/libs/eureka-server*SNAPSHOT.war ${KIEKER_WEBAPPS_FOLDER}/eureka.war && \
  rm ${KIEKER_EUREKA_FOLDER} -r && \
  rm /root/.gradle -r
  
WORKDIR /opt

ENV KIEKER_VERSION 1.12-20150708.003611-90
ENV KIEKER_AGENT_JAR_SRC kieker-${KIEKER_VERSION}-aspectj.jar
ENV KIEKER_AGENT_BASE_URL "https://oss.sonatype.org/content/groups/staging/net/kieker-monitoring/kieker/1.12-SNAPSHOT"
  
RUN \
  wget -q "${KIEKER_AGENT_BASE_URL}/${KIEKER_AGENT_JAR_SRC}" -O "${KIEKER_AGENT_FOLDER}/${KIEKER_AGENT_JAR}" && \
  ln -s ${KIEKER_CONFIG_FOLDER}/${KIEKER_AOP} ${KIEKER_TOMCAT_METAINF_FOLDER}/${KIEKER_AOP} && \
  sed -i '250i\'"export KIEKER_JAVA_OPTS=\" \
    -javaagent:${KIEKER_AGENT_FOLDER}/${KIEKER_AGENT_JAR} \
    -Dkieker.monitoring.configuration=${KIEKER_CONFIG_FOLDER}/${KIEKER_MONITORING_PROPERTIES} \
    -Dkieker.monitoring.writer.filesystem.AsyncFsWriter.customStoragePath=${KIEKER_LOGS_FOLDER} \
    -Daj.weaving.verbose=true \
    -Dkieker.monitoring.skipDefaultAOPConfiguration=true \
    \"" /usr/local/tomcat/bin/catalina.sh && \
  sed -i '251i\'"export JAVA_OPTS=\"\${KIEKER_JAVA_OPTS} \${JAVA_OPTS}\"" /usr/local/tomcat/bin/catalina.sh

VOLUME ["/opt/kieker"]
