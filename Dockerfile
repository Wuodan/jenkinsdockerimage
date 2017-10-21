FROM  jenkins/jenkins:lts
 
USER root

# create docker group and add jenkins user
RUN groupadd docker
RUN gpasswd -a jenkins docker
RUN newgrp docker

# pre-install docker-ce
RUN apt-get update
RUN apt-get install -y \
apt-transport-https \
ca-certificates \
curl \
gnupg2 \
software-properties-common
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
RUN add-apt-repository \
"deb [arch=amd64] https://download.docker.com/linux/debian \
$(lsb_release -cs) \
stable"
RUN apt-get update

# install docker-ce
RUN apt-get install -y docker-ce

# RUN usermod -aG docker jenkins
