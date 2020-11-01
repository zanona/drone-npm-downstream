FROM alpine/git
RUN apk -Uuv add jq npm
ADD downstream.sh /bin/
RUN chmod +x /bin/downstream.sh
ENTRYPOINT /bin/downstream.sh
