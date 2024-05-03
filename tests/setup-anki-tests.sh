#!/usr/bin/env bats
# bats file_tags=anki

# TODO:
function test_setup_anki_sync_server_nginx_config { #@test
  setup_anki_sync_server_nginx_config
  assert
}

# DONE
function test_setup_anki_connect { #@test
  run setup_anki_connect
  anki &
  assert "curl 127.0.0.1:8765" "anki-connect not running!"
}

# DONE
function test_setup_anki_config { #@test
  run setup_anki_config
  assert "diff ${BACKUP_DIR}/Anki2 ${HOME}/.local/share/Anki2"
  "Anki config (probably) not copied!"
  anki
  assert "curl 127.0.0.1:8765" "'anki-connect' not up!"
}

# DONE
function test_setup_anki_sync_server { #@test
  run setup_anki_sync_server
  systemctl is-enabled anki-sync-server.service
  systemctl is-active anki-sync-server.service
  [[ $(curl localhost:27701) == 'Anki Sync Server' ]] # Sync server up
}

# DONE
function test_setup_anki_package { #@test
  run setup_anki_package
  assert "[[ -d ${HOME}/.local/pipx/aqt ]]" \
         "The 'aqt' venv is not present!"
}

function teardown_file { #@test
  # test_setup_anki_sync_server_nginx_config
  # test_setup_anki_connect
  rm -rf ${HOME}/.local/share/Anki2/addons21/2055492159
  kill -s SIGHUP $(pgrep anki)
  # DONE setup_jap_anki_sync_server
  systemctl --user diable --now anki-sync-server.service
  rmvirtualenv anki-sync-server &> /dev/null
  rm -rf ~/.virtualenvs/anki-sync-server
  # TODO: check
  # setup_anki_package
  pipx uninstall aqt[qt6] &> /dev/null
  # setup_anki_config
}
