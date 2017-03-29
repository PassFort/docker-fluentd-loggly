from passfort_deployment import run_command, deploy_file, use_cluster, \
    git_tree_hash, validate_deploy, init, project_uri

import logging
import argparse


required_secrets = ["logglytoken"]
container = "fluentd-loggly"


def get_container_uri(container, container_tag):
    return "{}/passfort-{}:{}".format(project_uri, container, container_tag)


def build_container(container, container_tag):
    container_uri = get_container_uri(container, container_tag)
    logging.info("Building " + container_uri)
    run_command(["docker", "build", "-t", container_uri, "-f", "Dockerfile", "."], stdout=True)
    run_command(["gcloud", "docker", "--", "push", container_uri], stdout=True)
    logging.info("Build completed")


def deploy_daemonset(cluster, container, container_tag):
    container_uri = get_container_uri(container, container_tag)
    deploy_file(
        "fluentd-loggly-daemonset-{}.yaml",
        container_uri,
        container_uri=container_uri,
    )

    # Delete the fluentd pods, so the updated daemonset can recreate them
    run_command(["kubectl", "delete", "pods", "-l", "app=fluentd"])


def main(cluster, build, deploy, tag):
    use_cluster(cluster)

    if tag:
        if build:
            logging.error("Cannot specify a custom tag when building!")
            exit(1)
        container_tag = tag
    else:
        # Calculate the tree hash to use as the container name
        container_tag = git_tree_hash()
        # Sanity check
        # validate_deploy(cluster, container_tag, required_secrets)

    if build:
        build_container(container, container_tag)
    if deploy:
        deploy_daemonset(cluster, container, container_tag)

if __name__ == '__main__':
    init(__file__, 1.0)

    # Parse args
    parser = argparse.ArgumentParser()
    parser.add_argument("cluster", help="staging or production")
    parser.add_argument("-b", "--build", action="store_true")
    parser.add_argument("-d", "--deploy", action="store_true")
    parser.add_argument("--tag", type=str)
    args = parser.parse_args()

    # Run!
    main(**args.__dict__)
