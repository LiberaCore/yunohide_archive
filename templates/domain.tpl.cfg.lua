VirtualHost "{{ domain }}"
  modules_enabled = {onions}
  onions_only = true
  onions_tor_all = true
  ssl = {
        key = "/etc/yunohost/certs/{{ domain }}/key.pem";
        certificate = "/etc/yunohost/certs/{{ domain }}/crt.pem";
  }
  authentication = "ldap2"
  ldap = {
     hostname      = "localhost",
     user = {
       basedn        = "ou=users,dc=yunohost,dc=org",
       filter        = "(&(objectClass=posixAccount)(mail=*@{{ domain }}))",
       usernamefield = "mail",
       namefield     = "cn",
       },
  }
