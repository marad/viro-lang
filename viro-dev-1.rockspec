package = "viro"
version = "dev-1"
rockspec_format = "3.0"
source = {
   url = "*** please add URL for source tarball, zip or repository here ***"
}
description = {
   homepage = "https://github.com/marad/viro",
   license = "MIT"
}
dependencies = {
}
build_dependencies = {
}
build = {
   type = "builtin",
   modules = {
      ["viro"] = "src/main.lua"
   }
}
test_dependencies = {
}

test = {
   type = "busted",
   flags = {
      --"--verbose"
   }
}
