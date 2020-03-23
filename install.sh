# //TODO: delete user named pi


############################## HELPER FUNCTIONS ####################################
# source: https://misc.flogisoft.com/bash/tip_colors_and_formatting
# source2: https://gist.github.com/daytonn/8677243
RED='\033[0;31m'
PURPLE="\033[0;35m"
GREEN="\033[0;32m"
NC='\033[0m'
# Print purple
function echo_n {
    echo -e "${PURPLE}${1}${NC}"
}

function echo_g {
    echo -e "${GREEN}${1}${NC}"
}

function render_template {
  eval "echo \"$(cat $1)\""
}

############################## SYSTEM UPDATE ####################################
# Update package list
echo_n "updating package list"
apt-get update -y

# // upgrade
echo_n "upgrading packages"
apt-get upgrade -y
#echo_n "dist-upgrade"
#apt-get -y dist-upgrade


echo_n "Installing apt-transport-https"
apt-get install -y apt-transport-https

############################# SET ADMIN & ROOT PASSWORD ####################

apt-get install -y diceware

ADMIN_PASSWORD="$(diceware -n 6 -w en_eff)"
ROOT_PASSWORD="$(diceware -n 6 -w en_eff)"


# change root password
echo pi:"${ROOT_PASSWORD}" | chpasswd
echo root:"${ROOT_PASSWORD}" | chpasswd
#echo admin:"${ADMIN_PASSWORD}" | chpasswd

# allow ssh login for root
sed -i '/PermitRootLogin/c\PermitRootLogin yes' /etc/ssh/sshd_config



############################## INSTALL YUNOHOST #################################
#echo "Install YunoHost"
#apt-get install -y wget
#bash <(wget -q -O- https://install.yunohost.org/stretch) -f -a


############################## HIDDEN SERVICE CONFIGURATION ####################################
# Tor installation & hidden service creation
echo_n "Installing tor..."
apt-get install -y tor
systemctl enable tor

echo_n "Creating hidden service for ssh access..."
echo '# Hidden service for ssh' >> /etc/tor/torrc
echo 'HiddenServiceDir  /var/lib/tor/hidden_service_ssh/' >> /etc/tor/torrc
echo 'HiddenServicePort 22 127.0.0.1:22' >> /etc/tor/torrc

echo_n "Creating default hidden service for YunoHide..."
echo '# Default hidden service for YunoHide' >> /etc/tor/torrc
echo 'HiddenServiceDir  /var/lib/tor/hidden_service_default/' >> /etc/tor/torrc
echo 'HiddenServicePort 80 127.0.0.1:80' >> /etc/tor/torrc
echo 'HiddenServicePort 443 127.0.0.1:443' >> /etc/tor/torrc

# Email Ports
echo 'HiddenServicePort 25 127.0.0.1:25' >> /etc/tor/torrc
echo 'HiddenServicePort 465 127.0.0.1:465' >> /etc/tor/torrc
echo 'HiddenServicePort 587 127.0.0.1:587' >> /etc/tor/torrc
echo 'HiddenServicePort 993 127.0.0.1:993' >> /etc/tor/torrc

# XMPP Ports
echo 'HiddenServicePort 5222 127.0.0.1:5222' >> /etc/tor/torrc
echo 'HiddenServicePort 5269 127.0.0.1:5269' >> /etc/tor/torrc


echo_n "Restarting tor..."
systemctl restart tor
echo_n "waiting for tor to generate hidden services(60s)"
sleep 60

hidden_service_ssh="$(cat /var/lib/tor/hidden_service_ssh/hostname)"
hidden_service_default="$(cat /var/lib/tor/hidden_service_default/hostname)"
main_domain="$(cat /var/lib/tor/hidden_service_default/hostname)"



############################## YUNOHOST POSTINSTALL ####################################
echo_n "Starting YunoHost post-install..."
yunohost tools postinstall -d "$hidden_service_default" -p "$ADMIN_PASSWORD" --ignore-dyndns --force-password

############################## FIREWALL UPDATE ####################################
# update firewall settings
echo_n "Updating firewall rules..."
echo_n "Updating firewall rules: IPv4+TCP"
#yunohost firewall disallow TCP 22 --ipv4-only --no-reload
yunohost firewall disallow TCP 25 --ipv4-only --no-reload
yunohost firewall disallow TCP 53 --ipv4-only --no-reload
yunohost firewall disallow TCP 80 --ipv4-only --no-reload
yunohost firewall disallow TCP 443 --ipv4-only --no-reload
yunohost firewall disallow TCP 465 --ipv4-only --no-reload
yunohost firewall disallow TCP 587 --ipv4-only --no-reload
yunohost firewall disallow TCP 993 --ipv4-only --no-reload
yunohost firewall disallow TCP 5222 --ipv4-only --no-reload
yunohost firewall disallow TCP 5269 --ipv4-only --no-reload

echo_n "Updating firewall rules: IPv6+TCP"
#yunohost firewall disallow TCP 22 --ipv6-only --no-reload
yunohost firewall disallow TCP 25 --ipv6-only --no-reload
yunohost firewall disallow TCP 53 --ipv6-only --no-reload
yunohost firewall disallow TCP 80 --ipv6-only --no-reload
yunohost firewall disallow TCP 443 --ipv6-only --no-reload
yunohost firewall disallow TCP 465 --ipv6-only --no-reload
yunohost firewall disallow TCP 587 --ipv6-only --no-reload
yunohost firewall disallow TCP 993 --ipv6-only --no-reload
yunohost firewall disallow TCP 5222 --ipv6-only --no-reload
yunohost firewall disallow TCP 5269 --ipv6-only --no-reload

echo_n "Updating firewall rules: pnpp+TCP"
#yunohost firewall disallow TCP 22 --pnpp-only --no-reload
yunohost firewall disallow TCP 25 --upnp-only --no-reload
yunohost firewall disallow TCP 53 --upnp-only --no-reload
yunohost firewall disallow TCP 80 --upnp-only --no-reload
yunohost firewall disallow TCP 443 --upnp-only --no-reload
yunohost firewall disallow TCP 465 --upnp-only --no-reload
yunohost firewall disallow TCP 587 --upnp-only --no-reload
yunohost firewall disallow TCP 993 --upnp-only --no-reload
yunohost firewall disallow TCP 5222 --upnp-only --no-reload
yunohost firewall disallow TCP 5269 --upnp-only --no-reload

echo_n "Updating firewall rules: IPv4+UDP"
yunohost firewall disallow UDP 53 --ipv4-only --no-reload
yunohost firewall disallow UDP 5353 --ipv4-only --no-reload

echo_n "Updating firewall rules: IPv6+UDP"
yunohost firewall disallow UDP 53 --ipv6-only --no-reload
yunohost firewall disallow UDP 5353 --ipv6-only --no-reload

echo_n "Updating firewall rules: upnp+UDP"
yunohost firewall disallow UDP 53 --upnp-only --no-reload
yunohost firewall disallow UDP 5353 --upnp-only --no-reload

echo_n "Reloading firewall configuration"
yunohost firewall reload

# use own service configuration
wget https://github.com/LiberaCore/yunohide/raw/master/templates/yunohost.conf
cp ./yunohost.conf /etc/yunohost/yunohost.conf
# configure xmpp-server for hidden services only
# source: https://gist.github.com/xnyhps/33f7de50cf91a70acf93
apt-get install -y liblua5.1-bitop0 liblua5.1-bitop-dev lua-bitop
apt-get install -y mercurial
cd /usr/lib/metronome/
hg clone https://hg.prosody.im/prosody-modules/ modules


# configure mailserver for internal use
# source: https://serverfault.com/a/117597
apt-get install -y tor-socks


echo -e '\nsmtpd_recipient_restrictions =
  hash:/etc/postfix/recipient_access,
  reject' >> /etc/postfix/main.cf
echo "$main_domain    OK" >> /etc/postfix/recipient_access
postmap /etc/postfix/recipient_access
postfix reload

# retrieve variables
domain_list=$(yunohost domain list --output-as plain --quiet)
# source for paths: https://moncoindu.net/wiki/doku.php?id=yunohost-metronome#configuration_de_metronome
# /etc/metronome/metronome.cfg.lua
# /etc/metronome/conf.d/domaine.tld.cfg.lua
metronome_conf_dir =  '/etc/metronome/conf.d'
wget https://raw.githubusercontent.com/LiberaCore/yunohide/master/templates/domain.tpl.cfg.lua

for domain in $domain_list; do
    cat ./domain.tpl.cfg.lua \
      | sed "s/{{ domain }}/${domain}/g" \
      > "${metronome_conf_dir}/${domain}.cfg.lua"
done

wget https://raw.githubusercontent.com/LiberaCore/yunohide/master/templates/metronome.tpl.cfg.lua
cat ./metronome.tpl.cfg.lua \
  | sed "s/{{ main_domain }}/${main_domain}/g" \
  > "${metronome_conf_dir}/metronome.cfg.lua"

# reload metronome
systemctl reload metronome


############################## SERVER INFO ####################################
echo_g "\n\n\n###################################################"
echo_n "Finished YunoHide installation!\n"
echo_n "SSH-Address:"
echo_n "$hidden_service_ssh"
echo_n "YunoHost-Address:"
echo_n "$hidden_service_default"
echo_n "pi password:"
echo_n "$ROOT_PASSWORD"
echo_n "admin password:"
echo_n "$ADMIN_PASSWORD"
echo_n "Please copy and save the addresses & passwords shown above."
echo_n "You need them to access your server from the internet!"
echo_g "###################################################\n\n"
