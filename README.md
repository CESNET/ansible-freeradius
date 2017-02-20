# ansible-freeradius
Ansible role pro instalaci FreeRADIUSu v roli IdP&SP, nebo jen SP pro eduroam.cz. Předpokladem úspěšného použítí je solidní znalost administrace Linuxu a alespoň základní znalost automatizované správy pomocí ansible.com.

Role podporuje RadSec, Operator-Name, Chargeable-User-Identity, vynucení shody vnitřní a vnější identity. Dále umožní neEAP ověření pouze lokálním realmům (pro captive portály, pokud je fakt musíte používat).

Předpokládám, že si roli ansible-freeradius vložíte do vlastního projektu. Pro jednoúčelové otestování stačí postupovat podle následujícího návodu. Vytvořte si libovolný adresář a proveďte:

```
git clone https://github.com/CESNET/ansible-freeradius.git roles/freeradius
mkdir -p host_vars group_vars files/certs
cp roles/freeradius/examples/semik-dev.cesnet.cz.yml host_vars/
cp roles/freeradius/examples/playbook-freeradius.yml .
cp roles/freeradius/examples/inventory.conf .
cp roles/freeradius/examples/ansible.cfg .
cp roles/freeradius/examples/chain_TERENA_SSL_CA_3.pem files/certs/
cp roles/freeradius/examples/chain_CESNET_CA3.pem files/certs/
export ANSIBLE_INVENTORY=./inventory.conf

```
Server na kterém roli testuji se jmenuje `semik-dev.cesnet.cz`. Vy musíte zeditovat soubor `inventory.conf` a by se odkazoval na váš server. Dále musíte přejmenovat soubor `host_vars/semik-dev.cesnet.cz.yml` podle vašeho serveru a následně nahradit v dotyčném souboru odkazy na `semik_dev_cesnet_cz`. Dále vytvořte soubor `group_vault/idp_vault.yml` s následujícím obsahem:

```
semik_dev_cesnet_cz:
  p12pswd: heslo k p12 certifikátu
  ermon_secret: sdílené heslo k ermon.cesnet.cz
  ldap_passwd: heslo k LDAP uctu
  NAS:
    192.168.1.1:
      ipaddr: 192.168.1.1
      secret: random-secret
      shortname: WLC1
    192.168.1.2:
      ipaddr: 192.168.1.2
      secret: random-secret2
      shortname: WLC2
    192.168.1.3:
      ipaddr: 192.168.2.1/24
      secret: random-secret3
      shortname: AP_oldbuilding

```

Konfigurační informace jsou rozděleny do dvou soubrů aby bylo možné oddělit důvěrné informace které stojí za šifrování pomocí ansible-vault a ty celkem veřejné. Dále předpokládám že v šifrovaném souboru `group_vault/idp_vault.yml` jsou sdíleny důvěrné informace dalších serverů a případně jiných rolí.

## Certifikáty
Role poředpokládá že RADIUS server používá pro spojení s národním RADIUS serverem ten samý certifikát jako pro (volitelnou) roli IdP. Certifikát musí být ve formátu PKCS#12, tento požadavek vychází z toho že sdílíme části kódu s playbookem pro Shibboleth (eduID.cz) a tam se to vyplatí, navíc takto šifrovaný certifikát lze uložit do veřejného GITu bez obavy z neužití. Soubor musí být umístěn v `files/semik-dev.cesnet.cz.p12` resp. adekvátně pojmenovaném souboru. Převody mezi PEM a PKCS#12 formátem ponechávám za domácí úkol.

Role dále pracuje s certifikáty pro ověření důvěry LDAP serveru, ty jsou odkazovány v `host_vars/semik-dev.cesnet.cz.yml` v proměné `ldap.CAChain`. A certifikám pro ověření nadřazeného RADIUS serveru. Ten je odkazován v `eduroam.topRADIUS.CAChain`. Role počítá s tím že nadřazeným RADIUSem není radius1.eduroam.cz ale obecný nadřazený RADIUS.
