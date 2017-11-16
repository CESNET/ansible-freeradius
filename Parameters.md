# Význam jednotlivých parametrů

Dokumentace k jednotlivým parametrům voleb z hostfailů pro roli
ansible-freeradius, podívejte se na
[příklady](https://github.com/CESNET/ansible-freeradius/tree/master/examples)
je to snad celkem samovysvětlující.

## Sekce ldap

Sekce je nutná pouze pokud je FR v roli IdP.

### ldap.URL

Adresa adresářového serveru školy ve formátu [LDAP
URL](https://www.ldap.com/ldap-urls), pokud by škola měla více serverů
tak je možné jejich použití, ale vyžádá si to změny
playbooku. FreeRADIUS by to měl
[umět](https://stackoverflow.com/questions/18060771/how-to-configure-freeradius-with-multiple-ldap-servers),
**netestováno**.

Playbook nepočítá s tím že LDAP nepoužívá šifrování (LDAPS).

### ldap.CAChain

Obsahuje název souboru ve kterém je umístěn certifikát CA, která
vydala certifikát pro LDAP server. Je nutné aby tam byla celá cesta až
ke kořeni. V případě že LDAP používá self-sign certifikát, tak se
tento asi umístí do souboru odkazovaného `ldap.CAChain`-
**netestováno**. Playbook nepočítá s tím že by certifikát serveru
vyexpiroval.

### ldap.eduroam.bindDN a ldap.eduroam.bindPass

DN a heslo LDAP uživatele který bude používán k připojení
LDAPu. Dotyčný uživatel musí mít právo číst eduroam heslo
uživatelů. Aby fungoval PEAP-MSCHAPv2 tak to heslo musí být v
**čitelné podobě**.

### ldap.peopleDN

DN od kterého se začínají hledat uživatelé. Používá se hledání
[`scope: one`](https://www.ldap.com/the-ldap-search-operation).

### ldap.attrs.uid

Atribut pomocí kterého se hledá uživatel, na LDAP serverech OpenLDAP,
389 DS, .. je to `uid` na MS AD se používá `sAMAccountName`.

### ldap.attrs.eduroamPassword

Atribut ve kterém je uloženo heslo které uživatel používá k
přihlašování k eduroamu. Předpokládá se že se jedná o jiné heslo než
je použito pro většinu ostatních služeb na škole. Aby mohlo fungovat
přihlašování pomocí PEAP-MSCHAPv2 musí toto heslo být uloženo v
nešifrované podobě a uživatel kterého RADIUS server má k dispozici
''ldap.eduroam.bindDN'' musí mít oprávnění toto heslo přečíst.

Poznámky (neimplementováno v roli):

Alternatovou by bylo použít třeba TTLS-PAP kdy lze ověřovat klasickým
LDAP bindem. Odpadne nutnost jiného hesla. Je to ale velmi náchylné ke
krádežím identit uživatelů pokud uživatel nekontroluje certifikát tak
útočník dostane heslo ihned, po sestavení tunelu jde nešifrovaně.

Ověřování pomocí
[NTLMv1](https://www.eduroam.cz/cs/spravce/pripojovani/radius/freeradius3/windowsad)
je možné ale je to starý a **dost** děravý protokol, mám dojem že něco
takového bychom neměli doporučovat.

## Sekce eduroam

Popisuje parametry FR v rámci eduroamu

### eduroam.mode

Režim zapojení serveru, možnosti jsou: `proxy`, `SP`, `IdPSP`.

### eduroam.realm 

Realmy které instituce používá. Velmi doporučuji aby to byl realm
jediný. Musí se jednat o doménu registrovanou ve veřejném DNS systému
a měla by patřit instituci.

V případě více realmů a pokud libovolný uživatel může používat oba
realmy je nezbytné zajistit že v obou případech dostane stejné
CUI. FIXME - Vašek to vyzkoumal, jen zanést do role.

Pokud se jedná o doménu mimo CZ TLD, tak je třeba
[definovat NAPTR](https://www.eduroam.cz/cs/spravce/pripojovani/realm#realmy_mimo_cz_tld) záznam jinak nebude fungovat roaming uživatelů mimo
CZ. Problém jsou veřejní registrátoři, Active24 ani DomainMaster to
nepodporují - nevím jak jsou na tom ostatní.

### eduroam.topRADIUS

Parametry nadřazeného RADIUS serveru většinou tedy národního RADIUSu. Detailněji viz některý z [příkladů](https://github.com/CESNET/ansible-freeradius/tree/master/examples), je to celkem samovysvětlující.

### eduroam.radsec a eduroam.EAP

Certifikát pro RadSec spojení a certifikát pro EAP. Může odkazovat na
ty samé soubory. Privátní klíče musí být zašifrovány.

Pokud by nebyl uveden ani jeden ze slovníků eduroam.radsec a
eduroam.EAP tak role bude očekávat existenci certifikátu v souboru
''<hostname>.pkcs12'', nedoporučuji to využívat je to pro ty situace
kdy se role freeradius využívá na tom samém serveru jako role pro
shibboleth. Tj. ten samý host slouží krom eduroam IdP i jako eduID.cz
IdP.

### eduroam.NAS

Definice parametrů WLC nebo obyčejných APček. Na názvech klíčů
NAS1/2/... nezáleží musí být jen unikátní. Sekce je volitelná, v
režimu proxy RADIUSu může být zbytečná.

### eduroam.downRADIUS

Sekce má smysl jen když je FR v roli `proxy`, detailní příklad viz [semik-dev.cesnet.cz-proxy.yml](https://github.com/CESNET/ansible-freeradius/blob/master/examples/semik-dev.cesnet.cz-proxy.yml)

## certificate_password

Heslo k certifikátu v PKCS#12 formátu, pokud je použito musí být
certifikát uložen v files/`hostname`.pkcs12 pak je použit pro EAP i
RadSec. Tohle nemá moc smysl používat, má smysl jen když spravujeme
současně eduroam a eduID.cz IdP.

