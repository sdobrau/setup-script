# DONE
function setup_python_environment {
  # ensures python3 also
  ensure_packages python3.9 python3-pip python3-virtualenvwrapper

  if ! [[ "$(which pipx)" ]]; then
    echo "Python: pipx not installed! Installing..."
    python3 -m pip install -qqq --user pipx
    echo "Python: pipx installed."
  fi

  echo "Python: All dependencies for Python installed!"
  # For everyday venv management.
  # installs python3-virtualenv also

  # TODO: $HOME for user
  # TODO add this to startup
  # source /usr/local/bin/virtualenvwrapper.sh
  export WORKON_HOME="${HOME}/.virtualenvs"
  export PROJECT_HOME="${HOME}/everything/python-projects"
  # source /usr/local/bin/virtualenvwrapper.sh
}

# DONE
function setup_bats {
  echo "Bash: installing 'bats'..."
  pushd "${BASE_CLONE_DIR}"
  git clone -q https://github.com/bats-core/bats-core/tree/master bats-core
  pushd bats-core
  # PREFIX/bin/bats, does not check for additional /
  install.sh ~/.local
  popd
  # not removing, as required for teardown (uninstall script provided)
}

# DONE
function setup_javascript_environment {
  if [[ "$(which nvm)" ]]; then
    echo "NVM: NVM already setup. Exiting..."
    return 2
  else
    echo "NVM: Installing NVM..."
    pushd "${BASE_CLONE_DIR}"
    git clone -q "https://github.com/nvm-sh/nvm"
    pushd nvm
    su - "${EUSER}"
    ./install.sh &>/dev/null
    popd &>/dev/null / && rm -rf nvm
    export NVM_DIR="${HOME}/.nvm"
    [[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"                 # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion
  fi
  nvm install node --latest-npm &>/dev/null
  nvm use node &>/dev/null
  nvm install-latest-npm &>/dev/null
  nvm alias default node &>/dev/null
  npm install -g corepack@latest &>/dev/null
  # enable pnpm
  corepack --enable
  corepack prepare pnpm@latest --activate
}

# DONE:
function setup_sbcl_environment {
  pushd "${BASE_CLONE_DIR}"
  fetch -z sbcl.tar.bz2 http://prdownloads.sourceforge.net/sbcl/sbcl-1.4.3-x86-linux-binary.tar.bz2
  pushd sbcl*
  ./install.sh
  popd
  rm -rf sbcl*
}

# TODO:
function setup_perl_environment {
  echo "stub"
}

# DONE
function setup_bash_environment {
  after python
  pipx install bashate
  ensure_package shfmt

}

# TODO: implement password
function setup_ruby_environment {
  ensure_packages expect
  local -ar SCRIPT_DIR=$(dirname "$_")
  # ^ we need this to input a password.

  # As detailed in rvm.io
  # https://rvm.io/rvm/security
  #
  # 1. install gpg keys
  #
  # We use an IP address as it is not
  # Assured systemd-resolved is not used for DNS.
  # gpg2's 'dirmngr' reads directly from resolv.conf
  # and fails to resolve 'keyserver.ubuntu.com'
  #
  # https://unix.stackexchange.com/questions/399027/gpg-keyserver-receive-failed-server-indicated-a-failure
  gpg2 --keyserver 162.213.33.8 \
    --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB

  # 2. install rvm
  pushd "${BASE_CLONE_DIR}"
  curl -sSL https://raw.githubusercontent.com/rvm/rvm/stable/binscripts/rvm-installer -o rvm-installer
  curl -sSL https://raw.githubusercontent.com/rvm/rvm/stable/binscripts/rvm-installer.asc -o rvm-installer.asc
  gpg2 --verify rvm-installer.asc rvm-installer
  # TODO: check chown for all executables
  chmod +x rvm-installer && X./rvm-installer
  ./rvm-installer
  rm -rf rvm-installer
  rm -rf rvm-installer.asc
  export PATH="${HOME}/.rvm/bin:$PATH"

  # 3. Setup some rubies
  # Requires a password to be unlocked with yubikey
  # TODO: implement here
  password="$(IMPLEMENT_PASSfWORD_HERE)"
  "./${SOURCE_DIR}/files/ruby-install-expect-script ${PASSWORD}"

}

# DONE
function setup_jenkins_environment {
  sudo wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo
  sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
  # Add required dependencies for the jenkins package
  sudo dnf install java-17-openjdk
  sudo dnf install jenkins
  sudo systemctl daemon-reload

  # add firewall permission
  sudo firewall-cmd --permanent --add-port=8080
  sudo firewall-cmd --permanent --add-service=jenkins
  sudo firewall-cmd --zone=public --add-service=http
  sudo firewall-cmd --reload

  # systemctl
  systemctl enable --now jenkins
}

# DONE
function setup_dxhd {
  # ensure_packages golang rofi
  pushd "${BASE_CLONE_DIR}"
  # FIXME: ...
  wget -O dxhd https://github.com/dakyskye/dxhd/releases/download/05.04.2021_02.38/dxhd_amd64
  # echo "Installing 'dxhd'..."
  # git clone -q https://github.com/dakyskye/dxhd.git
  # pushd dxhd
  # make fast
  chmod +x dxhd
  chown dxhd "${USER}":"${EUSER}"
  mv dxhd "${HOME}/.local/bin"
  # TODO: ${FILES} form for all
  cp ${FILES}/dxhd.sh "${HOME}/.config/dxhd.sh"
}
