### docker-python-selenium

Docker python base image with selenium chrome and firefox

```bash
# build in x86
docker build . --platform linux/amd64 -t docker-python-selenium:latest
# tag image
docker tag docker-python-selenium:latest rarce/docker-python-selenium:20220915
# push image to docker hub
docker push rarce/docker-python-selenium:20220915
```