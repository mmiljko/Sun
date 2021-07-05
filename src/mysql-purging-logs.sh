#!/bin/bash

# Name: mysql-purging-logs.sh
# Version: 0.1

# Mysql Path
MYSQL="$(which mysql)"  

Help()
{
   # Display Help
   echo "Usage: mysql-purging-logs.sh [-l|-t <'YYYY-MM-DD hh:mm:ss'>|-b <binlogfile>]"
   echo "Options:"
   echo "-l                 Show binlog files."
   echo "-t <timestamp>     Purge binary logs before <timestamp>."
   echo "-b <binlogfile>    Purge binary logs to <binlogfile>."
   
}

GetArguments()
{
   OPTIND=1
   while getopts ":lt:b:" option; do
      case ${option} in
         l) 
            CMD=l
            return 0
            ;;
         t) 
            TIMESTAMP=${OPTARG}
            if [ "z$TIMESTAMP" == "z" ] ; then
               echo "No timestamp specified for ${option} option."
               Help
               exit 1
            fi

            if ! [[ "$TIMESTAMP" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}.?[0-9]{2}:[0-9]{2}:[0-9]{2}$ ]] ; then
               echo "Expected 'YYYY-MM-DD HH:MM:SS' timestamp format."
               exit 1
            fi

            if ! date -d "$TIMESTAMP"  > /dev/null ; then
               exit 1
            fi

            return 0
            ;;
         b) 
            BINLOGFILE=${OPTARG}
            if [ "z$BINLOGFILE" == "z" ] ; then
               echo "No binary log specified for ${option} option. "
               Help
               exit 1
            fi

            return 0
            ;;
         :)  # Nije proslijeden argument
            echo "Please provide an argument for -${OPTARG} option."
            exit 1
            ;;
         \?) 
            # Nepostojeca opcija
            echo "There is no -${OPTARG} option."
            Help
            exit 1;;
      esac
   done
   shift $((OPTIND -1))
}

ExecuteOnDB ()
{
   if GetArguments ; then
      if [ "$CMD" == "l" ] ; then
         $MYSQL -e "SHOW BINARY LOGS;"
         if [[ $? -ne 0 ]] ; then
            echo "ERROR"
            exit 1
         fi
         exit 0
      fi
      
      if ! [ -z "$TIMESTAMP" ]; then
         $MYSQL -e "PURGE BINARY LOGS BEFORE '$TIMESTAMP';"
         if [[ $? -ne 0 ]] ; then
            echo "ERROR"
            exit 1
         fi
         exit 0
      fi

      if ! [ -z "$BINLOGFILE" ] ; then
         $MYSQL -e "PURGE BINARY LOGS TO '$BINLOGFILE';"
         if [[ $? -ne 0 ]] ; then
            exit 1
         fi
         exit 0
      fi
   fi
}

GetArguments "$@"
ExecuteOnDB



