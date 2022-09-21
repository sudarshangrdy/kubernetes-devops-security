FROM adoptopenjdk/openjdk8:alpine-slim
# Removed below to pass trivy image scan
#FROM openjdk:8-jdk-alpine
EXPOSE 8080
ARG JAR_FILE=target/*.jar
#Using COPY for compiling with OPA Conftest
#ADD ${JAR_FILE} app.jar
RUN addgroup -S pipeline && adduser -S k8s-pipeline -G pipeline
COPY ${JAR_FILE} /home/k8s-pipeline/app.jar
USER k8s-pipeline
#ENTRYPOINT ["java","-jar","/app.jar"]
ENTRYPOINT ["java","-jar","/home/k8s-pipeline/app.jar"]