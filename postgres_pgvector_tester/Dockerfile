ARG BUILD_FROM=alpine:latest
FROM $BUILD_FROM

ENV LANG=C.UTF-8

RUN apk add --no-cache python3 py3-pip gcc musl-dev postgresql-dev python3-dev

# Set up virtual environment
RUN python3 -m venv /venv
ENV PATH="/venv/bin:$PATH"

# Install packages inside the venv
RUN pip install psycopg[binary]

COPY tester.py /tester.py
CMD ["python3", "/tester.py"]