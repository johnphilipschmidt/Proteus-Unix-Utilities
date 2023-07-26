#!/bin/bash
# JP Schmidt Jan 2019
# version: 1.1.20190107_1100
# Description:
#      Application Admin Script to allow Application Admins to perform various admin functions in a controlled
#      environment.
# Installation: root user should add the file in /usr/local/bin on an app server connecting to a formDoc microservice
# admin endpoint.
#  The permissions should 755 chmod 755;chown root:root
#  The user should /usr/local/bin in their path
# Parameters data file, full servername, webserviceuser password

main() {
LOG="${HOME}/adminclose_$USER_`date +%Y%m%d`.log"

while true
do
    #clear the screen
        printf "\033c"
        echo; echo;echo
        echo "          ------------Welcome $USER to the formDoc Admin Screen------------------"
        echo "     Logging to: $LOG                  "
        echo " Options:"
        echo "          1. Batch close formDoc's using a File                                  "
        echo "          2. View todays log                                                   "
        echo "          3. Edit a file                                                   "
        echo "          q. Quit                                                              "
        echo "          i. Instructions                                                      "
        echo -n "Select an Option:"
        read option
        echo
        case $option in
        "1" )
                closeformDoc $LOG
                echo -n "press enter to continue"
                read a
        ;;
        "2" )
                tail -100 $LOG
                echo
                echo -n "Press enter to continue"
                read a
        ;;
        "3" )
                echo -n "Enter the path and filename to edit:"
                read FILE
                vi $FILE
                echo
                echo -n "Press enter to continue"
                read a
        ;;

        "q")
                exit 0
        ;;

        "i")
                provideInstruction formDoc
                echo -n "press enter to continue"
                read a
        ;;
        esac
done
}


#README SECTION
provideInstruction(){
        if [ $1 == "formDoc" ]
        then
            printf " ******************formDoc Instructions***********************************\n"
            printf "    This feature allows for the closing several formDoc's using a file and curl.\n\n"
            printf " If the formDoc was closed it will not be processed again.\n\n"
            printf " Parameters that you must enter:\n"
            printf "    FILE: Please create a file that has only on formDocid per line- no delimiters\n"
            printf "       The default file is $HOME/formDocclose.dat\n\n"
            printf "    SERVER:Please enter the SERVERNAME where this will be executed.\n"
            printf "      It should be the server you are on:$HOSTNAME\n\n"
            printf "    PASSWORD: The webserviceuser password to access the formDocadminclose endpoint.\n\n"
            printf " Miscellaneous:\n"
            printf "      Logs are located in $LOG\n"
            printf "      The script is located in /usr/local/bin\n"
            printf " Have a nice day...\n"
        fi

}



#Wrapper to call processfile performs validation and paramter collection
closeFormDoc(){

        LOG=$1
        echo -n "Enter webserviceuser password:"
        PW=$(getServicePassword)
        if [ ${#PW} -lt 3 ]
        then
                printf "Error: PASSWORD too short to be valid!\n"
                return 1
        fi

        echo

        echo -n "Enter SERVERNAME  ${HOSTNAME}>:"
        SERVER=$(getServer)
        echo

        echo -n "Enter DIRECTORY and FILENAME(default is $HOME/formDocclose.dat):"
        FILENAME=$(getFile)

        isValid=$(validateformDocFile $FILENAME)


        if [ "$isValid" == "-1" ]
        then
                printf "Adminclose Error: File is invalid: One formDoc per line no delimters\n"
        fi

        if [ "$isValid" == "-2" ]
        then
                printf "Adminclose Error: File missing\n"
        fi

        #Valid if validate returns with 0, the PW is > 3, the SERVER NAME is not empty
        if [ "$isValid" = "0" ] && [ ${#PW} -gt 3  ] && [ -n "$SERVER" ]
        then
                processFile $FILENAME $PW $SERVER $LOG
        else
                printf "Parameters invalid"
        fi
}


# Processes the file after validation
processFile(){
        #SERVER=vredtssasa03.tactsc.com
        local FILENAME=$1
        local PW=$2
        local SERVER=$3
        local LOG=$4
        for   formDocid in `cat ${FILENAME}`
        do
                printf "Processing $formDocid Time:`date +%H%M%S`\n"
                printf "`date +%Y%m%d:%H%M%S`-$USER:$formDocid\n"  >>$LOG
 /usr/bin/curl -u webserviceuser:${PW} -k  -X PUT --header "Content-Type: application/json" --header "Accept:application/json" "https://${SERVER}:31700/formDocSvc/api/v1/docs/admin/adminExternalCloseformDoc/$formDocid/${USER}" >> $LOG 2<&1
        printf "\n" >>$LOG
        done

}
#Crude validator for the file
validateFormDocFile(){
        local retval="-1"
        if [ -f $1 ]
        then
                wordcount=`wc -w $1`
                linecount=`wc -l $1`
                if [ "$wordcount" == "$linecount" ]
                then
                #strip spaces
                    cat $1|sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' >/tmp/$$tmp
                    retval="0"
                else
                        retval="-1"
                fi
        else
                retval="-2"
        fi
        echo $retval


}

#Gets input from user for PASSWORD
 getServicePassword(){
        local paswd
        read a
        paswd=$a
        echo $paswd
}

#Gets user input for FILE
 getFile(){
        local filename=""
        read a
        local filename=$a
        if [ -z $filename ]
        then
                filename="$HOME/formDocclose.dat"
        fi
        echo $filename
}


#Gets user input for the server
 getServer(){
        local servername=""
        read a
        local servername=$a
        if [ -z $servername ]
        then
                servername="vredassa03.tactsc.com"
        fi
        echo $servername
}


# runs the whole shabang....
 main
