# syntax=docker/dockerfile:1

# Tautulli on the shared Alpine base, rootless from the first process. Tautulli
# vendors its pure-Python dependencies in lib/; the only compiled requirement
# (cryptography) comes from upstream's own baseimage requirements file and is
# installed into a venv in a build stage so the runtime image has no toolchain.
# pip is removed from the venv after the install: nothing uses it at runtime and
# its vendored libraries (urllib3, msgpack, setuptools) only add scanner findings.
FROM ghcr.io/rake-pro/alpine-base:1.0@sha256:13603c44f47bc2163846b1959d16987bc4b85e2fd2fe07d4a0bc618755e8fedb AS build
ARG VERSION="2.19.1"
RUN apk add --no-cache curl python3 py3-pip \
    && python3 -m venv /opt/venv \
    && curl -fsSL -o /tmp/requirements.txt \
        "https://raw.githubusercontent.com/Tautulli/tautulli-baseimage/python3/requirements.txt" \
    && /opt/venv/bin/pip install --no-cache-dir --only-binary=:all: -r /tmp/requirements.txt \
    && rm -rf /opt/venv/bin/pip* /opt/venv/lib/python3*/site-packages/pip /opt/venv/lib/python3*/site-packages/pip-*.dist-info \
    && mkdir -p /out \
    && curl -fsSL -o /tmp/app.tgz "https://github.com/Tautulli/Tautulli/archive/refs/tags/v${VERSION}.tar.gz" \
    && tar -xzf /tmp/app.tgz -C /out --strip-components=1 \
    && printf 'v%s\n' "${VERSION}" > /out/version.txt \
    && printf 'master\n' > /out/branch.txt \
    && rm -rf /tmp/app.tgz /tmp/requirements.txt \
    && chmod -R u=rwX,go=rX /out /opt/venv

FROM ghcr.io/rake-pro/alpine-base:1.0@sha256:13603c44f47bc2163846b1959d16987bc4b85e2fd2fe07d4a0bc618755e8fedb
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
