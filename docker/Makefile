ifndef ACCOUNT
	ACCOUNT=recipelab
endif
ifndef DISTRO
	DISTRO=ubuntu
endif
ifndef MACHINE
	MACHINE=amd64
endif
ifndef CGROUP_VER
	CGROUP_VER=v1
endif

SETTING_DIR=/home/$(ACCOUNT)/catkin_ws/src/setting

ifeq ($(DISTRO), ubuntu)
	DISTRO_CODENAME=$${UBUNTU_CODENAME:-$$VERSION_CODENAME}
else ifeq ($(DISTRO), debian)
	DISTRO_CODENAME=$${VERSION_CODENAME}
else
	exit 1
endif
ifeq ($(MACHINE), amd64)
	DOCKER_FROM=osrf/ros:noetic-desktop-full
else ifeq ($(MACHINE), rpi5)
	DOCKER_FROM=arm64v8/ros:noetic
else
	exit 1
endif
ifeq ($(CGROUP_VER), v1)
	CGROUPNS=
	CGROUPCMD=
else ifeq ($(CGROUP_VER), v2)
	CGROUPNS=--cgroupns=host
	CGROUPCMD=sudo cp $(SETTING_DIR)/docker/daemon.json /etc/docker
else
	exit 1
endif

PROGRESS_MESSAGE=install & reboot -> clone -> setup -> build -> create -> enable_service & reboot
confirm:
	@echo "ACCOUNT=$(ACCOUNT) DISTRO=$(DISTRO) MACHINE=$(MACHINE) CGROUP_VER=$(CGROUP_VER)"
	@read -p "Is Right?(yes/no/?): " INPUT; \
	if [ "$$INPUT" = "yes" ] || [ "$$INPUT" = "y" ]; then \
		:; \
	elif [ "$$INPUT" = "?" ]; then \
		echo "DISTRO=[ubuntu|debian] MACHINE=[amd64|rpi5] CGROUP_VER=[v1|v2]"; \
		echo "DISTRO=[lsb_release -a] MACHINE=[uname -a] CGROUP_VER=[grep cgroup /proc/filesystems]"; \
		echo "# progress: $(PROGRESS_MESSAGE)"; \
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
	sudo apt install -y build-essential
	# setup zsh
	sudo apt install -y fonts-powerline
	@if [ -d "/home/$(ACCOUNT)/.oh-my-zsh" ]; then \
		rm -rf /home/$(ACCOUNT)/.oh-my-zsh; \
	fi
	cd /home/$(ACCOUNT) \
	&& sh -c "$$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
	&& sed -i -e "s#ZSH_THEME=\"robbyrussell\"#ZSH_THEME=\"agnoster\"#" .zshrc \
	&& sed -i -e "s#\# zstyle ':omz:update' mode auto#zstyle ':omz:update' mode auto#" .zshrc \
	&& echo "alias sb='source ~/.zshrc'" >> .zshrc \
	&& echo "alias cw='cd ~/catkin_ws'" >> .zshrc \
	&& echo "alias cs='cd ~/catkin_ws/src'" >> .zshrc \
	&& echo "alias cssd='cd ~/catkin_ws/src/setting/docker'" >> .zshrc \
	&& echo "export ACCOUNT=$(ACCOUNT)" >> .zshrc \
	&& echo "export DISTRO=$(DISTRO)" >> .zshrc \
	&& echo "export MACHINE=$(MACHINE)" >> .zshrc \
	&& echo "export CGROUP_VER=$(CGROUP_VER)" >> .zshrc \
	&& sudo chsh -s `which zsh` $(ACCOUNT)
	# setup tmux
	cd /home/$(ACCOUNT) \
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
	sudo usermod -aG docker $(ACCOUNT)
	@echo "# progress: $(PROGRESS_MESSAGE)"

clone:
	cd /home/$(ACCOUNT) \
	&& git clone https://github.com/recipelab/catkin_ws_actuator.git --recursive \
	&& ln -s catkin_ws_actuator catkin_ws
	@echo "# progress: $(PROGRESS_MESSAGE)"

setup:
	@if [ "$$MACHINE" = "rpi5" ]; then \
		{ grep -q "net.ifnames=0" /boot/firmware/cmdline.txt && echo "already [net.ifnames=0]"; } || { sudo sed -i '$$ s/$$/ net.ifnames=0/' /boot/firmware/cmdline.txt && echo "success [net.ifnames=0]" || echo "fail [net.ifnames=0]"; } \
	fi
	sudo rm -rf /etc/udev/rules.d/99-ethercat.rules
	sudo ln -s $(SETTING_DIR)/99-ethercat.rules /etc/udev/rules.d/99-ethercat.rules
	sudo udevadm control --reload-rules && sudo udevadm trigger
	cd $(SETTING_DIR)/docker \
	&& curl -fsSL https://code-server.dev/install.sh | sh \
	&& mkdir -p ~/.config/code-server && cp config.yaml ~/.config/code-server && sudo systemctl enable --now code-server@$(ACCOUNT)
	@echo "# progress: $(PROGRESS_MESSAGE)"

build:
	$(CGROUPCMD)
	cd $(SETTING_DIR)/docker \
	&& docker build -f $(SETTING_DIR)/docker/Dockerfile -t recipelab/ros:noetic /home/$(ACCOUNT) --progress=plain --no-cache --build-arg docker_from=$(DOCKER_FROM)
	@echo "# progress: $(PROGRESS_MESSAGE)"

create:
	docker create --name ros1 --interactive --tty --network=host --privileged --volume=/dev:/dev $(CGROUPNS) --volume=/sys/fs/cgroup:/sys/fs/cgroup:rw recipelab/ros:noetic
	@echo "# progress: $(PROGRESS_MESSAGE)"

enable_service:
	@if [ "$$MACHINE" = "rpi5" ]; then \
		$(SETTING_DIR)/jinja2-cli/jinja2 $(SETTING_DIR)/docker/docker_ros1.service.tmpl -D exec_start_pre="/bin/sh -c 'nohup $(SETTING_DIR)/docker/fix-dm.sh > /dev/null 2>&1 &'" -o $(SETTING_DIR)/docker/docker_ros1.service; \
	else \
		$(SETTING_DIR)/jinja2-cli/jinja2 $(SETTING_DIR)/docker/docker_ros1.service.tmpl -o $(SETTING_DIR)/docker/docker_ros1.service; \
	fi
	sudo ln -sf $(SETTING_DIR)/docker/docker_ros1.service /etc/systemd/system
	sudo systemctl enable docker_ros1
	# sudo systemctl [enable|start|restart|stop|status|disable] docker_ros1
	@echo "# progress: $(PROGRESS_MESSAGE)"

run:
	docker run --detach --name ros1 --interactive --tty --network=host --privileged --volume=/dev:/dev $(CGROUPNS) --volume=/sys/fs/cgroup:/sys/fs/cgroup:rw recipelab/ros:noetic

exec:
	docker exec -it -u $(ACCOUNT) ros1 /bin/zsh

start:
	docker start ros1

stop:
	docker stop ros1

rm:
	docker rm ros1

prune:
	docker system prune -a