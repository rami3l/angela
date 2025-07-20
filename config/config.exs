import Config

config :angela, setup_commands: true

if config_env() == :test do
  config :angela, enable: false
end
