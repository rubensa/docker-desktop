# add software to PATH
if [ -d "$SOFTWARE_INSTALL_DIR" ]; then
  for f in $(find -L $SOFTWARE_INSTALL_DIR -mindepth 1 -maxdepth 1 -type d);
  do
    if [ -d "$f/bin" ]; then
      # Calibre is an exception to the rule
      if [[ "$f" != *"calibre"* ]] ; then
        f="$f/bin"
      fi
    fi
    if [[ ":$PATH:" != *":$f"* ]]; then
      PATH="$f:$PATH"
    fi
  done
fi
