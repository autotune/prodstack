#!/bin/bash
# recommended - 8 GB controller node
printf "This script will install OpenStack or a service for an OpenStack node  \n\n" 

case "$1" in
        verify)
 	    /bin/bash ./verify.sh
	    printf "\n"
            ;;
         
        install)
            printf "install\n"
            ;;
	add_identity)
            printf "under development\n"
            ;; 
        *)
            printf $"Usage: $0 { \n\nverify \nconfigure \ninstall \naction_service (add/delete_compute) \$IP (127.0.0.1) }\n\n"
	    exit 1
esac
