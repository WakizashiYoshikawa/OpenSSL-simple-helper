#!/bin/bash
if [ ! -f openssl.cnf ]; then
    echo "Ovde nesto fali... odoh ja"
    exit 0
fi
CACRL="$(sed -n -e 3p openssl.cnf | sed 's/^.//')"
CACERT="$(sed -n -e 2p openssl.cnf | sed 's/^.//')"
echo -e "\e[1mUser cert password(ZAPISATI GA!):\e[0m \c "
read userpwd
echo -e "\e[1mIme sertifikata(bez razmaka npr. pera.peric):\e[0m \c "
read  name
if [ -f ./private/$name.key.pem ]; then
    echo "Sertifikat sa ovim imenom vec postoji. Necemo gaziti prethodne..."
    exit 0
fi
echo `openssl genrsa -aes256 -passout pass:$userpwd -out private/$name.key.pem 2048`
printf '\e[5;32;40m Generisanje CSR fajla...\e[m\n'
echo `openssl req -config openssl.cnf -key private/$name.key.pem -new -sha256 -out csr/$name.csr.pem`
#printf '\e[5;32;40m Test CSR fajla...\e[m\n'
#echo `openssl req -text -noout -verify -in csr/$name.csr.pem`
echo -e "\e[1mValidnost sertifikata u danima[180]:\e[0m \c" -n1 -s
read days
if [[ -n ${days//[0-9]/} ]]; then
    echo "SAMO BROJEVI SARANE!"
    days=180
    echo -e "\e[1mBroj dana setovan na:\e[0m \e[32m$days\e[0m \c "
elif [ -z $days ]; then 
	days=180
fi
echo `openssl ca -config openssl.cnf -extensions usr_cert -days $days -notext -md sha256 -in csr/$name.csr.pem -out certs/$name.cert.pem`
printf '\e[5;32;40m Generisanje P12 fajla...\e[m\n'
echo -e "\e[1mSertifikat sa chain fajlom [yes / no]\e[0m \c "
read yno
case $yno in

        [yY] | [yY][Ee][Ss] )
                #ovo je opcioni p12 sertifikat sa ugradjenim CA tako da nece browser izbacivati gresku u vezi sa bilo kojim sertifikatom potpisanim on strane CA
				#ali ce izbaciti ogromno upozorenje kada se klijentski sertifikat importuje
				echo `openssl pkcs12 -export -inkey private/$name.key.pem -in certs/$name.cert.pem -chain -CAfile certs/$CACERT -out p12/keba1.p12`
                ;;

        [nN] | [n|N][O|o] )
				echo `openssl pkcs12 -export -clcerts -in certs/$name.cert.pem -inkey private/$name.key.pem -out p12/$name.p12`                ;;
        *) echo "Neispravan odabir"
            ;;
esac

printf '\e[5;32;40m Generisanje CRL liste...\e[m\n'
echo `openssl ca -config openssl.cnf -gencrl -out crl/$CACRL`
echo -e 'Password koricen za kreiranje kljuca je: \e[1m'$userpwd'\e[0m\n'