#!/bin/bash
if [ ! -f openssl.cnf ]; then
    echo "Ovde nesto fali... odoh ja"
    exit 0
fi
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CACRL="$(sed -n -e 3p openssl.cnf | sed 's/^.//')"
echo -e '\e[1mSpisak sertifikata za revokaciju:\e[0m'
for file in $DIR/certs/*; do
  #echo ${file##*/}
  echo -e "\e[31m"${file##*/}
done
# silly goto implementacija :)
function goto
{
    label=$1
    cmd=$(sed -n "/$label:/{:a;n;p;ba};" $0 | grep -v ':$')
    eval "$cmd"
    exit
}
# priprema promenljivih iz openssl.cnf fajla, trazimo ime CA sertifikata, CRL listu
echo -e "\e[1mIme CRL fajla je:'$CACRL'\e[0m \c "
echo ""
echo -e "\e[1mIme sertifikata za revokaciju bez .cert.pem dela (npr. pera.peric):\e[0m \c "
read  name
PS3='Razlog: '
options=("unspecified" "keyCompromise" "CACompromise" "affiliationChanged" "superseded" "cessationOfOperation" "certificateHold" "removeFromCRL" "Izlaz")
select opt in "${options[@]}"
do
    case $opt in
        "unspecified")
            echo `openssl ca -config openssl.cnf -revoke certs/$name.cert.pem -crl_reason $opt`
            goto revoke
            ;;
        "keyCompromise")
            echo `openssl ca -config openssl.cnf -revoke certs/$name.cert.pem -crl_reason $opt`
            goto revoke
            ;;
        "CACompromise")
            echo `openssl ca -config openssl.cnf -revoke certs/$name.cert.pem -crl_reason $opt`
            goto revoke
            ;;
        "affiliationChanged")
            echo `openssl ca -config openssl.cnf -revoke certs/$name.cert.pem -crl_reason $opt`
            goto revoke
            ;;
        "superseded")
            echo `openssl ca -config openssl.cnf -revoke certs/$name.cert.pem -crl_reason $opt`
            goto revoke
            ;;
        "cessationOfOperation")
            echo `openssl ca -config openssl.cnf -revoke certs/$name.cert.pem -crl_reason $opt`
            goto revoke
            ;;
        "certificateHold")
            echo `openssl ca -config openssl.cnf -revoke certs/$name.cert.pem -crl_reason $opt`
            goto revoke
            ;;
        "removeFromCRL")
            echo `openssl ca -config openssl.cnf -revoke certs/$name.cert.pem -crl_reason $opt`
            goto revoke
            ;;
        "Izlaz")
            break
            ;;
        *) echo invalid option;;
    esac
done
revoke:
printf '\e[5;32;40m Generisanje CRL liste...\e[m\n'
echo `openssl ca -config openssl.cnf -gencrl -out crl/$CACRL`