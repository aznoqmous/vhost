#!/bin/bash

script_directory=${0%/*}
current_directory=$(pwd)
config_file="vhost.yml"

sample_conf_file="$script_directory/sample.conf"
sample_ssl_conf_file="$script_directory/sample-ssl.conf"
sample_yml_file="$script_directory/$config_file"

trap "exit 1" TERM
export TOP_PID=$$
quit(){
  kill -s TERM "$TOP_PID"
}

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
  # echo "$1" "${!variable}"

  if [[ -z "$variable" ]]; then
    exit
    #echo -e "\e[32m$variable:\e[0m "${!variable}
  fi
  if [[ -z ${!variable} ]]; then
    echo "$variable is not defined !"
    quit
  fi
}

check_config(){
    if [[ ! -f "$config_file" ]]; then
      read -p "Do you want to create an empty vhost.yml file in current directory ? (Press <Enter> to continue, <CTRL+C> to cancel)"
      cp "$sample_yml_file" "$config_file"
      quit
    fi

    parse_yml "$config_file"

    check_variable "server"
    check_variable "user"
    check_variable "document_root"
    check_variable "php_version"
    check_variable "ssl"
    check_variable "main_domain"
}

content=""
generate(){
  content=$(cat "$sample_conf_file")

  generate_ssl

  content=$(echo "$content" | sed -e "s~##server##~$server~g")
  content=$(echo "$content" | sed -e "s~##user##~$user~g")
  content=$(echo "$content" | sed -e "s~##document_root##~$document_root~g")
  content=$(echo "$content" | sed -e "s~##php_version##~$php_version~g")
  content=$(echo "$content" | sed -e "s~##ssl##~$ssl~g")
  content=$(echo "$content" | sed -e "s~##main_domain##~$main_domain~g")
  if [[ -z "$server_aliases" ]]; then
    content=$(echo "$content" | grep -v "ServerAlias")
  else
    content=$(echo "$content" | sed -e "s~##server_aliases##~$server_aliases~g")
  fi

  echo "$content" > "$file"
}

generate_ssl(){
  if [[ "$ssl" = "yes" ]]; then
    content=$(cat "$sample_ssl_conf_file")
  fi
}

check_config
generate

apacheCtl=$(apache2ctl -t)
echo "$apacheCtl"
if [[ -z $(echo "$apacheCtl" | grep "failed") ]];
then
  read -p "Do you want to restart apache2 service ? (Press <Enter> to continue, <CTRL+C> to cancel)"
  service apache2 restart
else
  echo "" > /dev/null
fi

