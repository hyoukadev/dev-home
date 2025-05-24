
def --env set_env_virtual_env_by_relative_path [name: string] {
  $env.VIRTUAL_ENV = pwd | path join $name
}

def --env unset_env_virtual_env [] {
  hide-env VIRTUAL_ENV
}

def print_env_virtual_env [] {
  $env.VIRTUAL_ENV
}
