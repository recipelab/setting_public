USERNAME=recipelab
GIT_USERNAME=$(USERNAME)
GIT_EMAIL=recipelab17@gmail.com
DISTRO=ubuntu
ARCH=amd64
CGROUP_VER=V1
ifeq ($(DISTRO), ubuntu)
	DISTRO_CODENAME=$${UBUNTU_CODENAME:-$$VERSION_CODENAME}
else ifeq ($(DISTRO), debian)
	DISTRO_CODENAME=$${VERSION_CODENAME}
else
	exit 1
endif
ifeq ($(ARCH), amd64)
	DOCKER_FROM=osrf/ros:noetic-desktop-full
else ifeq ($(ARCH), arm64)
	DOCKER_FROM=arm64v8/ros:noetic
else
	exit 1
endif
ifeq ($(CGROUP_VER), V1)
	CGROUPNS=
	CGROUPCMD=
else ifeq ($(CGROUP_VER), V2)
	CGROUPNS=--cgroupns=host
	CGROUPCMD=sudo cp /home/$(USERNAME)/catkin_ws/src/setting/docker/daemon.json /etc/docker
else
	exit 1
endif

confirm:
	@echo "USER=$(USERNAME), EMAIL=$(GIT_EMAIL), DISTRO=$(DISTRO), ARCH=$(ARCH), CGROUP_VER=$(CGROUP_VER)"
	@read -p "Is Right?(yes/no/?): " INPUT; \
	if [ "$$INPUT" = "yes" ] || [ "$$INPUT" = "y" ]; then \
		:; \
	elif [ "$$INPUT" = "?" ]; then \
		echo "install & reboot -> clone -> setup -> build -> enable_service & reboot"; \
		exit 1; \
	else \
		exit 1; \
	fi

install: confirm
	sudo systemctl disable --now apt-daily.timer
	sudo systemctl disable --now apt-daily.service
	sudo systemctl disable --now apt-daily-upgrade.timer
	sudo systemctl disable --now apt-daily-upgrade.service
	sudo apt update
	sudo apt install -y curl vim ssh htop
	sudo apt install -y zsh tmux git
	# setup zsh
	sudo apt install -y fonts-powerline
	@if [ -d "/home/$(USERNAME)/.oh-my-zsh" ]; then \
		rm -rf /home/$(USERNAME)/.oh-my-zsh; \
	fi
	cd /home/$(USERNAME) \
	&& sh -c "$$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
	&& sed -i -e "s#ZSH_THEME=\"robbyrussell\"#ZSH_THEME=\"agnoster\"#" .zshrc \
	&& sed -i -e "s#\# zstyle ':omz:update' mode auto#zstyle ':omz:update' mode auto#" .zshrc \
	&& echo "alias sb='source ~/.zshrc'" >> .zshrc \
	&& echo "alias cw='cd ~/catkin_ws'" >> .zshrc \
	&& echo "alias cs='cd ~/catkin_ws/src'" >> .zshrc \
	&& echo "alias cssd='cd ~/catkin_ws/src/setting/docker'" >> .zshrc \
	&& sudo chsh -s `which zsh` $(USERNAME)
	# setup tmux
	cd /home/$(USERNAME) \
	&& echo "set -g mouse on\nunbind t\nbind-key -T prefix t split-window -v \; split-window -h 'htop' \; select-pane -t 0 \; split-window -h \; select-pane -t 0 \;" > .tmux.conf
	# setup docker
	sudo apt install -y ca-certificates curl
	sudo install -m 0755 -d /etc/apt/keyrings
	sudo curl -fsSL https://download.docker.com/linux/$(DISTRO)/gpg -o /etc/apt/keyrings/docker.asc
	sudo chmod a+r /etc/apt/keyrings/docker.asc
	echo \
	"deb [arch=$$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$(DISTRO) \
	$$(. /etc/os-release && echo "$(DISTRO_CODENAME)") stable" | \
	sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	sudo apt update
	sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
	sudo usermod -aG docker $(USERNAME)
	# setup git
	cd /home/$(USERNAME) \
	&& git config --global user.name "$(USERNAME)" \
	&& git config --global user.email "$(GIT_EMAIL)"
	# setup github
	cd /home/$(USERNAME) \
	&& (type -p wget >/dev/null || (sudo apt update && sudo apt install -y wget)) && sudo mkdir -p -m 755 /etc/apt/keyrings && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && echo "deb [arch=$$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null && sudo apt update && sudo apt install -y gh \
	&& gh auth login

clone:
	cd /home/$(USERNAME) \
	&& git clone https://github.com/recipelab/amr.git --recursive --branch pallete_rev1 catkin_ws_pallete_rev1 \
	&& ln -s catkin_ws_pallete_rev1 catkin_ws

setup:
	sudo apt update
	sudo apt install -y build-essential
	cd /home/$(USERNAME)/catkin_ws/src/setting/setup \
	&& ./setup_udev.sh socketcan
	cd /home/$(USERNAME)/catkin_ws/src/setting/ngrok \
	&& ./ngrok.sh remove && ./ngrok.sh install
	cd /home/$(USERNAME)/catkin_ws/src/setting/docker \
	&& curl -fsSL https://code-server.dev/install.sh | sh \
	&& mkdir -p ~/.config/code-server && cp config.yaml ~/.config/code-server && sudo systemctl enable --now code-server@$(USERNAME)

build: confirm
	$(CGROUPCMD)
	cd /home/$(USERNAME)/catkin_ws/src/setting/docker \
	&& docker build -f /home/$(USERNAME)/catkin_ws/src/setting/docker/Dockerfile -t recipelab/ros:noetic /home/$(USERNAME) --progress=plain --no-cache --build-arg docker_from=$(DOCKER_FROM)

create: confirm
	docker create --name ros1 --interactive --tty --network=host --privileged --volume=/dev:/dev $(CGROUPNS) --volume=/sys/fs/cgroup:/sys/fs/cgroup:rw recipelab/ros:noetic

run: confirm
	docker run --detach --name ros1 --interactive --tty --network=host --privileged --volume=/dev:/dev $(CGROUPNS) --volume=/sys/fs/cgroup:/sys/fs/cgroup:rw recipelab/ros:noetic

exec:
	docker exec -it -u $(USERNAME) ros1 /bin/zsh

start:
	docker start ros1

stop:
	docker stop ros1

rm:
	docker rm ros1

prune:
	docker system prune -a

enable_service:
	sudo ln -sf /home/$(USERNAME)/catkin_ws/src/setting/docker/docker_ros1.service /etc/systemd/system
	sudo systemctl enable docker_ros1
	# sudo systemctl [enable|start|restart|stop|status|disable] docker_ros1