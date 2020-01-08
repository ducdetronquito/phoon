FROM debian:bullseye-slim

RUN \
    apt-get update \
    && apt install apache2-utils curl nim -y

COPY ./benchmark/ /home/src/benchmark
COPY ./src/ ./home/src/benchmark/phoon/src/

RUN \
    curl https://storage.googleapis.com/hey-release/hey_linux_amd64 \
    && mv hey_linux_amd64 hey

WORKDIR /home/src/benchmark
