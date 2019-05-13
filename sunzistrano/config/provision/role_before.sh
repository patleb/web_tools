#!/bin/bash
set -e
set -u
<% if @sun.debug == 'trace' %>
  set -x
<% end %>

source /etc/os-release
source sun.sh

export DEBIAN_FRONTEND=noninteractive
export TERM=linux

sun.setup_progress
ROLE_ID=<%= @sun.role %>
ROLE_START=$(sun.start_time)
REBOOT_FORCE=false

source roles/hook_before.sh
