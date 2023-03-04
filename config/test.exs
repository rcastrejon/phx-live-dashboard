import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :phx_app, PhxAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "1KV2lOzt7uYxy66rCuGH9xz2+ObfRo4XYw1oREPix7eSyx4SKPIaBbqv8qU06tBQ",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
