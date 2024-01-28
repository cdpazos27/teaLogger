#!/bin/bash

# ===================================================
# Date: 20230126
# Title: CSV Time logger
# Description: Logs time into a CSV File
# Parameters:
#	1) Timesheet file (relative or full path)
# ===================================================
# Modify Date: -
# ===================================================

# Function to convert date to timestamp
GetDate() {
    echo "$(date '+%Y-%m-%d %H:%M:%S')"
}

GetDateFormatted() {
    local dateToFormat=$1
    echo "$(date -d "$dateToFormat" +"%Y-%m-%d %H:%M")"
}

date_to_timestamp() {
    date -d "$1" +"%s"
}

# Function to calculate hours between two timestamps
calculate_hours() {
    local start_timestamp=$(date_to_timestamp "$1")
    local end_timestamp=$(date_to_timestamp "$2")

    local seconds_diff=$((end_timestamp - start_timestamp))
    local hours_diff=$(echo "scale=2; $seconds_diff / 3600" | bc)

    echo "$hours_diff"
}

replace_string() {
    local text="$1"
    local rep="$2"
    local by="$3"
    
    # Use parameter expansion to perform the replacement
    result="${text//$rep/$by}"
    
    echo "$result"
}

display_task_information() {
    local TaskName="$1"
    local TaskWorkItem="$2"
    local TaskStartDate="$3"
    local CurrentDttm=$(date +"%Y-%m-%d %H:%M:%S")
    local Hours=$(calculate_hours "$TaskStartDate" "$CurrentDttm")

    echo "$bar"
    echo "Current Task: $TaskName"
    echo "Work Item: $TaskWorkItem"
    echo "Date: $TaskStartDate"
    echo "Current hours working: $Hours"
    echo "$bar"
}

confirm_prompt() {
    local PromptText="$1"
    local DefaultPromptText="Are you sure? (Y/n): "

    if [ -z "$PromptText" ] ; then
        PromptText="$DefaultPromptText"
    fi
    
    local confirmSelection=0
    local confirmValue=0
    while [ "$confirmSelection" -eq 0 ] ; do
        echo "$text"
        read -p "$PromptText " pConfirmInput
        case $pConfirmInput in
            1|Y|y)
                confirmSelection=1
                confirmValue=1
            ;;
            0|N|n)
                confirmSelection=1
                confirmValue=0
            ;;
            *)
                echo "Invalid option..."
        esac
    done
    echo "$confirmValue"
}

OldPS1="$PS1"
PS1="tldrTasker> "


FilePath=$1 # This path will replace $DefaultFilePath if entered
DefaultFilePath="TimeSheet.csv"

if [ -z $FilePath ] ; then
    FilePath=$DefaultFilePath
fi

DefaultSeparator="|"
DefaultFileHeader="Task Name${DefaultSeparator}Task Item${DefaultSeparator}Hours Logged${DefaultSeparator}Start Date${DefaultSeparator}End Date"
TaskName=""
TaskWorkItem=""
TaskStartDttm=""
TaskEndDttm=""
TaskStatusId="NONE"

text=""
bar="==================================================="
echo "$text"

ExitCommand=0
while [ $ExitCommand -eq 0 ] ; do
    echo "$bar"
    echo "It is $(GetDate)"
    echo "Commands: "
    echo "1) Start new task"
    echo "2) End current task"
    echo "3) Cancel task"
    echo "4) Show status"
    echo "5) Edit current task"
    echo "6) Exit"
    echo "$bar"
    read -p "Enter your action (1-6): " choice
    
    case $choice in
        1)
            # ===================================================
            # New Task option
            # ===================================================
            echo "$text"
            case $TaskStatusId in
                "ACTIVE")
                    echo "There is a task in progress! Please, finish that one before."
                ;;
                "NONE")
                    inputValid=0
                    while [ "$inputValid" -eq 0 ]; do
                        echo "Creating new task..."
                        read -p "Enter task name: " pTaskNameInput
                        read -p "Enter task work item: " pTaskWorkItemInput
                        echo "$text"
                        inputValid=1
                        
                        if [ -z "$pTaskNameInput" ] ; then
                            inputValid=0
                            echo "Task name can't be empty..."
                        fi
                        
                        if [ -z "$pTaskWorkItemInput" ] ; then
                            inputValid=0
                            echo "Task work item can't be empty..."
                        fi
                        echo "$text"
                    done
                    TaskName="$pTaskNameInput"
                    TaskWorkItem="$pTaskWorkItemInput"
                    TaskStartDttm="$(date +"%Y-%m-%d %H:%M:%S")"
                    TaskStatusId="ACTIVE"
                    echo "Work item [${TaskName}] for [${TaskWorkItem}] started at [${TaskStartDttm}]. Good Luck!"
                ;;
                *)  ;;
            esac
            echo "$text"
            echo "Please, press any key to continue."
            read 
            ;;
        2)
            echo "$text"
            case $TaskStatusId in
                "NONE")
                    echo "There is no active task right now!"
                ;;
                "ACTIVE")
                    display_task_information $TaskName $TaskWorkItem $TaskStartDttm
                    FinishTaskConfirmation=$(confirm_prompt "Finish task [${TaskName}]? (y/N): ")
                    
                    if [ "$FinishTaskConfirmation" -eq 0 ] ; then
                        echo "Resuming task, you can do it!"
                    fi

                    echo "$text"
                    if [ "$FinishTaskConfirmation" -eq 1 ] ; then
                        echo "Finishing task..."
                        CurrentDate=$(GetDate)
                        # Format Dates for the Output row
                        TaskEndDttm="$(GetDateFormatted "$CurrentDate")"
                        TaskStartDttm="$(GetDateFormatted "$TaskStartDttm")"
                        TaskDuration=$(calculate_hours "$TaskStartDttm" "$CurrentDate")
                        
                        ResultRow="${TaskName}|${TaskWorkItem}|${TaskDuration}|${TaskStartDttm}|${TaskEndDttm}"
                        
                        FileExists=$( [ -e "$FilePath" ] && echo 1 || echo 0 )
                        
                        if [ "$FileExists" -eq 1 ] ; then
                            
                            readarray -t -n 1 FirstRow < "$FilePath"
                            
                            if [ "$DefaultFileHeader" = "$FirstRow" ] ; then
                                # Header's format is okay, add new row
                                echo "$ResultRow" >> "$FilePath"
                            fi
                            
                            if [ -z "$FirstRow" ] ; then
                                echo "The file $FilePath is empty, adding a header to the file"
                                
                                echo "$DefaultFileHeader" >> "$FilePath"
                                echo "$ResultRow" >> "$FilePath"
                            fi
                            
                            elif [ "$FileExists" -eq 0 ] ; then
                            echo "No file in ${FilePath}, creating a new file with headers"
                            
                            echo  "$DefaultFileHeader" >> "$FilePath"
                            echo  "$ResultRow" >> "$FilePath"
                        fi
                        
                        echo "Task logged succesfully! Please, get some rest."
                        # Reverting task data to empty
                        TaskName=""
                        TaskWorkItem=""
                        TaskStartDttm=""
                        TaskEndDttm=""
                        TaskStatusId="NONE"
                        
                        
                    fi
                    echo "$text"
                ;;
                *)  ;;
            esac
            ;;
        3)
            echo "Cancel Task"
            case $TaskStatusId in
                "NONE")
                    echo "$bar"
                    echo "There are no active tasks to be cancelled..."
                    echo "$bar"
                    ;;
                "ACTIVE")
                    display_task_information "$TaskName" "$TaskWorkItem" "$TaskStartDttm"
                    cancelConfirm=$(confirm_prompt "Are you sure you want to cancel [${TaskName}]? (y/N): ")

                    if [ $cancelConfirm -eq 1 ] ; then
                        TaskName=""
                        TaskWorkItem=""
                        TaskStartDttm=""
                        TaskEndDttm=""
                        TaskStatusId="NONE"
                        echo "Task cancelled. Good job!"
                    else
                        echo "Resuming current task. Never give up!"
                    fi
                    ;;
                *)
                    ;;
            esac
            echo "Please, press any key to continue..."
            read 
            ;;
        4)
            echo "$bar"
            echo "Showing Timesheet Status"
            case $TaskStatusId in
                "ACTIVE")
                    display_task_information "$TaskName" "$TaskWorkItem" "$TaskStartDttm"
                ;;
                "NONE")
                    echo "$bar"
                    echo "There are no active tasks."
                    echo "$bar"
                ;;
                *)  ;;
            esac
            echo "Last tasks logged in $FilePath"
            echo "$bar"
            { head -n 1 "${FilePath}"; tail -n 5 "${FilePath}"; } | tr '|' '\t' | column -t -s $'\t'
            echo "$bar"
            echo "Please, press any key to return to the main menu."
            read 
            ;;
        5)
            echo "Option in development!"
            ;;
        6)
            echo "Exiting the menu. Goodbye!"
            ExitCommand=1
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
done

PS1="$OldPS1"

exit 0

# Check if the file exists
# if [ -e "$file_path" ]; then
#     source "./${file_path}"
# else
#     echo "File not found: $file_path"
# fi
# echo "$currentTask"
