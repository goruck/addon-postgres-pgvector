ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

RUN apk add --no-cache \
    postgresql16 \
    postgresql16-contrib \
    postgresql16-dev \
    build-base \
    gnupg \
    git

RUN git clone --branch v0.7.0 https://github.com/pgvector/pgvector.git && \
    cd pgvector && \
    make && make install && \
    cd .. && rm -rf pgvector

COPY run.sh /run.sh
COPY init.sql.j2 /init.sql.j2
COPY postgresql.conf /etc/postgresql/postgresql.conf
COPY pg_hba.conf /etc/postgresql/pg_hba.conf
RUN chmod +x /run.sh

CMD [ "/run.sh" ]
