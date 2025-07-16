import Config
import Dotenvy

env_dir_prefix = System.get_env("RELEASE_ROOT") || Path.expand(".")

source!([
  Path.absname(".env", env_dir_prefix),
  Path.absname("#{config_env()}.env", env_dir_prefix),
  System.get_env()
])

# Configure ex_gram with environment variables
config :ex_gram, method: :polling

if config_env() != :test do
  config :ex_gram, token: env!("ANGELA_TELEGRAM_BOT_TOKEN", :string!)
end
