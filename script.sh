#!/bin/bash

if [ -z $1 ]; then
    echo "Aide: Voici les options possibles:
---------------------------------------
-f permet de préciser l'emplacement du fichier à utiliser, si l'option n'est pas utilisée, le script utilise le fichier /home/user/listing.txt
-d permet de choisir un autre séparateur que le ;
-a permet d'ajouter de nouveaux user/group/password au fichier listing.txt
-e le script crée les utilisateurs sur le système"
    exit 0
fi

while getopts ":f:d:a:e:" opts; do
    case $opts in
        f)  echo "Le nouveau fichier à utiliser est $OPTARG"
            arg1="$OPTARG"
        ;;
        d)  echo "Le nouveau séparateur de value est de $OPTARG"
            arg2="$OPTARG"
        ;;
        : )
            case $OPTARG in
                a) addUserToFile=true
                ;;
                e) addUserToSystem=true
                ;;
                *) echo "L'option -$OPTARG requiert un argument."
                   exit 1
                ;;
            esac
        ;;
        \?) echo "L'option -$OPTARG n'existe pas."
            exit 2
        ;;
    esac
done

fileName=${arg1:-listing.txt}
separator=${arg2:-;}

if [ ! -f $fileName ]; then
    echo "Le fichier $fileName n'existe pas !"
    exit 1
fi

if [ "$addUserToFile" = true ] ; then
    echo -en "\nAjout d'un nouvel utilisateur dans le fichier $fileName :
-------------------------------------\n"
    userAlreadyExist=true
    while [ $userAlreadyExist = true ]; do
        echo -n "login : "
        read login
        echo -n "groupe : "
        read group
        echo -n "password : "
        read -s password
        echo ""
        while read p; do
            username=$(echo "$p" | cut -d"$separator" -f 1)
            if [ $username = $login ]; then
                echo "L'utilisateur existe déjà"
                userAlreadyExist=true
                break
            else
                userAlreadyExist=false
            fi
        done <./$fileName
    done
    echo -en "$login$separator$group$separator$password\n" >> ./$fileName
fi

if [ "$addUserToSystem" = true ] ; then
    echo -en "\nCréation des utilisateurs sur le système
-------------------------\n"
    while read p; do
        username=$(echo "$p" | cut -d"$separator" -f 1)
        group=$(echo "$p" | cut -d"$separator" -f 2)
        password=$(echo "$p" | cut -d"$separator" -f 3)
        if grep -q $group /etc/group; then
            echo "Le groupe $group existe déjà."
        else
            echo "Création du groupe $group."
            groupadd $group
        fi
        if grep -q $username /etc/passwd; then
            echo "L'utilisateur $username existe déjà."
        else
            echo "Création de l'utilisateur $username."
            useradd -m -g $group $username
            echo ""$username":"$password"" | chpasswd
        fi
        echo "$username$separator$group$separator$password"
    done <./$fileName
fi

echo -en "\nAffichage du fichier $fileName
-------------------------\n"

cat ./$fileName

echo -en "\nExécution du script terminée.\n"