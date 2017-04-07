FROM fluent/fluentd:v0.12.32

ENV TOKEN=""
ENV NODE_HOSTNAME=""
ENV LOGGLY_TAG=""

RUN gem install net-http-persistent -v 2.9.4

COPY plugins/ /fluentd/plugins

USER root
COPY fluent.conf /fluentd/etc/fluent.conf

# Run Fluentd
CMD exec fluentd -c /fluentd/etc/fluent.conf -p /fluentd/plugins
