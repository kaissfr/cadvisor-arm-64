# Container Advisor for ARM64

cAdvisor provides container users an understanding of the resource usage and performance characteristics of their running containers. It is a running daemon that collects, aggregates, processes, and exports information about running containers. Specifically, for each container it keeps resource isolation parameters, historical resource usage, histograms of complete historical resource usage and network statistics. This data is exported by container and machine-wide.

cAdvisor has native support for Docker containers and should support just about any other container type out of the box. We strive for support across the board so feel free to open an issue if that is not the case. cAdvisor's container abstraction is based on lmctfy's so containers are inherently nested hierarchically.

## Running cAdvisor in a Docker Container

To quickly tryout cAdvisor on your machine with Docker, we have a Docker image that includes everything you need to get started. You can run a single cAdvisor to monitor the whole machine. Simply run:
```
    sudo docker run \
                --volume=/:/rootfs:ro \
                --volume=/var/run:/var/run:ro \
                --volume=/sys:/sys:ro \
                --volume=/var/lib/docker/:/var/lib/docker:ro \
                --volume=/dev/disk/:/dev/disk:ro \
                --publish=8080:8080 \
                --detach=true \
                --name=cadvisor \
                kaissfr/cadvisor:arm64
```

cAdvisor is now running (in the background) on http://localhost:8080. The setup includes directories with Docker state cAdvisor needs to observe.

## Exporting stats

cAdvisor supports exporting stats to various storage plugins. See the documentation for more details and examples.

### Web UI

cAdvisor exposes a web UI at its port:

http://<hostname>:<port>/

This UI has one primary resource at /containers which exports live information about all containers on the machine.

#### Web UI authentication

You can add authentication to the web UI by either HTTP basic or HTTP digest authentication.

##### HTTP basic authentication

You will need to add a http_auth_file parameter with a HTTP basic auth file generated using htpasswd to enable HTTP basic auth. By default the auth realm is set as localhost.

```
    ./cadvisor --http_auth_file test.htpasswd --http_auth_realm localhost
```

The test.htpasswd file provided has a username and password already added (admin:password1) for testing purposes.

```
    admin:$apr1$WVO0Bsre$VrmWGDbcBV1fdAkvgQwdk0
```

##### HTTP Digest authentication

You will need to add a http_digest_file parameter with a HTTP digest auth file generated using htdigest to enable HTTP Digest auth. By default the auth realm is set as localhost.

```
    ./cadvisor --http_digest_file test.htdigest --http_digest_realm localhost
```

The test.htdigest file provided has a username and password already added (admin:password1) for testing purposes.
```
    admin:localhost:70f2631dded4ce5ad0ebbea5faa6ad6e
```
    Note : You can use either type of authentication, in case you decide to use both files in the arguments only HTTP basic auth will be enabled.

### Remote REST API & Clients

cAdvisor exposes its raw and processed stats via a versioned remote REST API:
```
    http://<hostname>:<port>/api/<version>/<request>
```

This document covers the detail of version 2.0. All resources covered in this version are read-only.


#### Version information

Software version for cAdvisor can be obtained from version endpoint as follows: ``` /api/v2.0/version ```

#### Machine Information

The resource name for machine information is as follows: ```/api/v2.0/machine ```

The machine information is returned as a JSON object of the MachineInfo.

#### Attributes

Attributes endpoint provides hardware and software attributes of the running machine. The resource name for attributes is: ```/api/v2.0/attributes ```

Hardware information includes all information covered by machine endpoint. Software information include version of cAdvisor, kernel, docker, and underlying OS.

#### Container Stats

The resource name for container stats information is: ```/api/v2.0/stats/<container identifier>```

##### Stats request options

Stats support following options in the request:

- **type**: describes the type of identifier. Supported values are **name**(default) and **docker**. **name** implies that the identifier is an absolute container name. **docker** implies that the identifier is a docker id.
- **recursive**: Option to specify if stats for subcontainers of the requested containers should also be reported. Default is false.
- **count**: Number of stats samples to be reported. Default is 64.

##### Container name

When container identifier is of type **name**, the identifier is interpreted as the absolute container name. Naming follows the lmctfy convention. For example:

| Container Name | Resource Name |
| :-------------- | :------------- |
| /     	     | /api/v1.3/containers/ |
| /docker/3c5732e46e1b3980078bf6cf1e39d1cb4428420f050931a8ef87c088a0fbf5e1 | /api/v1.3/containers/docker/3c5732e46e1b3980078bf6cf1e39d1cb4428420f050931a8ef87c088a0fbf5e1 |

Note that the root container (/) contains usage for the entire machine. All Docker containers are listed under /docker. Also, type=name is not required in the examples above as name is the default type.

##### Docker Containers

When container identifier is of type docker, the identifier is interpreted as docker id. For example:

| Docker container | Resource Name |
| :--------------- | :------------ |
| All docker containers | /api/v2.0/stats?type=docker&recursive=true |
| minio | /api/v2.0/stats/minio?type=docker |
| 7c5fec2fcc4c | /api/v2.0/stats/7c5fec2fcc4c?type=docker |

The Docker name can be either the UUID or the short name of the container. It returns the information of the specified container(s).

Note that recursive is only valid when docker root is specified. It is used to get stats for all docker containers.

##### Returned stats

The stats information is returned as a JSON object containing a map from container name to list of stat objects. Stat object is the marshalled JSON of the ContainerStats.

##### Container Stats Summary

Instead of a list of periodically collected detailed samples, cAdvisor can also provide a summary of stats for a container. It provides the latest collected stats and percentiles (max, average, and 90%ile) values for usage in last minute and hour. (Usage summary for last day exists, but is not currently used.)

Unlike the regular stats API, only selected resources are captured by summary. Currently it is limited to cpu and memory usage.

The resource name for container summary information is: ```/api/v2.0/summary/<container identifier>```

Additionally, type and recursive options can be used to describe the identifier type and ask for summary of all subcontainers respectively. The semantics are same as described for container stats above.

The returned summary information is a JSON object containing a map from container name to list of summary objects. Summary object is the marshalled JSON of the DerivedStats.

##### Container Spec

The resource name for container stats information is: ```/api/v2.0/spec/<container identifier>```

Additionally, type and recursive options can be used to describe the identifier type and ask for spec of all subcontainers respectively. The semantics are same as described for container stats above.

The spec information is returned as a JSON object containing a map from container name to list of spec objects. Spec object is the marshalled JSON of the ContainerSpec.