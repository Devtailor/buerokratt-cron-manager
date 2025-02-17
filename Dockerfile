FROM eclipse-temurin:17-jdk AS build
WORKDIR /workspace/app

COPY gradlew .
COPY gradlew.bat .
COPY gradle gradle
COPY build.gradle .
COPY src src
COPY .env .env
COPY scripts scripts
COPY DSL DSL

RUN chmod 754 ./gradlew
RUN ./gradlew -Pprod clean bootJar
RUN mkdir -p build/libs && (cd build/libs; jar -xf *.jar)

FROM eclipse-temurin:17-jdk
VOLUME /build/tmp

ARG DEPENDENCY=/workspace/app/build/libs
COPY --from=build ${DEPENDENCY}/BOOT-INF/lib /app/lib
COPY --from=build ${DEPENDENCY}/META-INF /app/META-INF
COPY --from=build ${DEPENDENCY}/BOOT-INF/classes /app
COPY DSL /DSL
COPY scripts /app/scripts/
COPY constants.ini /app/constants.ini
RUN chmod a+x /app/scripts/*

ENV application.config-path=/DSL

COPY .env /app/.env
RUN echo BUILDTIME=`date +%s` >> /app/.env

RUN useradd cronmanager
RUN chown -R cronmanager:cronmanager /app
RUN chown -R cronmanager:cronmanager /DSL
USER cronmanager

EXPOSE 9010

ENTRYPOINT ["java","-cp","app:app/lib/*","ee.buerokratt.cronmanager.CronManagerApplication"]
