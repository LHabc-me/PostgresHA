FROM postgres:16.4

ENV PG_MAJOR=16
ENV CITUS_VERSION=12.1.4
ENV LANG=C.UTF-8

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    vim \
    make \
    git \
    gcc \
    liblz4-dev \
    libzstd-dev \
    libkrb5-dev \
    libcurl4-openssl-dev \
    postgresql-server-dev-${PG_MAJOR} && \
    git clone https://github.com/citusdata/citus.git && \
    cd citus && \
    git checkout v${CITUS_VERSION} && \
    ci/build-citus.sh && \
    tar -xvf install-${PG_MAJOR}.tar -C / && \
    cd .. && \
    rm -rf citus && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

ENV POSTGRES_HA_ROOT=/postgres-ha
ENV POSTGRES_HA_SERVICE_DIR=${POSTGRES_HA_ROOT}/service
ENV POSTGRES_HA_DATA_DIR=${POSTGRES_HA_ROOT}/data
ENV POSTGRES_HA_LOG_DIR=${POSTGRES_HA_ROOT}/log
ENV POSTGRES_HA_SERVICE_PORT=54323

RUN apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv curl && \
    mkdir -p ${POSTGRES_HA_SERVICE_DIR} && \
    python3 -m venv ${POSTGRES_HA_SERVICE_DIR}/venv && \
    ${POSTGRES_HA_SERVICE_DIR}/venv/bin/pip install flask flask-cors psycopg2-binary

COPY ./app.py ${POSTGRES_HA_SERVICE_DIR}/app.py

HEALTHCHECK --interval=5s --timeout=5s --retries=3 \
CMD curl --fail http://localhost:${POSTGRES_HA_SERVICE_PORT}/ping || exit 1
    
CMD ["sh", "-c", "${POSTGRES_HA_SERVICE_DIR}/venv/bin/python ${POSTGRES_HA_SERVICE_DIR}/app.py"]