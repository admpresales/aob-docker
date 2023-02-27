Supported through nimbusapp: https://github.com/admpresales/nimbusapp

Requires Docker Compose: https://docs.docker.com/compose/install/#install-compose

Requires Docker App 0.6.0: https://github.com/docker/app#installation

***
#### Latest Tags ####
``` <tag>```
***
#### Basic Commands for nimbusapp

| Description               | Command |
|---------------------------| ------------- |
| Bring containers up       | ```nimbusapp aob:$TAG up``` |
| Stop existing containers  | ```nimbusapp aob:$TAG stop``` |
| Start existing containers | ```nimbusapp aob:$TAG start``` |
| Terminate containers      | ```nimbusapp aob:$TAG down``` |
|  Inspect configuration    | ```nimbusapp aob:$TAG inspect``` |
 
For a list of raw Docker App commands, please see the bottom of the document.

***

#### Networking Prerequisite
AOB requires a network which can be built with the following command, which is preconfigured on the NimbusServer VM

```docker network create --subnet 172.50.0.0/16 --gateway 172.50.0.1 demo-net ```

***
#### Container Usage
URL: ``` http://nimbusserver.aos.com:8280 ```

Username: ```admin```

Password: ```demo```

***
#### Adjusting Parameters at Run Time
If you need to change one of these parameters you can add that change to the docker-app command using the -s or --set option as in:

``` nimbusapp aob:$TAG -s MAIN_PORT=8280 up ```


***
#### Raw Docker App commands:

| Description               | Command |
|---------------------------| ------------- |
| Bring containers up       | ``` docker-app render admpresales/aob.dockerapp:$TAG \| docker-compose -p aob -f - up -d ``` | 
| Stop existing containers  | ``` docker-app render admpresales/aob.dockerapp:$TAG \| docker-compose -p aob -f - stop ```  |
| Start existing containers | ``` docker-app render admpresales/aob.dockerapp:$TAG \| docker-compose -p aob -f - start ``` |
| Terminate containers      | ``` docker-app render admpresales/aob.dockerapp:$TAG \| docker-compose -p aob -f - down ``` |
|  Inspect Configuration    | ``` docker-app inspect admpresales/aob.dockerapp:$TAG ``` |