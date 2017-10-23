FROM jenkins/jenkins:lts
 
USER root

# pre-install docker-ce
RUN apt-get update && \
	apt-get install -y \
		apt-transport-https \
		ca-certificates \
		curl \
		gnupg2 \
		software-properties-common
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && \
	add-apt-repository \
		"deb [arch=amd64] https://download.docker.com/linux/debian \
		$(lsb_release -cs) \
		stable" && \
	apt-get update

# install docker-ce
RUN apt-get install -y docker-ce

# install setup script
COPY setup_docker_GID.sh /

# add jenkins user to docker group (it exists by now)
RUN gpasswd -a jenkins docker && \
# clean up
	apt-get clean && \
	rm -rf /var/lib/apt/lists/* && \
# make setup script executable
	chmod g+x /setup_docker_GID.sh

# stay user root, the setup script will start jenkins as jenkins user

ENTRYPOINT ["/setup_docker_GID.sh"]
