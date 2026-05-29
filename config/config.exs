import Config

config :kvbucket,
  enabled: true

import_config "#{config_env()}.exs"
