FROM alpine:3.17.3
EXPOSE 22

# Remember:
# * Comments in Dockerfile need `#` at the *beginning* of the line.
# * Shell commands under RUN can have indented comments.
# * Adding a backslash after such comments helps the syntax highlighting in my
#   Neovim setup, for whatever reason.

# Regarding the splitting or joining of RUN commands:
# https://stackoverflow.com/questions/39223249/multiple-run-vs-single-chained-
# run-in-dockerfile-which-is-better

# -> Foundational packages
RUN cd /root/ && apk update
RUN cd /root/ && \
  apk add \
    mandoc man-pages mandoc-apropos less-doc tar-doc wget-doc \
    tzdata tzdata-doc \
    openssh openssh-doc \
    curl curl-doc \
    git git-doc \
    # Note: `ncurses` is for coloring in terminals like `screen*` and `tmux*` \
    ncurses ncurses-doc \
    botan botan-doc \
    parallel parallel-doc \
    # Note: Using LibreSSL here. \
    #openssl openssl-doc \
    libressl libressl-doc \
    xz xz-doc \
    lz4 lz4-doc

# -> Perl, because many packages and programs tend to depend on it
RUN cd /root/ && \
  apk add perl perl-doc

# -> CXX/low-level compilation and numerical computing environment, partly
# needed for YouCompleteMe and others
RUN cd /root/ && \
  apk add \
    gfortran \
    # Note: `lapack` and `lapack-dev` are needed for e.g. `scipy`. \
    lapack lapack-dev \
    openblas openblas-dev openblas-doc \
    libstdc++ \
    libc-dev \
    musl-dev \
    libc6-compat gcompat \
    # Note: 2023-05-09: `clang` and subpackages are not available on 3.17.3 \
    #clang clang-dev clang-doc \
    gcc g++ gcc-doc \
    lld \
    make make-doc \
    # Note: Ninja does not exist for Alpine 3.17.3 at the moment \
    # …Samurai may be an alternative \
    #ninja ninja-doc ninja-bash-completion \
    cmake cmake-doc \
    boost-dev boost-doc

# TODO: Previously, I did this:
# `ln -s /lib/libc.musl-x86_64.so.1 /lib/ld-linux-x86-64.so.2`
# This command produces an error now and I haven't looked into fixing it yet

# -> My interactive "userland"
RUN cd /root/ &&
  apk add \
    mosh mosh-doc \
    fish fish-doc fish-tools \
    tmux tmux-doc \
    neovim neovim-doc \
    ranger ranger-doc \
    viu viu-doc

# -> LaTeX
RUN cd /root/ && \
  apk add tectonic

# -> Python, needed for YouCompleteMe in (and as provider for) Neovim
RUN cd /root/ && \
  apk add python3 python3-doc python3-dev \
    py3-pip py3-pip-doc && \
  pip3 install --upgrade pip && \
  python3 -m pip install pynvim watchdog

# -> Python modules
RUN cd /root/ && \
  python3 -m pip install \
    numpy \
    scipy \
    mne \
    BCI2kReader

# Building wheels for `numpy` and especially `scipy` in the above takes ages.
# Maybe I can find a better way. And in the process switch to `conda` or at
# least virtualenv. (TODO)

# -> Julia
RUN cd /root/ && \
  # Note: At the time of writing (2022-02-03), there's no Julia package for \
  # Alpine. Hence, we're installing the `musl` Binary manually. This is not \
  # uncommon, since other distros do not necessarily have up-to-date Julia \
  # packages either. \
  # Note: I'm writing this one on 2023-05-09. Don't know if I'll grow fond of \
  # JuliaUp in the future but at the moment, it seems to not be compatible \
  # with Alpine. The above note is still true. \
  wget -O /opt/julia.tar.gz \
    https://julialang-s3.julialang.org/bin/musl/x64/1.8/julia-1.8.5-musl-x86_64.tar.gz && \
  gunzip /opt/julia.tar.gz && \
  tar -C /opt/ -xf /opt/julia.tar && \
  rm /opt/julia.tar && \
  ln -s /opt/julia-1.8.5/bin/julia /usr/bin/julia

# -> Julia packages
# TODO: Change `using` to `import` below if I change anything about this anyway
RUN cd /root/ && \
  julia -e 'using Pkg; Pkg.add([ \
\
    "FileIO", \
    "Match", \
    "Memoization", \
    "LoopVectorization", \
    "PyCall", \
\
    "IntervalSets", \
    "LinearMaps", \
    "FixedPointNumbers", \
    "MultiFloats", \
\
    "StructArrays", \
    "PooledArrays", \
    "LazyArrays", \
    "Dictionaries", \
    "OrderedCollections", \
    "ThreadSafeDicts", \
\
    "Tables", \
    "TypedTables", \
    "DataFrames", \
    "SplitApplyCombine", \
\
    "StatsBase", \
    "Statistics", \
    "HypothesisTests", \
    "DSP", \
    "AbstractFFTs", \
    "FFTW", \
    "FastRunningMedian", \
\
    "Colors", \
    "Images", \
    "Measures", \
    "Compose", \
    "Gadfly", \
    "Luxor", \
\
    "IterativeSolvers", \
    "Optim", \
\
    "JLD2", \
    "CodecZlib", \
    "JSON", \
    "JSON3", \
  ])'

# -> Miscellaneous setup
RUN cd /root/ && \
  echo "root:root" | chpasswd && \
  mkdir -p /root/bin && \
  ln -s /usr/share/zoneinfo/CET /etc/localtime && \
  rm /etc/motd && \
  mkdir /root/.ssh && chmod 700 /root/.ssh && \
  # TODO: `ssh-keygen -A` creates host keys in `/etc/ssh` – do I need that? \
  ssh-keygen -A && \
  sed -i 's/\/bin\/ash/\/usr\/bin\/fish/g' /etc/passwd && \
  mkdir /root/.parallel && touch /root/.parallel/will-cite && \
  printf "\n# %s\n%s" \
    "If the client sends its terminal's color capability, accept it" \
    "AcceptEnv COLORTERM" >> /etc/ssh/sshd_config

COPY authorized_keys /root/.ssh/
# Note: `id_rsa` is not included in the git repo for obvious reasons
COPY id_rsa /root/.ssh/
COPY id_rsa.pub /root/.ssh/

COPY motd /etc/motd

# -> Git setup
RUN cd /root/ && \
  git config --global user.name "lasse" && \
  git config --global user.email "lasse-schloer@servermx.de" && \
  # Note: I have trouble getting a git credential helper to run on Alpine. The \
  # `cache` mode at least allows to remember passwords for a short time. \
  # Using SSH instead of HTTPS may help, I think. \
  git config --global credential.helper cache && \
  ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts

# -> CPCP, Neovim, Tmux and Fish setup
RUN cd /root/ && \
  curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim && \
  mkdir -p /root/.config && \
  git clone git@github.com:publik-void/cross-platform-copy-paste.git \
    /root/.config/cross-platform-copy-paste && \
  ln -s /root/.config/cross-platform-copy-paste/cpcp.sh /root/bin/cpcp && \
  git clone git@github.com:publik-void/config-fish.git \
    /root/.config/fish && \
  git clone git@github.com:publik-void/config-nvim.git \
    /root/.config/nvim && \
  git clone git@github.com:publik-void/config-tmux.git \
    /root/.config/tmux && \
  ln -s /root/.config/tmux/tmux.conf /root/.tmux.conf

# -> Mosh, from source
# Note: I disabled (commented out) this section, because as of the time of
# writing this (2023-05-09), it seems there is a new version of mosh and it's
# available in Alpine 3.17. Hooray!
  # Note: I'm building from source to get the latest version. I did this in the
  # hope that it would enable some features not included in the latest release
  # (which is `mosh` 1.3.2 from 2017 at the time of writing this, 2022-02-03).
  # There may e.g. be better color support. However, at least without additional
  # help, this version of `mosh` still lacks the following functionality for me:
  # * Cursor shape changing in Neovim
  # * Copy-to-clipboard from `tmux` inside `mosh`
  # This fork proposes a fix for the cursor shape issue (open pull request):
  # `https://github.com/matheusfillipe/mosh.git`
  # However, this doesn't seem to work for me. Perhaps because my `mosh-client`
  # isn't built from that fork.
  # So I guess we're still waiting for `mosh` to catch up…
  #
  # Inspired by the Alpine `mosh` package at:
  # `https://git.alpinelinux.org/aports/tree/main/mosh/APKBUILD`
  #
  # Run dependencies (some of these may already be installed)
#RUN cd /root/ && \
#  apk add perl \
#    ncurses-dev \
#    libprotobuf \
#    openssh \
#    libutempter-dev && \
#  # Build dependencies (yes, `perl-doc` is needed) \
#  apk add --no-cache --virtual .build-deps \
#    git \
#    make \
#    automake \
#    autoconf \
#    g++ \
#    lld \
#    protobuf-dev \
#    libutempter-dev \
#    ncurses-dev \
#    openssl1.1-compat-dev \
#    perl-doc && \
#  git clone https://github.com/mobile-shell/mosh.git /opt/mosh && \
#  sed -i '/unicode-later-combining.test/d' /opt/mosh/src/tests/Makefile.am && \
#  export CXXFLAGS="$CXXFLAGS -Wno-deprecated-declarations" && \
#  cd /opt/mosh && \
#  ./autogen.sh && \
#  ./configure \
#    --prefix=/usr \
#    --sysconfdir=/etc \
#    --mandir=/usr/share/man \
#    --localstatedir=/var \
#    --enable-compile-warnings=error \
#    --enable-examples && \
#  make && \
#  make install && \
#  cd /root/ && \
#  rm -rf /opt/mosh && \
#  apk del .build-deps

# -> Setup steps which need to be done after the above
RUN cd /root/ && \
  echo "Running PlugInstall for vim-plug…" && \
  nvim -c PlugInstall -c qall && \
  # Note: In the following, `fish` will warn that it is unable to get the \
  # manpath, and falls back to some defaults, including `/usr/share/man`, \
  # which I believe is correct. \
  fish -c fish_update_completions

WORKDIR /root

#ENTRYPOINT /usr/sbin/sshd;/usr/bin/fish
ENTRYPOINT /usr/sbin/sshd -D

