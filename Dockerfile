FROM fluent/fluentd:latest

ENV TOKEN=""
ENV NODE_HOSTNAME=""
ENV LOGGLY_TAG=""

RUN gem install fluent-plugin-loggly
RUN gem install fluent-plugin-logdna

# Force back into root from fluentd's ubuntu
USER root
COPY fluent.conf /fluentd/etc/fluent.conf

# Run Fluentd
CMD exec fluentd -c /fluentd/etc/fluent.conf -p /fluentd/plugins
