#!/bin/bash
set -e

# SETUP_DOCKER_GID_DEBUG=1

setup_docker_GID(){
	local WARN=0
	if [[ ! -S /var/run/docker.sock ]]; then
		WARN=1
		>&2 echo "WARNING: /var/run/docker.sock is not bound from host"
	else
		local SOCK_GID="$(ls -aln /var/run/docker.sock | awk '{print $4}')" 
		if [[ "${SOCK_GID}" == 0 ]] || [[ "${SOCK_GID}" == '' ]]; then
			WARN=1
			>&2 echo "WARNING: /var/run/docker.sock runs with root group"
		fi
		if [[ "${WARN}" == 1 ]]; then
			>&2 echo " ==> Jenkins will not be able to run Docker"
			return
		fi

		# check if GID does not exist
		if ! grep -Eq "^[^:]+:[^:]*:${SOCK_GID}:.*$" /etc/group; then
			echo "setting docker group GID to ${SOCK_GID}"
			groupmod -g "${SOCK_GID}" docker
		else
			# check if jenkins user is in that group
			if [[ " $(id -G jenkins) " =~ .*\ ${SOCK_GID}\ .* ]]; then
				echo "jenkins is in group $(getent group "${SOCK_GID}" | cut -d: -f1), nothing to do"
				return
			fi
			# group exists ...have to add jenkins to a random group
			>&2 echo "WARNING: added jenkins user to existing group $(getent group "${SOCK_GID}" | cut -d: -f1)."
			>&2 echo "         ==> Consider changing the GID of your docker group (to $(getent group docker | cut -d: -f3) or a higher value)"
			gpasswd -a jenkins "$(getent group "${SOCK_GID}" | cut -d: -f1)"
		fi
	fi
}

if [[ ! -z "${SETUP_DOCKER_GID_DEBUG}" ]]; then
	setup_docker_GID
	# try to run docker as jenkins
	exec su jenkins -c "/bin/tini -s -- docker run hello-world"
else
	setup_docker_GID > /dev/null
fi


# docker volume is initialized as last user in Dockerfile, which is root
# thus we change that to jenkins
chown -R jenkins:jenkins /var/jenkins_home

exec su jenkins -c "/bin/tini -s -- /usr/local/bin/jenkins.sh"
