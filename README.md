# Remote Command Execution

## Instructions

- Install Ruby
```
$ sudo apt-get install ruby
```

- Install a few ruby gems
```
$ sudo gem install sinatra
$ sudo gem install net-ssh
```

- specify password in `execute_shell_script` function
```Ruby
password = secret
```

- Execute as root (since the first command requires a password)
```
sudo ruby server.rb
```

- Go to `localhost:4567` on the browser
