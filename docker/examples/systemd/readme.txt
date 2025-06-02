0. $ docker build -t ubuntu-systemd .

1. $ docker run -itd --privileged --name systemd -v /sys/fs/cgroup:/sys/fs/cgroup ubuntu-systemd
  가. dockerfile에서 CMD ["/usr/sbin/init"] 를 사용하지 않을 경우
    1) $ docker run -itd --privileged --name systemd -v /sys/fs/cgroup:/sys/fs/cgroup ubuntu-systemd /usr/sbin/init

2. $ docker exec -it systemd /bin/bash