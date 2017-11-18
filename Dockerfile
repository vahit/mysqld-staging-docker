FROM mariadb:10.3
MAINTAINER vahit<vahid.maani@gmail.com>

COPY ./bin/ /root

ENTRYPOINT ["bash", "/root/entrypoint.sh"]
CMD ["echo"]
