#!/bin/bash

## Test for the hooks of acme.sh
pre_hook_file="/tmp/prehook"
pre_hook_command="touch $pre_hook_file"
post_hook_file="/tmp/posthook"
post_hook_command="touch $post_hook_file"



if [[ -z $GITHUB_ACTIONS ]]; then
  le_container_name="$(basename "${0%/*}")_$(date "+%Y-%m-%d_%H.%M.%S")"
else
  le_container_name="$(basename "${0%/*}")"
fi
run_le_container "${1:?}" "$le_container_name" --cli-args "--env ACME_DEFAULT_PRE_HOOK=$pre_hook_command" --cli-args "--env ACME_DEFAULT_POST_HOOK=$post_hook_command"

# Create the $domains array from comma separated domains in TEST_DOMAINS.
IFS=',' read -r -a domains <<< "$TEST_DOMAINS"

# Cleanup function with EXIT trap
function cleanup {
  # Remove any remaining Nginx container(s) silently.
  for domain in "${domains[@]}"; do
    docker rm --force "$domain" &> /dev/null
  done
  # Cleanup the files created by this run of the test to avoid foiling following test(s).
  docker exec "$le_container_name" /app/cleanup_test_artifacts
  # Stop the LE container
  docker stop "$le_container_name" > /dev/null
}
trap cleanup EXIT

# Run a separate nginx container for each domain in the $domains array. ith LETSENCRYPT_EMAIL set
# Start all the containers in a row so that docker-gen debounce timers fire only once.
# The nginx container for ${domains[0]} checks the Default Hooks
container_email="contact@${domains[0]}"
for (( i=0; i<${#domains[@]}; i++ )); do
  if [[ i == 0 ]]; then
    run_nginx_container --hosts "${domains[0]}" --cli-args "--env LETSENCRYPT_EMAIL=${container_email}"
  else
    pre_hook_file="/tmp/prehook${domains[$i]}"
    pre_hook_command="touch $pre_hook_file"
    post_hook_file="/tmp/posthook${domains[$i]}"
    post_hook_command="touch $post_hook_file"
    run_nginx_container --hosts "${domains[$i]}" --cli-args "--env LETSENCRYPT_EMAIL=${container_email}" --cli-args "--env ACME_PRE_HOOK=$pre_hook_command" --cli-args "--env ACME_POST_HOOK=$post_hook_command"
  fi

  # Wait for a symlink at /etc/nginx/certs/${domains[$i]}.crt
  wait_for_symlink "${domains[$i]}" "$le_container_name"

  ##Check if the command is deliverd properly in /etc/acme.sh
  if docker exec "$le_container_name" [[ ! -d "/etc/acme.sh/$container_email" ]]; then
    echo "The /etc/acme.sh/$container_email folder does not exist."
  elif docker exec "$le_container_name" [[ ! -d "/etc/acme.sh/$container_email/${domains[$i]}" ]]; then
    echo "The /etc/acme.sh/$container_email/${domains[$i]} folder does not exist."
  elif docker exec "$le_container_name" [[ ! -f "/etc/acme.sh/$container_email/${domains[$i]}/${domains[$i]}.conf" ]]; then
    echo "The /etc/acme.sh/$container_email/${domains[$i]}/${domains[$i]}.conf file does not exist."
  fi
  acme_pre_hook_key="Le_PreHook="
  acme_post_hook_key="Le_PostHook="
  acme_base64_start="'__ACME_BASE64__START_"
  acme_base64_end="__ACME_BASE64__END_'"
  pre_hook_command_base64=$(echo -n "$pre_hook_command" | base64)
  post_hook_command_base64=$(echo -n "$post_hook_command" | base64)

  acme_pre_hook="$(docker exec "$le_container_name" grep "$acme_pre_hook_key" "/etc/acme.sh/$container_email/${domains[$i]}/${domains[$i]}.conf")"
  acme_post_hook="$(docker exec "$le_container_name" grep "$acme_post_hook_key" "/etc/acme.sh/$container_email/${domains[$i]}/${domains[$i]}.conf")"

  if [[ "$acme_pre_hook_key$acme_base64_start$pre_hook_command_base64$acme_base64_end" != "$acme_pre_hook" ]]; then 
    if [[ i == 0 ]]; then
      echo "Default Prehook command not saved properly"
    else
      echo "Prehook command of ${domains[$i]} not saved properly"
    fi
  elif [[ "$acme_post_hook_key$acme_base64_start$post_hook_command_base64$acme_base64_end" != "$acme_post_hook" ]]; then 
    if [[ i == 0 ]]; then
      echo "Default Posthook command not saved properly"
    else
      echo "Posthook command of ${domains[$i]} not saved properly"
    fi
  fi


  ## Check if the action is performed 
  if docker exec "$le_container_name" [[ ! -f "$pre_hook_file" ]]; then
    if [[ i == 0 ]]; then
      echo "Default Prehook action failed"
    else
      echo "Prehook action of ${domains[$i]} failed"
    fi
  elif docker exec "$le_container_name" [[ ! -f "$post_hook_file" ]]; then
    if [[ i == 0 ]]; then
      echo "Default Posthook action failed"
    else
      echo "Posthook action of ${domains[$i]} failed"
    fi
  fi

  # Stop the Nginx container silently.
  docker stop "${domains[$i]}" > /dev/null

done



