# syntax=docker/dockerfile:1.7

# ---- Build stage ----
FROM maven:3.9-eclipse-temurin-21 AS build
LABEL org.opencontainers.image.source="https://github.com/Mamoykun/sawit-app"
WORKDIR /app

# Cache deps separately so layer is reused when only src changes
COPY pom.xml .
RUN --mount=type=cache,target=/root/.m2 mvn dependency:go-offline -B

# Build
COPY src ./src
RUN --mount=type=cache,target=/root/.m2 mvn package -DskipTests -B && \
    cp target/*.jar /app/app.jar

# ---- Runtime stage ----
FROM eclipse-temurin:21-jre-alpine

LABEL org.opencontainers.image.title="Sawitku Backend"
LABEL org.opencontainers.image.description="Spring Boot backend for Sawitku palm oil farm app"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.source="https://github.com/Mamoykun/sawit-app"

# Tools for healthcheck + observability; set Jakarta timezone
RUN apk add --no-cache curl tzdata && \
    cp /usr/share/zoneinfo/Asia/Jakarta /etc/localtime && \
    echo "Asia/Jakarta" > /etc/timezone

# Non-root user
RUN addgroup -S sawitku && adduser -S -G sawitku sawitku

WORKDIR /app
COPY --from=build --chown=sawitku:sawitku /app/app.jar app.jar

USER sawitku
EXPOSE 8080

# JVM tuning for container environments
ENV JAVA_OPTS="-XX:+UseG1GC -XX:MaxRAMPercentage=75.0 -XX:InitialRAMPercentage=50.0 -Djava.security.egd=file:/dev/./urandom"

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD curl -fsS http://localhost:8080/actuator/health/liveness || exit 1

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
