This Spark image brings everything we need to:
- Connect directly to IRIS using JDBC
- Connect to IRIS using IRIS Spark Connector

This image is meant to be used on a docker-compose with IRIS. Preferably with a Zeppelin notebook.

It has IRIS JDBC driver and Spark Connector. 

This repo contains an example of a docker-compose.yml file that you can copy and paste on any folder on your PC and just run it with:

```bash
docker-compose up
```

After you start this composition, you will find the Spark Cluster at http://localhost:8080.

Please, refer to the [Readmission Demo](https://github.com/intersystems-community/irisdemo-demo-readmission) for an example of using this image.