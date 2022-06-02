# alpine-vnc - A basic, graphical alpine workstation
# includes xfce, vnc, ssh
# last update: May/29/2022

FROM alpine:3.16

# init ash file (for non-login shells)
ENV ENV '$HOME/.ashrc'

# default screen size
ENV XRES 1280x800x24

# default tzdata settings
ENV TZ Etc/UTC

# update and install system software
RUN apk update && apk upgrade \
&& apk add  --no-cache sudo supervisor openssh-server openssh nano tzdata \
&& apk add --no-cache xvfb x11vnc \
&& apk add --no-cache xfce4 xfce4-terminal xfce4-xkb-plugin mousepad adwaita-icon-theme \
&& apk add --no-cache  chromium --repository=http://dl-cdn.alpinelinux.org/alpine/v3.16/main

# add main user
RUN adduser -D alpine

# change passwords and permissions
RUN 	echo "root:alpine" | /usr/sbin/chpasswd \
    && 	echo "alpine:alpine" | /usr/sbin/chpasswd \
    && 	echo "alpine ALL=(ALL) ALL" >> /etc/sudoers 	

# setup sshd
RUN 	mkdir /run/sshd \
	&& 	ssh-keygen -A

# add my sys config files
ADD etc /etc

# customizations
RUN 	echo "alias ll='ls -l'" > /home/alpine/.ashrc \
	&& 	echo "alias lla='ls -al'" >> /home/alpine/.ashrc \
	&& 	echo "alias llh='ls -hl'" >> /home/alpine/.ashrc \
	&& 	echo "alias hh=history" >> /home/alpine/.ashrc \
	#
	# ash personal config file for login shell mode
	&& cp /home/alpine/.ashrc /home/alpine/.profile 

# personal xfce4 config
ADD config/xfce4/terminal/terminalrc /home/alpine/.config/xfce4/terminal/terminalrc
ADD config/xfce4/terminal/Ubunty.theme /home/alpine/.local/share/xfce4/terminal/colorschemes/Ubunty.theme

# set custom wallpaper
ADD config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml  \
	/home/alpine/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml

# RUN chown -R alpine:alpine /home/alpine/.config /home/alpine/.xscreensaver
RUN chown -R alpine:alpine /home/alpine/

# exposed ports
EXPOSE 22 5900

# RUN echo "CHROMIUM_FLAGS='--no-sandbox --disable-gpu --user-data-dir --window-size=${VNC_RESOLUTION%x*},${VNC_RESOLUTION#*x} --window-position=0,0'" > ${HOME}/.chromium-browser.init
RUN echo "CHROMIUM_FLAGS='--no-sandbox --disable-gpu --user-data-dir --window-position=0,0'" > ${HOME}/.chromium-browser.init
RUN sed -i -e 's@Exec=/usr/bin/chromium-browser@Exec=/usr/bin/chromium-browser --no-sandbox --disable-dev-shm-usage@g' /usr/share/applications/chromium.desktop 
RUN sed -i -e 's@Exec=exo-open --launch WebBrowser %u@Exec=/usr/bin/chromium-browser --no-sandbox --disable-dev-shm-usage@g' /usr/share/applications/xfce4-web-browser.desktop

# default command
CMD ["/usr/bin/supervisord","-c","/etc/supervisord.conf"]

