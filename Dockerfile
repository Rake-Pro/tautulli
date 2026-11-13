# syntax=docker/dockerfile:1

# Tautulli on the shared Alpine base, rootless from the first process. Tautulli
# vendors its pure-Python dependencies in lib/; the only compiled requirement
# (cryptography) comes from upstream's own baseimage requirements file and is
# installed into a venv in a build stage so the runtime image has no toolchain.
FROM ghcr.io/rake-pro/alpine-base:1.0@sha256:dc3ee9f773b64708750783e81c9f9a0071194f56e40cd2d3f3e6fa139ec1dc46 AS build
ARG VERSION="2.19.1"
RUN apk add --no-cache curl python3 py3-pip \
    && python3 -m venv /opt/venv \
    && curl -fsSL -o /tmp/requirements.txt \
        "https://raw.githubusercontent.com/Tautulli/tautulli-baseimage/python3/requirements.txt" \
    && /opt/venv/bin/pip install --no-cache-dir --only-binary=:all: -r /tmp/requirements.txt \
    && mkdir -p /out \
    && curl -fsSL -o /tmp/app.tgz "https://github.com/Tautulli/Tautulli/archive/refs/tags/v${VERSION}.tar.gz" \
    && tar -xzf /tmp/app.tgz -C /out --strip-components=1 \
    && printf 'v%s\n' "${VERSION}" > /out/version.txt \
    && printf 'master\n' > /out/branch.txt \
    && rm -rf /tmp/app.tgz /tmp/requirements.txt \
    && chmod -R u=rwX,go=rX /out /opt/venv

FROM ghcr.io/rake-pro/alpine-base:1.0@sha256:dc3ee9f773b64708750783e81c9f9a0071194f56e40cd2d3f3e6fa139ec1dc46
ARG VERSION
LABEL org.opencontainers.image.source="https://github.com/Rake-Pro/tautulli" \
      org.opencontainers.image.version="${VERSION}"

ENV HOME="/config" \
    TAUTULLI_DOCKER="True" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN apk add --no-cache python3

COPY --from=build /opt/venv /opt/venv
COPY --from=build /out /app
COPY --chmod=0755 entrypoint.sh /entrypoint.sh

USER 65534:65534
WORKDIR /config
VOLUME ["/config"]
EXPOSE 8181

ENTRYPOINT ["/usr/bin/catatonit", "--", "/entrypoint.sh"]
