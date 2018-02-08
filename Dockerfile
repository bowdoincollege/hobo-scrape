# CasperJs
# http://casperjs.org/
#
# Usage
#  exec mode
#    docker run --rm vitr/casperjs casperjs --version
#    docker run --rm vitr/casperjs phantomjs --version
#
#  daemon mode
#    docker run -d --name casperjs-daemon -v /home/ubuntu/test:/mnt/test --restart always vitr/casperjs

FROM vitr/casperjs
MAINTAINER Stephen Houser

RUN apt-get update && apt-get install curl -y

COPY entrypoint.sh .
COPY hobo-scrape.js .

VOLUME /data

ENTRYPOINT ["./entrypoint.sh"]
