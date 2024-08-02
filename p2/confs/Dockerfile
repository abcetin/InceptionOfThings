FROM debian:bookworm

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
    openssh-server \
    passwd \
    sudo \
    net-tools \ 
    curl \
    iptables-persistent \
    fuse-overlayfs \
    systemd systemd-sysv && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


RUN mkdir /var/run/sshd

RUN useradd --create-home -s /bin/bash vagrant
RUN echo "vagrant:vagrant" | chpasswd

RUN echo 'vagrant ALL=(ALL) NOPASSWD: ALL' | tee /etc/sudoers.d/vagrant
RUN chmod 440 /etc/sudoers.d/vagrant

RUN mkdir -p /home/vagrant/.ssh
RUN chmod 700 /home/vagrant/.ssh
ADD https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub /home/vagrant/.ssh/authorized_keys
RUN chmod 600 /home/vagrant/.ssh/authorized_keys
RUN chown -R vagrant:vagrant /home/vagrant/.ssh

RUN sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

EXPOSE 22
RUN echo "export PATH=$PATH:/usr/sbin" >> /etc/profile.d/env.sh
RUN echo "alias k=kubectl" >> /etc/profile.d/env.sh 
RUN bash /etc/profile.d/env.sh


COPY confs/app1.yaml /p2/app1.yaml
COPY confs/app2.yaml /p2/app2.yaml
COPY confs/app3.yaml /p2/app3.yaml
COPY confs/ingress.yaml /p2/ingress.yaml
# COPY scripts/initilaize.sh /
# RUN chmod 777 /initilaize.sh
# RUN bash /initilaize.sh
CMD ["/sbin/init"]
