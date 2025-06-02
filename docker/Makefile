USER=recipelab
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
	CGROUPCMD=sudo cp /home/$(USER)/catkin_ws/src/setting_public/docker/daemon.json /etc/docker
else
	exit 1
endif

confirm:
	@echo "USER=$(USER), DISTRO=$(DISTRO), ARCH=$(ARCH), CGROUP_VER=$(CGROUP_VER)"
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
	@if [ -d "/home/$(USER)/.oh-my-zsh" ]; then \
		rm -rf /home/$(USER)/.oh-my-zsh; \
	fi
	cd /home/$(USER) \
	&& sh -c "$$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
	&& sed -i -e "s#ZSH_THEME=\"robbyrussell\"#ZSH_THEME=\"agnoster\"#" .zshrc \
	&& sed -i -e "s#\# zstyle ':omz:update' mode auto#zstyle ':omz:update' mode auto#" .zshrc \
	&& echo "alias sb='source ~/.zshrc'" >> .zshrc \
	&& echo "alias cw='cd ~/catkin_ws'" >> .zshrc \
	&& echo "alias cs='cd ~/catkin_ws/src'" >> .zshrc \
	&& echo "alias cssd='cd ~/catkin_ws/src/setting_public/docker'" >> .zshrc \
	&& sudo chsh -s `which zsh` $(USER)
	# setup tmux
	cd /home/$(USER) \
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
	sudo usermod -aG docker $(USER)

clone:
	cd /home/$(USER) \
	&& git clone https://github.com/recipelab/catkin_ws_actuator.git --recursive \
	&& ln -s catkin_ws_actuator catkin_ws

setup:
	sudo apt update
	sudo apt install -y build-essential
	cd /home/$(USER)/catkin_ws/src/setting_public/docker \
	&& curl -fsSL https://code-server.dev/install.sh | sh \
	&& mkdir -p ~/.config/code-server && cp config.yaml ~/.config/code-server && sudo systemctl enable --now code-server@$(USER)

build: confirm
	$(CGROUPCMD)
	cd /home/$(USER)/catkin_ws/src/setting_public/docker \
	&& docker build -f /home/$(USER)/catkin_ws/src/setting_public/docker/Dockerfile -t recipelab/ros:noetic /home/$(USER) --progress=plain --no-cache --build-arg docker_from=$(DOCKER_FROM)

create: confirm
	docker create --name ros1 --interactive --tty --network=host --privileged --volume=/dev:/dev $(CGROUPNS) --volume=/sys/fs/cgroup:/sys/fs/cgroup:rw recipelab/ros:noetic

run: confirm
	docker run --detach --name ros1 --interactive --tty --network=host --privileged --volume=/dev:/dev $(CGROUPNS) --volume=/sys/fs/cgroup:/sys/fs/cgroup:rw recipelab/ros:noetic

exec:
	docker exec -it -u $(USER) ros1 /bin/zsh

start:
	docker start ros1

stop:
	docker stop ros1

rm:
	docker rm ros1

prune:
	docker system prune -a

enable_service:
	sudo ln -sf /home/$(USER)/catkin_ws/src/setting_public/docker/docker_ros1.service /etc/systemd/system
	sudo systemctl enable docker_ros1
	# sudo systemctl [enable|start|restart|stop|status|disable] docker_ros1