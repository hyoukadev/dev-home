use ./files.nu is-directory
use std/assert


assert equal (is-directory ./files.nu) false
assert equal (is-directory ./files.dir) true

