ARG docker_from=osrf/ros:noetic-desktop-full
FROM $docker_from

## 전체적으로 명령어를 noninteractive하게 설정
ARG DEBIAN_FRONTEND=noninteractive

# catkin build 및 service build를 위한 환경변수
ENV ROS_DISTRO=noetic
ENV ROS_PATH=/opt/ros/${ROS_DISTRO}
ENV PKG_CONFIG_PATH=${ROS_PATH}/lib/pkgconfig

## 사용자 계정을 생성
# (일반적으로 docker에서 추천하지는 않음)
RUN adduser recipelab --disabled-password --gecos ""
RUN usermod -aG sudo recipelab
RUN usermod -aG dialout recipelab
RUN usermod -aG video recipelab
# passwd는 interactive 명령이므로 chpasswd를 사용
RUN echo root:1q2w3e | /usr/sbin/chpasswd
RUN echo recipelab:1q2w3e | /usr/sbin/chpasswd
# recipelab 사용자 계정이 sudo를 사용하므로 암호 입력 비활성화
# (docker build시에만 임시로 사용, 마지막에 재활성)
RUN sed -i -e "s#%sudo	ALL=(ALL:ALL) ALL#%sudo	ALL=(ALL:ALL) NOPASSWD:ALL#" /etc/sudoers

## recipelab catkin_ws를 위한 apt 패키지 설치
RUN rm -rf /etc/apt/sources.list.d/ros1*.list
RUN apt update
RUN apt install -y curl
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros1.list > /dev/null
RUN apt update
# systemd를 사용하기 위함
RUN apt install -y init systemd
RUN apt install -y iproute2 fonts-powerline can-utils
RUN apt install -y zsh git curl vim tmux htop
RUN apt install -y python3-catkin-tools python-is-python3
RUN apt install -y python3-jinja2
RUN apt install -y xfce4 xfce4-goodies
RUN apt install -y tigervnc-standalone-server
RUN apt install -y socat
# interactive한 명령을 noninteractive하게 변경하기 위함
RUN apt install -y expect
# ros-noetic-desktop-full 설치(arm64용)
RUN apt install -y ros-noetic-desktop-full

## recipelab 사용자 계정관련
RUN chsh -s `which zsh` recipelab
USER recipelab
WORKDIR /home/recipelab
# ohmyzsh 설치 및 설정
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
RUN sed -i -e "s#ZSH_THEME=\"robbyrussell\"#ZSH_THEME=\"agnoster\"#" .zshrc
RUN sed -i -e "s#\# zstyle ':omz:update' mode auto#zstyle ':omz:update' mode auto#" .zshrc
RUN echo "export USER=recipelab" >> .zshrc
# ros 관련 설정
RUN echo "alias sb='source ~/.zshrc'" >> .zshrc
RUN echo "alias cw='cd ~/catkin_ws'" >> .zshrc
RUN echo "alias cs='cd ~/catkin_ws/src'" >> .zshrc
RUN echo "alias cm='cd ~/catkin_ws && catkin build'" >> .zshrc
RUN echo "source /opt/ros/noetic/setup.zsh" >> .zshrc
RUN echo "source ~/catkin_ws/devel/setup.zsh" >> .zshrc
RUN echo "export ROS_MASTER_URI=http://localhost:11311" >> .zshrc
RUN echo "export ROS_HOSTNAME=localhost" >> .zshrc
# tmux 설정
RUN printf "set -g mouse on\nunbind t\nbind-key -T prefix t split-window -v \; split-window -h 'htop' \; select-pane -t 0 \; split-window -h \; select-pane -t 0 \;" > .tmux.conf

## catkin_ws 복사
# (COPY 명령어를 사용하여 복사할 경우 root 소유권으로 복사됨)
COPY catkin_ws /home/recipelab/catkin_ws
USER root
# root에서 recipelab로 소유권 변경
RUN chown -R recipelab:recipelab catkin_ws
USER recipelab
# catkin_ws 종속성 패키지 설치
WORKDIR /home/recipelab/catkin_ws
RUN rosdep update --include-eol-distros && rosdep install --from-paths src --ignore-src -r -y
## catkin_ws build
RUN catkin config --extend /opt/ros/noetic
RUN catkin build

## service 활성화
WORKDIR /home/recipelab/catkin_ws/src/setting/docker
RUN ./change_vncpasswd.sh
RUN cd /home/recipelab/catkin_ws/src/setting/novncd && make jinja2

USER root
## systemd 설정
WORKDIR /home/recipelab/catkin_ws/src/setting/docker
RUN ln -s /home/recipelab/catkin_ws/src/setting/novncd/systemd/novncd@recipelab.service /lib/systemd/system
# 기본 실행 타겟 변경
RUN cp ros.target /lib/systemd/system
WORKDIR /lib/systemd/system
RUN rm -rf default.target
RUN ln -s ros.target default.target

## vscode 설치
WORKDIR /home/recipelab
RUN echo "code code/add-microsoft-repo boolean true" | debconf-set-selections
RUN apt install -y wget gpg
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
RUN install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
RUN echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | tee /etc/apt/sources.list.d/vscode.list > /dev/null
RUN rm -f packages.microsoft.gpg
RUN apt update
RUN apt install -y apt-transport-https code

## 설치관련 임시설정 복귀
# sudo 사용시 암호 입력 활성화
RUN sed -i -e "s#%sudo	ALL=(ALL:ALL) NOPASSWD:ALL#%sudo	ALL=(ALL:ALL) ALL#" /etc/sudoers

## systemd 실행
CMD ["/usr/sbin/init"]