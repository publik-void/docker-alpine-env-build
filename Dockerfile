FROM alpine:3.15.0
EXPOSE 22
# Remember: Comments in Dockerfile need `#` at the *beginning* of the line
RUN apk update && \
  # -> General environment setup
  apk add mandoc man-pages mandoc-apropos less-doc tar-doc wget-doc && \
  apk add tzdata tzdata-doc && \
  apk add openssh openssh-doc && \
  # TODO: `mosh` currently supports full coloring only when building from source
  apk add mosh mosh-doc && \
  apk add curl curl-doc && \
  apk add git git-doc && \
  apk add fish fish-doc fish-tools && \
  apk add tmux tmux-doc && \
  # `ncurses` is needed for coloring in terminals like `screen*` and `tmux*`
  apk add ncurses ncurses-doc && \
  apk add neovim neovim-doc && \
  apk add ranger ranger-doc && \
  apk add botan botan-doc && \
  apk add parallel parallel-doc && \
  apk add libressl libressl-doc && \
  #apk add openssl openssl-doc && \
  apk add xz xz-doc && \
  apk add lz4 lz4-doc && \
  echo "root:root" | chpasswd && \
  ln -s /usr/share/zoneinfo/CET /etc/localtime && \
  rm /etc/motd && \
  mkdir /root/.ssh && chmod 700 /root/.ssh && \
  # TODO: `ssh-keygen -A` creates host keys in `/etc/ssh` – do I need that?
  ssh-keygen -A && \
  sed -i 's/\/bin\/ash/\/usr\/bin\/fish/g' /etc/passwd && \
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
  git config --global user.name "lasse" && \
  git config --global user.email "lasse-schloer@servermx.de" && \
  ln -s /lib/libc.musl-x86_64.so.1 /lib/ld-linux-x86-64.so.2 && \
  # -> Perl, may be needed for some packages
  apk add perl perl-doc && \
  # -> CXX/low-level compilation and numerical computing environment, needed for
  # YouCompleteMe and others
  apk add gfortran && \
  # `lapack` and `lapack-dev` are needed for e.g. `scipy`.
  apk add lapack lapack-dev && \
  apk add libstdc++ && \
  apk add libc-dev && \
  apk add musl-dev && \
  apk add libc6-compat && \
  apk add clang clang-dev clang-doc && \
  apk add gcc g++ gcc-doc && \
  apk add lld && \
  apk add make make-doc && \
    # Ninja does not exist for Alpine 3.15.0 at the moment
    # Samurai may be an alternative
  #apk add ninja ninja-doc ninja-bash-completion && \
  apk add cmake cmake-doc && \
  apk add boost-dev boost-doc && \
  # -> Python, needed for YouCompleteMe in (and as provider for) Neovim
  apk add python3 python3-doc python3-dev && \
  apk add py3-pip py3-pip-doc && \
  pip3 install --upgrade pip && \
  python3 -m pip install pynvim watchdog && \
  # -> Python modules
  #python3 -m pip install numpy scipy && \
  # -> Julia
  wget -O /opt/julia.tar.gz \
    https://julialang-s3.julialang.org/bin/musl/x64/1.7/julia-1.7.1-musl-x86_64.tar.gz && \
  gunzip /opt/julia.tar.gz && \
  tar -C /opt/ -xf /opt/julia.tar && \
  rm /opt/julia.tar && \
  ln -s /opt/julia-1.7.1/bin/julia /usr/bin/julia && \
  # -> Julia packages
  # TODO: Can I split this into several lines? Perhaps by doing `'…' \ '…'`?
  #julia -e 'using Pkg; Pkg.add(["Memoization", "ThreadSafeDicts", "OrderedCollections", "StatsBase", "Statistics", "PyCall", "DSP", "LinearMaps", "IterativeSolvers", "HypothesisTests", "IntervalSets", "JLD2", "DataFrames", "StructArrays", "LazyArrays", "Optim", "LoopVectorization", "AbstractFFTs", "FFTW", "JSON", "JSON3"])' && \
  # -> Setup steps which need to be done after the above
  # TODO: Doing `PlugInstall` like this crashes at the moment.
  #echo "Running PlugInstall for vim-plug…" && \
  #nvim -c PlugInstall -c qall && \
  fish -c fish_update_completions
COPY authorized_keys /root/.ssh/
# `id_rsa` is not included in the git repo for obvious reasons
COPY id_rsa /root/.ssh/
COPY id_rsa.pub /root/.ssh/
COPY motd /etc/motd
WORKDIR /root
#ENTRYPOINT /usr/sbin/sshd;/usr/bin/fish
ENTRYPOINT /usr/sbin/sshd -D

