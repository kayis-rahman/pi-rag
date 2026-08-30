# multi-stage Dockerfile: build with Maven, then run on a slim JRE image

# Build stage: compile and package the application
FROM maven:3.9.4-eclipse-temurin-17 AS build
WORKDIR /build
# copy pom and sources
COPY pom.xml ./
COPY src ./src
# package the application (skip tests for speed)
RUN mvn -B -DskipTests package

# Runtime stage: run the packaged jar
FROM eclipse-temurin:17-jre
WORKDIR /app
# copy the built jar from the build stage (artifact name from pom)
COPY --from=build /build/target/synapse-backend-0.0.1-SNAPSHOT.jar /app/app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","/app/app.jar"]
