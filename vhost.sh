#!/bin/bash

current_directory=$(pwd)
config_file="vhost.yml"

parse_yml() {
  yml_file="$1"

  if [[ -n $(cat "$yml_file" | tail -n 1) ]]; then
    echo "" >>"$yml_file"
    echo "" >>"$yml_file"
  fi

  while read var value; do
    if [[ -z $(echo "$var" | grep -v ":") ]]; then
      # basic key: value
      current_var=$(echo "$var" | sed "s/://g")
      lastValue="$value"
    else
      # set - items
      lastValue="$lastValue $value"
      lastValue=$(echo "$lastValue" | sed -E "s/^ //g")
    fi

    if [[ -z $(echo "$lastValue") ]]; then
      continue
    else
      export "$current_var"="$lastValue"
    fi
  done <"$yml_file"
}

check_variable() {
  variable="$1"
  if [[ -z "$variable" ]]; then
    exit
    #echo -e "\e[32m$variable:\e[0m "${!variable}
  fi
  if [[ -z ${!variable} ]]; then
    echo "Updat fatal error : $variable is not defined !"
    exit
  fi
}

check_config(){
    parse_yml "$config_file"

    check_variable "file"
    check_variable "user"
    check_variable "document_root"
    check_variable "php_version"
    check_variable "ssl"
    check_variable "main_domain"
    check_variable "server_aliases"
}

check_config
