#!/bin/bash
DEBUG=''

if [ -n "$1" ] && [ $1 == 'debug' ]; then
  DEBUG='-debug'
fi

echo Building test container image
docker build -t selenium/test:local ./Test

echo Starting Selenium Container
HUB=$(docker run -d selenium/hub:2.45.0)
HUB_NAME=$(docker inspect -f '{{ .Name  }}' $HUB | sed s:/::)
sleep 2

NODE_CHROME=$(docker run -d --link $HUB_NAME:hub  selenium/node-chrome$DEBUG:2.45.0)
NODE_FIREFOX=$(docker run -d --link $HUB_NAME:hub selenium/node-firefox$DEBUG:2.45.0)
NODE_HTMLUNIT=$(docker run -d --link $HUB_NAME:hub selenium/node-htmlunit$DEBUG:2.45.0)

docker logs -f $HUB &
docker logs -f $NODE_CHROME &
docker logs -f $NODE_FIREFOX &
docker logs -f $NODE_HTMLUNIT &
sleep 2

echo Running test container...
docker run --rm -it --link $HUB_NAME:hub selenium/test:local
STATUS=$?

echo Tearing down Selenium HtmlUnit Node container
docker stop $NODE_HTMLUNIT
docker rm $NODE_HTMLUNIT

echo Tearing down Selenium Chrome Node container
docker stop $NODE_CHROME
docker rm $NODE_CHROME

echo Tearing down Selenium Firefox Node container
docker stop $NODE_FIREFOX
docker rm $NODE_FIREFOX

echo Tearing down Selenium Hub container
docker stop $HUB
docker rm $HUB

if [ ! $STATUS == 0 ]; then
  echo Failed
  exit 1
fi

echo Done
