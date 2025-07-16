import Config

if config_env() == :test do
  config :angela, enable: false
end
