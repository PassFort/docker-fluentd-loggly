### Fluentd Loggly K8s

This repo contains the necessary setup to redirect logs from all pods to [Loggly](https://passfort.loggly.com). This setup adds a DaemonSet to kubernetes which sits on each machine, and tails the log files of each container. `fluentd` then parses and redirects the logs to loggly over `http`.

There is some complexity to this setup, that took some trial and error to get working:

### Loggly Tags
Loggly provides a way for segmenting logs based on tags. The way to add a tag is either by sending a header, or when posting via `http` appending `/tag/nginx` to the end of the URL. The `fluentd` `in_tail` plugin sets the log's "tag" as the filename, which isn't useful for our infrastructure. Therefore the loggly plugin in `./plugins/out_loggly.rb` is tailored to our own specific needs, and parses the filename with a regex to set the tag. This is pretty nasty, but doesn't seem to be possible with fluentd setup only.

### Jsonish Parsing
We have started to use structured logging in some of our services. When you log from a service it produces lines like:
```
{"log":"[2018-01-18 08:38:36 +0000] [29] [DEBUG] POST /4.0/profiles/3d2c1cc8-fae4-11e7-93eb-0a580a040321/checks\n","stream":"stderr","time":"2018-01-18T08:38:36.549639081Z"}
```
The `in_tail` `fluentd` plugin contains a JSON formatter which will parse the above line fine. But when we have a structured log, it only parses the top level, and not the stringified object that lives in `log`. Therefore the plugin in `./plugins/parser_jsonish.rb` will try and parse the `log`, but if it cannot will just send the parsed version of the logline above. If it can parse the inner `log`, then it will merge the parsed object with the above logline, while deleting the stringified key and value.

### Deployment
You can deploy this from the build server like most other services.
```
python deploy.py -bd staging
```
