@ECHO OFF

set TAG=latest
set GIT_REPO_NAME=irisdemo-base-spark-iris
set IMAGE_NAME=intersystemsdc/%GIT_REPO_NAME%:%TAG%

docker build -t %IMAGE_NAME% .