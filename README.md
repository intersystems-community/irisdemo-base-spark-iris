This Spark image brings everything we need to:
- Connect directly to IRIS using JDBC
- Connect to IRIS using IRIS Spark Connector

This image is meant to be used on a docker-compose with IRIS. Preferably with a Zeppelin notebook.

It has IRIS JDBC driver and Spark Connector. 

This repo contains an example of a docker-compose.yml file that you can copy and paste on any folder on your PC and just run it with:

```bash
docker-compose up
```

After you start this composition, you will find IRIS, Zeppelin and the Spark portals on the following URLs:
* IRIS: http://localhost:52773/csp/sys/UtilHome.csp
  - The first time you try to log in, use the user SuperUser with the "SYS" password. 
    You will be asked to enter with a new password. Enter with "sys" (unless you want to change your docker-compose.yml to use another password)
* Zeppelin: http://localhost:9090/
  - It is already configured to talk to IRIS using JDBC and the Spark Connector
* Spark Cluster: http://localhost:8080
  - It is already configured to talk to IRIS using JDBC and the Spark Connector