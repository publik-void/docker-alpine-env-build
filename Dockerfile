FROM alpine:3.11.5
EXPOSE 22
RUN apk update && \
  apk add man-pages mdocml less-doc tar-doc && \
  apk add openssh openssh-doc && \
  apk add curl curl-doc && \
  apk add git git-doc && \
  apk add python3 python3-doc && \
  apk add perl perl-doc && \
  apk add mosh mosh-doc && \
  apk add fish fish-doc fish-tools && \
  apk add tmux tmux-doc && \
  apk add neovim neovim-doc && \
  apk add botan botan-doc && \
  apk add parallel parallel-doc && \
  apk add libressl libressl-doc && \
  apk add lz4 lz4-doc && \
  echo "root:root" | chpasswd && \
  rm /etc/motd && touch /etc/motd && \
  mkdir /root/.ssh && chmod 700 /root/.ssh && \
  ssh-keygen -A && \
  mkdir /root/.parallel && touch /root/.parallel/will-cite && \
  curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim && \
  mkdir -p /root/.config && \
  git clone https://github.com/publik-void/config-fish.git \
  /root/.config/fish && \
  git clone https://github.com/publik-void/config-nvim.git \
  /root/.config/nvim && \
  git clone https://github.com/publik-void/config-tmux.git \
  /root/.config/tmux && \
  ln -s /root/.config/tmux/tmux.conf /root/.tmux.conf && \
  fish -c fish_update_completions
COPY authorized_keys /root/.ssh/
WORKDIR /root
ENTRYPOINT /usr/sbin/sshd;/usr/bin/fish

