#! /bin/bash

nb=32768
alea=$RANDOM

while [ "$nb" -ne $alea ];
	do echo -n "devinez ?";
	read nb
if [ "$nb" -lt $alea ];
then echo -n "c'est plus grand !";
elif [ "$nb" -gt $alea ];
then echo -n "c'est plus petit !";
fi
done
echo -n "Bien joué ! Vous avez trouvé !"
exit 0