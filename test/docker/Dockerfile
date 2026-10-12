ARG DISTRO=resolute

FROM ubuntu:$DISTRO

RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
        git \
        make \
        python3

COPY [".", "/src"]
WORKDIR /src
CMD ["make", "test"]
