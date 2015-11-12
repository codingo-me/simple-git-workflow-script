#!/bin/bash
clear

#take path of public folder and create it
echo "Please enter ABSOLUTE PATH of web server public folder for this project, that will be your publicly visible web folder (for Apache /var/www/html/...)"
read webFolderPath
while true; do
    read -p "You entered: $webFolderPath is that correct path? y/n?" yn
    case $yn in
        [Yy]* ) mkdir -p $webFolderPath; break;;
        [Nn]* ) echo "Script stopped"; exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

#cd into public folder and initialize git there
cd $webFolderPath; git init;

#take path of bare git repository and create it
echo "Please enter ABSOLUTE PATH of bare git repo, that will be you main entry point for pushing/pulling to remote server, one that ends with .git: "
read gitBareRepo
while true; do
    read -p "You entered: $gitBareRepo is that correct path? y/n?" yn
    case $yn in
        [Yy]* ) mkdir -p $gitBareRepo; break;;
        [Nn]* ) echo "Script stopped"; exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

#cd into git bare repository and initialize bare repository there
cd $gitBareRepo; git init --bare;

#define bare repository as hub of public folder
cat <<EOT > $webFolderPath"/.git/config"
[remote "hub"]
url = $gitBareRepo
fetch = +refs/heads/*:refs/remotes/hub/*
EOT

#create post-update hook in git bare repository, for syncing files with public folder
cat <<EOT > $gitBareRepo"/hooks/post-update"
#!/bin/sh
echo
echo "**** Pulling changes into Live [Hub's post-update hook]"
echo
cd $webFolderPath || exit
unset GIT_DIR
git pull hub master
exec git-update-server-info
EOT

#create post-commit to sync back with bare repository,
#if you decide to change something directly from public folder
cat <<EOT > $webFolderPath"/.git/hooks/post-commit"
#!/bin/sh
echo
echo "**** pushing changes to Hub [Live's post-commit hook]"
echo
git push hub
EOT

#take username that will use this repository
echo -e "Please enter server username of user that will be using this repository: \c "
read username

#add execute permission to 2 hooks
sudo chmod +x $webFolderPath"/.git/hooks/post-commit";
sudo chmod +x $gitBareRepo"/hooks/post-update";

#customize ownership over files
sudo chown -R $username $webFolderPath;
sudo chown -R $username $gitBareRepo;