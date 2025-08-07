### References
# https://ccache.dev/manual/latest.html

rice.cache.stats() { # PUBLIC
  ccache -s
}

rice.cache.clear() { # PUBLIC
  ccache -C -z
}
