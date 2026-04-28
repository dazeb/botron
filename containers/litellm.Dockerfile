FROM ghcr.io/berriai/litellm:main-v1.82.3-stable.patch.2

# No custom handlers needed — all providers route via standard LiteLLM paths.
# The proxy startup uses litellm's built-in CLI entrypoint.
