Supervisor shell script that starts a program, monitors it and, if necessary, restarts it if it crashes.
  
    Usage:
    
      ./supervisor.sh <command>
    
    Commands:
      start       Start the supervisor and the supervised program
      stop        Stop the supervisor and the supervised program
      restart     Restart the supervisor and the supervised program
      status      Show the status of the supervisor and the supervised program
      config      Show configuration

### Configuration

Create a file config-supervisor.conf in the same folder of the supervisor script.

Example configuration:

    sv_name=gnome_mines                         # A name of the service, which can be chosen arbitrarily
    sv_program=gnome-mines                      # The program that is being executed
    sv_final_program_pattern=gnome-mines        # Optional pattern to find the program in the process list. In simple cases identical to sv_program.
    sv_restart_delay=10                         # Pause between program restarts in seconds
