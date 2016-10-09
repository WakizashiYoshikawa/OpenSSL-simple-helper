#!/bin/bash
if [ -f openssl.cnf ]; then
    echo "Ovde izgleda sve zavrseno... odoh ja"
    exit 0
fi
echo -e "\e[1mPriprema direktorijuma i fajlova...\e[0m \c "
#kreiranje potrebnih foldera, tekst fajlova itd...
echo `mkdir certs crl newcerts private csr p12`
echo `touch serial index.txt crlnumber`
echo 01 > serial 
echo 01 > crlnumber
# upit za ime CA sertifikata
echo -e "\e[1mIme CA sertifikata bez ekstenzije(npr. ca-lilly)\e[0m \c "
read certname
# DIR promenljiva da bi napravio cnf fajl sa direktnom putanjom do foldera...meh
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# kreiranje CNF fajla koji ce se posle koristiti za kreiranje i potpisivanje ovo mora posle upita za ime CA sertifikata
# da bi se ispravno popunio openssl.cnf
cat >openssl.cnf <<EOT
#$certname.key.pem
#$certname.cert.pem
#$certname.crl.pem
#guramo ovde definicije za kasnije, linija 1 ime kljuca, linija 2 ime sertifikata, linija 3 ime CRL liste...
[ ca ]
# man ca
default_ca = CA_default

[ CA_default ]
# Directory and file locations.
dir               = $DIR
certs             = $DIR/certs
crl_dir           = $DIR/crl
new_certs_dir     = $DIR/newcerts
database          = $DIR/index.txt
serial            = $DIR/serial
RANDFILE          = $DIR/private/.rand

# The root key and root certificate.
private_key       = $DIR/private/$certname.key.pem
certificate       = $DIR/certs/$certname.cert.pem

# For certificate revocation lists.
crlnumber         = $DIR/crlnumber
crl               = $DIR/crl/$certname.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30

# SHA-1 is deprecated, so use SHA-2 instead.
default_md        = sha256

name_opt          = ca_default
cert_opt          = ca_default
default_days      = 180
preserve          = no
policy            = policy_loose

[ policy_strict ]
# The root CA should only sign intermediate certificates that match.
# See the POLICY FORMAT section of man ca.
countryName             = match
stateOrProvinceName     = match
organizationName        = match
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ policy_loose ]
# Allow the intermediate CA to sign a more diverse range of certificates.
# See the POLICY FORMAT section of the 'ca' man page.
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
# Options for the 'req' tool (man req).
default_bits        = 2048
distinguished_name  = req_distinguished_name
string_mask         = utf8only

# SHA-1 is deprecated, so use SHA-2 instead.
default_md          = sha256

# Extension to add when the -x509 option is used.
x509_extensions     = v3_ca

[ req_distinguished_name ]
# See <https://en.wikipedia.org/wiki/Certificate_signing_request>.
countryName                     = Drzava (2 slova code)
stateOrProvinceName             = Drzava puno ime
localityName                    = Grad
0.organizationName              = Firma kojoj se izdaje sertifikat (npr.Loreal Srbija)
organizationalUnitName          = Sektor firme kojoj se izdaje sertifikat (npr. IT Sektor)
commonName                      = Za klijentske Ime i Prezime, za serverske FQDN
emailAddress                    = Email Adresa

# Optionally, specify some defaults.
countryName_default             = RS
stateOrProvinceName_default     = Serbia
localityName_default            = Belgrade
0.organizationName_default      = 
organizationalUnitName_default  =
emailAddress_default            =

[ v3_ca ]
# Extensions for a typical CA (man x509v3_config).
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
 crlDistributionPoints = critical, @crl_section

[ v3_intermediate_ca ]
# Extensions for a typical intermediate CA (man x509v3_config).
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
crlDistributionPoints = critical, @crl_section

[ usr_cert ]
# Extensions for client certificates (man x509v3_config).
basicConstraints = critical, CA:FALSE
#nsCertType = client, email
#nsComment = "ZUA Lilly Client Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
#extendedKeyUsage =, emailProtection - skinuto jer necemo da potpisuju mailove našim klijentskim sertifikatom...  može se dodati novi extension usr_lilly sa omogućenom ovom opcijom
#nsCaRevocationUrl		= http://www.lilly.rs/ca-crl.pem
crlDistributionPoints	= @crl_section

[ server_cert ]
# Extensions for server certificates (man x509v3_config). Služi za potpisivanje servera
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "ZUA Lilly Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth

[ crl_ext ]
# Extension for CRLs (man x509v3_config).
authorityKeyIdentifier=keyid:always

[crl_section]
# javna adresa CRL liste (vec je definisana u Apache ssl.conf ali je praksa da stoji i ovde)
URI.0	=	https://ca.lilly.rs/$certname.crl.pem

[ ocsp ]
# Extension for OCSP signing certificates (man ocsp).
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, OCSPSigning
EOT
# Generisanje ROOT CA sertifikata
echo -e "\e[1mSertifikat zasticen lozinkom [yes / no]\e[0m \c "
read yno
case $yno in

        [yY] | [yY][Ee][Ss] )
                echo `openssl genrsa -aes256 -out private/$certname.key.pem 4096`
                echo 'Kljuc je kreiran pod imenom /private/'$certname'.key.pem'
				echo `openssl req -config openssl.cnf -key private/$certname.key.pem -new -x509 -days 7300 -sha256 -extensions v3_intermediate_ca -out certs/$certname.cert.pem`
				echo 'CA sertifikat je kreiran pod imenom /certs/'$certname'.cert.pem'
                ;;

        [nN] | [n|N][O|o] )
                echo `openssl genrsa -out private/$certname.key.pem 4096`
                echo 'Kljuc je kreiran pod imenom /private/'$certname'.key.pem'
				echo `openssl req -config openssl.cnf -key private/$certname.key.pem -new -x509 -days 7300 -sha256 -extensions v3_intermediate_ca -out certs/$certname.cert.pem`
				echo 'CA sertifikat je kreiran pod imenom /certs/'$certname'.cert.pem'
                ;;
        *) echo "Neispravan odabir"
            ;;
esac
echo "Sve zavrseno..."