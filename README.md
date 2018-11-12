# cellery

Cellery is an architectural description language, runtime (tooling and extensions for popular cloud-native runtimes) that enables agile development teams to easily create a composite application (cell) in a technology neutral way. 

## Developer Guide

#### Cellery API Server

This is the RESTful API server for Cellery. This will be used by the CLI as well as any other client (UI, etc) which will interact with Cellery.

Start the API server using following command

```
$ ballerina run api-serser/api.bal
```

#### Cellery CLI

This is the Cellery CLI which can be used to interact with Cellery API Server to design, develop, build, run and manage your cells.

###### Build CLI using following command

```
$ bash build.sh
```
###### Link Cellery CLI locally

```
sudo mv cellery /usr/local/bin/
```
###### Run cellery commands

```
cellery [COMMAND]
```

