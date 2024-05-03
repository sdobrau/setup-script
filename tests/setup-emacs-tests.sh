#!/usr/bin/env bats
# bats file_tags=emacs

# DONE?:
function test_configure_and_install_emacs { #@test
  run setup_emacs_build
  emacs --version
}

# TODO:
function test_setup_emacs_test_config { #@test
  run setup_emacs_test_config
  assert
}

# TODO:
function test_setup_emacs_clone { #@test
  run setup_emacs_clone
  assert
}

# TODO:
function test_setup_emacs_main_dir { #@test
  run setup_emacs_main_dir
  assert
}

# DONE
function test_setup_eww_history_ext { #@test
  run setup_eww_history_ext
  emacsclient -l "${HOME}/.emacs.d/lib/others/eww_history_ext.el"
}

# DONE
function test_setup_pdf_tools { #@test
  run setup_pdf_tools
  "${HOME}/.local/bin/epdfinfo"
  [[ -d "${HOME}/.emacs.d/packages/other/pdf-tools" ]]
}

function teardown_file { #@test
  # DONE test_setup_emacs_testconfig
  # DONE test_setup_emacs_clone
  dnf remove -q -y emacs
  # DONE test_setup_emacs_main_dir
  dnf remove -q -y gh # git auth
  rm -rf "${HOME}/.config/gh"
  rm -rf "${HOME}/emacs-backup*"
  # TODO test_setup_eww_history_ext
  # DONE test_configure_and_install_emacs
  pushd /tmp/
  sudo make uninstall
  rm -rf /tmp/emacs
  rm -rf "${HOME}/.emacs.d"
  # DONE test_setup_pdf_tools
  rm -rf "${HOME}/.local/bin/epdfinfo"
  rm -rf "${HOME}/.emacs.d/packages/other/pdf-tools"
}
