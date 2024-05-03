#!/usr/bin/env bats
# TODO: setup

# bats file_tags=setup

# So that files are sourced properly.
# These tests are run from the tests/ folder and not base.

function setup_file{ #@test
    export SCRIPT_DIR=$(dirname "$_")
}

# TODO:
function test_fetch { #@test
    assert
}

# TODO:
function test_ensure_remote_bash { #@test
    run
}

# DONE:
function test_ensure_packages { #@test
    run ensure_packages wbox
    dnf list wbox # lists installed package
}


# DONE:
function test_setup_dnf_gpg_check { #@test
    run setup_dnf_gpg_check
    grep -q -q "^gpgcheck=True" /etc/dnf/dnf.conf
}

# Here we create a dummy directory to test that the command works as expected
# DONE
function test_external_storage_mounted { #@test
    mkdir /mount-point
    mkdir /some-dir-to-mount/
    mount --bind /some-dir-to-mount /mount-point
    lsblk -I 253 -o MOUNTPOINTS | grep -q mount-point
}

# TODO:
function test_todo_print_help { #@test
    assert
}

# DONE:
function test_setup_redshift { #@test
    run setup_redshift
    systemctl -q --user is-active redshift
    systemctl -q --user is-enabled redshift
}

# TODO:
function test_todo_setup_home_packages { #@test
    assert
}

# TODO:
function test_todo_setup_nginx { #@test
    assert
}

# TODO:
function test_todo_setup_sbcl { #@test
    sbcl --noinform --non-interactive --eval "(+ 1 1)"
}

# TODO:
function test_git clone -q { #@test
    pushd "${BASE_CLONE_DIR}"
    git clone -q https://github.com/pgrange/bash_unit .
    # Did repo clone ?
    [[ -d "bash_unit" ]]
}

# TODO:
function test_setup_mpvacious { #@test
    assert
}

# DONE
function test_setup_beets_and_deps_installed_and_config_file_present { #@test
    run setup_beets
    # The 'beets' venv is present
    [[ -d ${HOME}/.local/pipx/beets ]]
    # The 'beet' executable is not present!"
    whereis beet
    # Beet configuration is not missing
    [[ -f /home/${EUSER}/.config/beets/config.yaml ]]
    # ''beets'' is installed’
    [[ -d ${HOME}/.local/pipx/beets ]]
    # 'beetcamp' is installed’
    [[ -d ${HOME}/.local/pipx/beetcamp ]]
    # 'beets-check' is installed’
    [[ -d ${HOME}/.local/pipx/beets-check ]]
    # 'beets-copyartifacts3' is installed’
    [[ -d ${HOME}/.local/pipx/beets-copyartifacts3 ]]
    # 'python3-discogs-client' is installed’
    [[ -d ${HOME}/.local/pipx/python3-discogs-client ]]
    # 'beautifulsoup4' is installed’
    [[ -d ${HOME}/.local/pipx/beautifulsoup4 ]]
    # 'requests' is installed’
    [[ -d ${HOME}/.local/pipx/requests ]]
    # 'beet-summarize' is installed’
    [[ -d ${HOME}/.local/pipx/beet-summarize ]]
    # 'whatlastgenre' is installed’
    [[ -d ${HOME}/.local/pipx/whatlastgenre ]]
    # 'beets-usertag' is installed’
    [[ -d ${HOME}/.local/pipx/beets-usertag ]]

}

# DONE
function test_setup_beets_mp3val_is_installed { #@test
    run setup_beets_mp3val
    which mp3val mp3val is not installed!
}

# DONE
function test_setup_dns_with_dot { #@test
    resolvectl status
    systemctl is-active systemd-resolved.service
    dig @1.1.1.1 +tls +short google.com
}

# DONE
function test_setup_standard_font { #@test
    run setup_standard_font
    assert "[[ -f ${HOME}/.local/share/fonts/VictorMono-Regular.ttf ]]" \
           "VictorMono-Regular.ttf not found in home directory!"
}

# DONE
function test_setup_spamhaus { #@test
    run setup_spamhaus
    which spamhaus.sh
    grep -q -q "spamhaus.sh" "/var/spool/cron/${USER}"
    iptables -L Spamhaus
}

# DONE
function test_setup_firejail { #@test
    assert "[[ -f /etc/firejail/mpv.local ]]" "'mpv' firejail configuration not found!"
    assert "firecfg"
}

# TODO:
function test_setup_stumpwm { #@test
    run
}

# TODO:

function test_add_to_cron { #@test
    assert
}

# TODO:
function test_ensure_gh_authentication { #@test
    run ensure_gh_authentication
    assert "which gh" "'gh' is not installed!"
    assert "which jq" "'jq' is not installed!"
    assert "gh auth status" "gh authentication is not setup!"
}

# TODO:
function test_setup_yubikey_secrets { #@test
    assert
}

# TODO:
function test_setup_irc_cert { #@test
    assert
}

# DONE:
function test_usb_guard_successful_install { #@test
    run setup_usbguard
    [[ -f /etc/usbguard/rules.conf ]]
    systemctl -q is-active usbguard
    systemctl -q is-enabled usbguard
}

# DONE
function test_ensure_gh_authentication_works { #@test
    run ensure_gh_authentication
    dnf info --nogpgcheck  --installed gh
}

# DONE
function test_find_luks_partitions_partitions_are_valid { #@test
    for partition in $(find_luks_partitions); do
      cryptsetup isLuks /dev/"$partition";
        done
}

# DONE
function test_all_setup_function_adds_to_array_if_success { #@test
    run call_setup_function "echo" "systemctl" # should return success
    # should be added to SUCCESSFULLY_SETUP variable
    Array::hasValue 'SUCCESSFULLY_SETUP' 'echo'
}

# DONE
function test_all_setup_function_no_add_to_array_if_fail { #@test
    run call_setup_function "false" # assume setup function fails
    # then 'SUCCESSFULLY_SETUP' should be empty
    ! [[ Array::hasValue 'SUCCESSFULLY_SETUP' 'echo' ]]
}

# DONE
function test_setup_wine { #@test
    run setup_wine
    7z
    wine --version
    winetricks --version
}

# DONE
function test_setup_gnome_shell_extensions { #@test
    run setup_gnome_shell_extensions
    gnome-extensions show switcher@landau.fi
    gnome-extensions show remove-alt-tab-delay@daase.net
    gnome-extensions show ssm-gnome\@lgiki.net.shell-extension.zip
    gnome-extensions show weatheroclock@CleoMenezesJr.github.io
    gnome-extensions show browser-tabs@com.github.harshadgavali

    dnf info tabsearchproviderconnector
}

function test_setup_rpm_fusion { #@test
    dnf info --nogpgcheck --installed rpmfusion-nonfree-release-$(rpm -E %fedora)
    # TODO: what? ffmpeg
}

# DONE
function test_setup_autorandr { #@test
    autorandr
    if [[ -f "${HOME/.config/autorandr/laptop }}" ]]; then
      true # nothing to do
    else
      [[ -f /usr/lib/systemd/system-sleep/autorandr ]]
    fi
}

# TODO
function test_setup_swap_hibernation { #@test

}


# TODO
function test_setup_git_config { #@test

}


function teardown_file { #@test
    # DONE usbguard
    rm -rf /etc/usbguard/rules.conf
    systemctl disable --now usbguard
    # DONE test_setup_spamhaus
    sed -i '/.*spamhaus\.sh/d' /var/spool/crontab/${EUSER}
    rm -rf ~/.local/bin/spamhaus.sh
    iptables -X Spamhaus
    # DONE test_setup_beets_and_deps_installed_and_config_file_present
    rm -rf ${EUSER}/.config/beets/config.yaml
    pipx uninstall beets beetcamp beets-check beets-copyartifacts3 \
         python3-discogs-client \
         beautifulsoup4 \
         requests \
         "git+https://github.com/steven-murray/beet-summarize.git" \
         "git+https://github.com/YetAnotherNerd/whatlastgenre@master" \
         "git+https://github.com/igordertigor/beets-usertag.git"
    # DONE test_setup_beets_mp3val_is_installed
    rm -rf ${EUSER}/.local/bin/mp3val
    # DONE test_setup_standard_font
    rm -rf ${HOME}/.local/share/fonts/Victor*
    # DONE test_setup_dns
    rm -rf /etc/systemd/resolved.conf
    systemctl -q restart systemd-resolved.service
    # DONE test_setup_js_environment
    corepack disable pnpm@latest
    npm remove -g corepack
    nvm deactivate node
    nvm uninstall node
    rm -rf "${HOME}/.nvm/nvm.sh"
    # DONE test_setup_firejail
    rm -rf /etc/firejail/mpv.local
    # DONE test_ensure_packages
    dnf remove -q -y wbox
    # DONE test_external_storage_mounted
    umount /mount-point
    dnf-rf /mount-point
    rm -rf /some-dir-to-mount
    # DONE test_ensure_gh_authentication
    dnf remove -q -y gh jq
    # DONE test_setup_yubikey_with_luks_partition_crypttab_entries"
    echo "" > /etc/crypttab
    dnf partition in $(find_luks_partitions); do
  systemd-cryptenroll --wipe-slot=fido2 "/dev/${partition}"
    done
    # DONE test_setup_wine
    rm -rf "${HOME}/.wine"
    dnf remove -q -y wine winetricks
    # DONE test_setup_dnf_gpg_check
    sed -ie "s/^gpgcheck=True/#gpgcheck=True/g" /etc/dnf/dnf.conf
    # DONE test_setup_gnome_shell_extensions
    rm -rf "${HOME}/.local/share/gnome-shell/extensions/switcher@landau.fi"
    rm -rf "${HOME}/.local/share/gnome-shell/extensions/remove-alt-tab-delay@daase.net"
    # TODO: test with just gnome-extensions to be cleaner
    gnome-extensions uninstall -q ssm-gnome\@lgiki.net.shell-extension.zip
    gnome-extensions uninstall -q weatheroclock\@CleoMenezesJr.github.io
    gnome-extensions uninstall -q browser-tabs\@com.github.harshadgavali
    sudo dnf remove -y tabsearchproviderconnector
    sudo dnf copr disable -y harshadgavali/searchproviders
    # DONE test_setup_rpm_fusion
    sudo dnf remove -q -y rpmfusion-nonfree-release-$(rpm -E %fedora)
    sudo dnf remove -q -y ffmpeg
    # DONE test_setup_autorandr
    sudo dnf remove -y autorandr
    rm -rf /usr/lib/systemd/system-sleep/autorandr
    rm -rf "${HOME}/.config/autorandr/*"
    # TODO test_setup_swap_hibernation
    # TODO test_setup_git_config
}
