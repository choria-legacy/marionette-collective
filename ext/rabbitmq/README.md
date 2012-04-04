Installing RabbitMQ
===================

Pre-requisies
-------------

Debian

    sudo apt-get install -y erlang-base erlang-nox

Software
--------

[Download from the official site](http://www.rabbitmq.com/download.html)


Adding Users for Mcollective
----------------------------
    rabbitmq-plugins enable amqp_client
    rabbitmq-plugins enable rabbitmq_stomp
    rabbitmqctl add_user mcollective *<PASSWORD>*
    rabbitmqctl set_user_tags mcollective administrator
    rabbitmqctl set_permissions -p / mcollective ".*" ".*" ".*"

restart RabbitMQ
