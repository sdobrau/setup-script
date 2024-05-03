#!/usr/bin/env bats
# bats file_tags=environment
# DONE

# So that files are sourced properly.
# These tests are run from the tests/ folder and not base.

function setup_file { #@test
    export SCRIPT_DIR=$(dirname "$_")
}

# DONE
function test_setup_javascript_environment { #@test
    run setup_js_environment
    which nvm
    which node
    which pnpm
}

# TODO
function test_setup_perl_environment { #@test
    run setup_perl_environment
}

# DONE
function test_setup_ruby_environment { #@test
    run setup_ruby_environment
    which rvm
}

# DONE
function test_setup_python_environment { #@test
    run setup_python_environment
    which virtualenvwrapper.sh
    which pipx
}

# DONE
function test_setup_bats { #@test
    run setup_bats
    bats &>/dev/null
}

# DONE
function test_setup_sbcl { #@test
    run setup_sbcl
    sbcl
}

# DONE
function test_setup_bash_environment { #@test
    bashate
    shfmt
}

# DONE
function test_setup_jenkins_environment { #@test
    [[ -f /etc/yum.repos.d/jenkins.repo ]]
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    rpm -qi "$(rpm -qa gpg-pubkey* | tail -1)" | grep -q Jenkins
    # Add required dependencies for the jenkins package
    sudo dnf -q upgrade
    sudo dnf -q install java-17-openjdk
    sudo dnf -q install jenkins
    sudo systemctl daemon-reload

    # test firewall
    firewall-cmd --list-services | grep -q jenkins
    firewall-cmd --list-ports | grep -q 8080
    firewall-cmd --zone=public --list-services | grep -q http
    systemctl -q is-active jenkins
    systemctl -q is-enabled jenkins
}

function test_setup_dxhd { #@test
    dxhd --version
}

# DONE
function teardown_file { #@test
    # DONE test_setup_javascript_environment
    corepack disable pnpm@latest
    npm remove -g corepack
    nvm deactivate node
    nvm uninstall node
    rm -rf "${HOME}/.nvm/nvm.sh"
    # TODO test_setup_perl_environment

    # DONE test_setup_ruby_environment
    rm -rf "${HOME}/.rvm}"
    # DONE test_setup_python_environment
    python3 -m pip uninstall -qqq pipx
    dnf remove -y python3-pip python3-virtualenvwrapper
    rm -rf ${HOME}/.virtualenvs
    # DONE test_setup_bats
    pushd "${BASE_CLONE_DIR}"/bats-core
    uninstall.sh ~/.local
    # TODO test_setup_sbcl
    # DONE test_setup_bash_environment
    pipx remove bashate
    dnf remove -q -y shfmt
    # DONE test_setup_jenkins_environment
    rm -rf /etc/yum.repos.d/jenkins.repo
    dnf -y -q remove java-17-openjdk jenkins
    # remove Jenkins key
    rpm -e "$(rpm -qa gpg-pubkey* | tail -1)"
    # remove firewall rules
    local -r YOURPORT=8080
    local -r PERM="--permanent"
    local -r SERV="$PERM --service=jenkins"

    firewall-cmd --permanent --remove-port=8080
    firewall-cmd --permanent --remove-service=jenkins
    firewall-cmd --zone=public --remove-service=http
    firewall-cmd --reload
    systemctl disable --now jenkins
    # DONE test_setup_dxhd
    rm -rf ${HOME}/.local/bin/dxhd
}
