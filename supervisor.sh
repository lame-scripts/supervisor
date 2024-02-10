#!/bin/bash

# Supervisor script.
# See help section below.
# Configuration file: config-supervisor.conf

_cmd="$1"
_config_file="config-supervisor.conf"
_SV_CTRL_LOG_FILE="log-supervisor-ctrl.log"
_SV_LOG_FILE="log-supervisor.log"
_this_script="${BASH_SOURCE[0]}"
_required_programs="rkill" # List of required programs which are probably not installed by default


# Load config file
_config_file_loaded=false
if [[ -e "$_config_file" ]] ; then
	source "$_config_file"
	_config_file_loaded=true
else
	echo "Error: Configuration file ${_config_file} not found"
fi

_supervisor_name="${sv_name}_supervisor"



# Check if required programs are installed

_all_required_programs_installed=true
for _prog in $_required_programs; do
	if ! command -v "$_prog" &> /dev/null ; then
		echo "Error: The required program ${_prog} is not installed."
		_all_required_programs_installed=false
	fi
done

# Show installation help
if [[ $_all_required_programs_installed == false ]] ; then
	echo "rkill could be installed on ubuntu with apt-get install pslist"
fi


# Show help
if [[ -z "$_cmd" || "$_cmd" == "-h" || "$_cmd" == "--h" || "$_cmd" == "help" ]] ; then
	echo "Supervisor script"
	echo "${_this_script} <command>"
	echo ""
	echo -e "<command>\t\t The command"
	echo -e "\t\t\t start    Start the supervisor and the supervised program"
	echo -e "\t\t\t stop     Stop the supervisor and the supervised program"
	echo -e "\t\t\t restart  Restart the supervisor and the supervised program"
	echo -e "\t\t\t status   Show the status of the supervisor and the supervised program"
	echo -e "\t\t\t config   Show configuration"
	
	echo ""
	echo ""
	echo "Configuration"
	echo ""
	echo "Configuration file: $_config_file"
	
	echo ""
	echo ""
	echo "Log files"
	echo ""
	echo -e "$_SV_LOG_FILE\t Supervisor"
	echo -e "$_SV_CTRL_LOG_FILE\t Supervisor control"
	
	echo ""
	echo ""
	echo "Installation"
	echo "Copy the supervisor script ${_this_script} to your project folder or to some other folder."
	echo "  Each supervisor instance currently needs its own folder. Create a configuration file $_config_file"
	echo "  in the same folder. For help, see the configuration file template. After configuration, "
	echo "  the supervisor could be started by ${_this_script} start." 
	exit
fi


if [[ $_all_required_programs_installed == false ]] ; then
	exit 1
fi

if [[ $_config_file_loaded == false ]] ; then
	exit 1
fi


log() {
	local msg="$1"
	local logfile="$2"
	if [[ ! -z "$logfile" ]] ; then
		echo "$(date -Iseconds) -- ${msg}" >> "$logfile" 
	else
		echo "$(date -Iseconds) -- ${msg}"
	fi
}


#################################################################################
# Run the program supervised
#################################################################################
if [[ "$_cmd" == "_run" ]] ; then
	_stopped=false

	_term() {
		_stopped=true
		log "Caught SIGTERM signal!" "$_SV_LOG_FILE"
		rkill -TERM "$child"
	}

	_kill() {
		_stopped=true
		log "Caught SIGKILL signal!" "$_SV_LOG_FILE"
		rkill -9 "$child"
	}

	trap _term SIGTERM
	trap _kill SIGKILL

	log "Start Supervisor." "$_SV_LOG_FILE"
	while [[ "$_stopped" != "true" ]]; do
		log "Start Program '$sv_program'" "$_SV_LOG_FILE"
		"$sv_program" &
		child=$!
		wait "$child"
		_exit_code=$?
		log "Program stopped with exit code ${_exit_code}." "$_SV_LOG_FILE"
		[[ "$_stopped" == "true" ]] && break
		log "Restart later." "$_SV_LOG_FILE"
		sleep $sv_restart_delay 
	done
	log "Stop Supervisor." "$_SV_LOG_FILE"
	
	exit 0
fi


#################################################################################
# Start 
#################################################################################
if [[ "$_cmd" == "start" ]] ; then
	pgrep -f "$_supervisor_name" && echo "Already running" && exit

	log "Start" "$_SV_CTRL_LOG_FILE"
	"$_this_script" "_run" "$_supervisor_name" >/dev/null 2>&1 & disown
	
	exit 0
fi


#################################################################################
# Stop
#################################################################################
if [[ "$_cmd" == "stop" ]] ; then

	_getPid() {
		_pid=$(pgrep -f "$_supervisor_name")
	}

	_getPid


	if [[ -z "$_pid" ]] ; then
		echo "Not running"
		exit
	fi

	log "Stop" "$_SV_CTRL_LOG_FILE"
	echo "Stopping $_pid ..."
	kill "$_pid"
	_counter=0

	while [[ ! -z "$_pid" ]]; do
		sleep 1
		_getPid
		_counter=$((_counter+1))
		if (( _counter >= 60 )); then
			break
		fi
	done

	if [[ ! -z "$_pid" ]]; then
		echo "Still running. Now kill ..."
		kill -9 "$_pid"
	fi
	
	exit 0
fi


#################################################################################
# Status
#################################################################################
if [[ "$_cmd" == "status" ]] ; then
	if [[ -z "$(pgrep -f "$_supervisor_name")" ]] ; then
		echo "Supervisor: Not running"
	else
		echo "Supervisor: Running"
	fi


	if [[ ! -z "$sv_final_program_pattern" ]] ; then
		if [[ -z "$(pgrep -f "$sv_final_program_pattern")" ]] ; then
			echo "Final program: Not running"
		else
			echo "Final program: Running"
		fi
	fi
	
	exit 0
fi


#################################################################################
# Restart
#################################################################################
if [[ "$_cmd" == "restart" ]] ; then
	log "Restart" "$_SV_CTRL_LOG_FILE"

	"$_this_script" stop
	"$_this_script" start
	
	exit 0

fi


#################################################################################
# Show config
#################################################################################
if [[ "$_cmd" == "config" ]] ; then
	cat "$_config_file"
	exit 0
fi

echo "Invalid command"
exit 1

