# ansible-freeradius
Ansible role pro instalaci FreeRADIUSu v roli IdP & SP, SP only anebo proxy pro eduroam.cz. Předpokladem úspěšného použítí je solidní znalost administrace Linuxu a alespoň základní znalost automatizované správy pomocí ansible.com.

Role podporuje *RadSec*, *Operator-Name*, *Chargeable-User-Identity*, *vynucení shody vnitřní a vnější identity*. Dále umožní neEAP ověření pouze lokálním realmům (pro captive portály, pokud je fakt musíte používat).

Předpokládám, že si roli ansible-freeradius vložíte do vlastního projektu. Pro jednoúčelové otestování stačí postupovat podle následujícího návodu. Vytvořte si libovolný adresář a proveďte:

```
git clone https://github.com/CESNET/ansible-freeradius.git roles/freeradius
mkdir -p host_vars group_vars files/certs
cp roles/freeradius/examples/playbook-freeradius.yml .
cp roles/freeradius/examples/inventory.conf .
cp roles/freeradius/examples/ansible.cfg .
cp roles/freeradius/examples/chain_TERENA_SSL_CA_3.pem files/certs/
cp roles/freeradius/examples/chain_CESNET_CA4.pem files/certs/
```
Musíte upravit soubor `inventory.conf`, aby se odkazoval na váš server. Musíte vyvořit soubor `host_vars/vas-radius.realm.cz.yml`, jako vzor použijte soboury [vysvětlivky k obsahu](./Parameters.md):
 * [semik-dev.cesnet.cz-IdPSP-PKCS12.yml](https://github.com/CESNET/ansible-freeradius/blob/master/examples/semik-dev.cesnet.cz-IdPSP-PKCS12.yml) pro IdP & SP s certifikátem ve formátu PKCS#12
 * [semik-dev.cesnet.cz-IdPSP.yml](https://github.com/CESNET/ansible-freeradius/blob/master/examples/semik-dev.cesnet.cz-IdPSP.yml) pro IdP & SP s certifikátem v běžnějším PEM formátu, uživateli v LDAPu s eduroam heslem jiným od hlavního hesla v LDAPu
 * [semik-dev.cesnet.cz-IdPSP-msAD.yml](https://github.com/CESNET/ansible-freeradius/blob/master/examples/semik-dev.cesnet.cz-IdPSP.yml) pro IdP & SP s certifikátem v běžnějším PEM formátu, uživateli v MS AD a ověřováním pomocí NTLMv1, přidání do domény musí být provedeno manuálně to ansible nedělá, viz [návod](https://www.eduroam.cz/cs/spravce/pripojovani/radius/freeradius3/windowsad).
 * [semik-dev.cesnet.cz-SP.yml](https://github.com/CESNET/ansible-freeradius/blob/master/examples/semik-dev.cesnet.cz-SP.yml) pro SP only instalaci
 * [semik-dev.cesnet.cz-proxy.yml](https://github.com/CESNET/ansible-freeradius/blob/master/examples/semik-dev.cesnet.cz-proxy.yml) proxy rezim kdy je domaci realm predavany na jiny RADIUS server

Důvěrné informace o konfiguraci serveru jsou šifrovány ve vaultu, např.:

```
ldap:
  eduroam:
    bindPass: "{{ semik_dev_cesnet_cz.ldap_passwd }}"
```

Vytvořte si `group_vars/idp_vault.yml` s následujícím obsahem, jen změňte první řádek na svůj hostname (**tečky a případné pomlčky musíte nahradit podtržítky, tzn. `semik-dev.cesnet.cz` bude `semik_dev_cesnet_cz`**):

```
semik_dev_cesnet_cz:
  ermon_secret: sdílené heslo k ermon.cesnet.cz
  ldap_passwd: heslo k LDAP uctu
  radsec_key_password: heslo k privatnimu klici pro radsec
  eap_key_password: heslo k privatnimu klici pro eap

```

Konfigurační informace jsou rozděleny do dvou souborů, aby bylo možné oddělit důvěrné informace, které stojí za šifrování pomocí ansible-vault, a ty celkem veřejné. Navíc předpokládám, že v šifrovaném souboru `group_vars/idp_vault.yml` jsou sdíleny důvěrné informace dalších serverů a případně jiných rolí.

## Certifikáty
V případě použití PKCS#12 formátu role předpokládá, že RADIUS server používá pro spojení s národním RADIUS serverem ten samý certifikát jako pro (volitelnou) roli IdP. Tento požadavek vychází ze sdílení části kódu s playbookem pro Shibboleth IdP (eduID.cz), kde je to vhodné a navíc takto šifrovaný certifikát lze uložit do veřejného GITu bez obavy ze zneužití. Soubor musí být umístěn v `files/semik-dev.cesnet.cz.p12`, resp. adekvátně pojmenovaném souboru.

FreeRADIUS používá PEM formát pro certifikáty, v takovém případě je očekává v `files/certs/hostname.{crt,key}`, lze použít různé certifikáty pro RadSec a EAP, což bude asi častý případ.

Role dále pracuje s certifikáty pro ověření důvěry LDAP serveru. Ty jsou odkazovány v `host_vars/semik-dev.cesnet.cz.yml` v proměné `ldap.CAChain`. 

Pracuje také s certifikám pro ověření nadřazeného RADIUS serveru. Ten je odkazován v `eduroam.topRADIUS.CAChain`. Role počítá s tím, že nadřazeným RADIUSem není `radius1.eduroam.cz`, ale obecný nadřazený RADIUS.


## Spuštění

```
export ANSIBLE_INVENTORY=./inventory.conf
ansible-playbook playbook-freeradius.yml 
```
