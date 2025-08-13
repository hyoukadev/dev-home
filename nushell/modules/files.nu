use ./do.nu *

export def is-directory [path] {
  (ls -D $path | get type.0) == dir
}


export def symlink [link original] {
  do auto {
    windows: {
      if (is-directory $original) {
        mklink /d $link $original #directory
      } else {
        mklink $link $original #file
      }
    },
    _: { ln -s $original $link }
  }
}