use ./do.nu *

export def symlink [link original] {
  do auto {
    windows: { mklink $link $original },
    _: { ln -s $original $link }
  }
}
