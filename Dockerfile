FROM maven:3-openjdk-11 as builder
MAINTAINER joost@tmmrman.nl

RUN apt-get update \
    && apt-get -y -q install --no-install-recommends \
        npm \
        grunt \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR source

# Cache maven dependencies until one of the poms change
COPY ./pom.xml                  .
COPY ./docs-core/pom.xml        ./docs-core/
COPY ./docs-web-common/pom.xml  ./docs-web-common/
COPY ./docs-web/pom.xml         ./docs-web/
RUN mvn org.apache.maven.plugins:maven-dependency-plugin:3.2.0:go-offline -Dsilent=true -DexcludeGroupIds=com.sismics.docs

# Any other resource change may now trigger a rebuild
COPY ./docs-core/               ./docs-core/
COPY ./docs-web-common/         ./docs-web-common/
COPY ./docs-web/                ./docs-web/

RUN mvn clean package -T1C -Pprod -DskipTests

FROM jetty:9-jre11-slim
MAINTAINER joost@tmmrman.nl

USER root
RUN apt-get update \
    && apt-get -y -q install --no-install-recommends \
        ffmpeg \
        mediainfo \
        tesseract-ocr \
        tesseract-ocr-fra \
        tesseract-ocr-ita \
        tesseract-ocr-kor \
        tesseract-ocr-rus \
        tesseract-ocr-ukr \
        tesseract-ocr-spa \
        tesseract-ocr-ara \
        tesseract-ocr-hin \
        tesseract-ocr-deu \
        tesseract-ocr-pol \
        tesseract-ocr-jpn \
        tesseract-ocr-por \
        tesseract-ocr-tha \
        tesseract-ocr-jpn \
        tesseract-ocr-chi-sim \
        tesseract-ocr-chi-tra \
        tesseract-ocr-nld\
        tesseract-ocr-tur\
        tesseract-ocr-heb\
        tesseract-ocr-hun\
        tesseract-ocr-fin\
        tesseract-ocr-swe\
        tesseract-ocr-lav\
        tesseract-ocr-dan\
        tesseract-ocr-nor\
        tesseract-ocr-vie\
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /data && chown jetty: /data
VOLUME /data

USER jetty




# Remove the embedded javax.mail jar from Jetty
RUN rm -f /opt/jetty/lib/mail/javax.mail.glassfish-*.jar

COPY ./docs.xml /var/lib/jetty/webapps/ROOT.xml
COPY --from=builder /source/docs-web/target/docs-web-*.war /var/lib/jetty/webapps/ROOT.war

ENV JAVA_OPTIONS -Xmx1g
