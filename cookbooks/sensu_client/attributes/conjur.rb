
# These attributes are used only by the conjurrc recipe, which can be used
# to install the initial Conjur configuration and certificate.
default['conjur']['configuration']['account'] = 'chef'
default['conjur']['configuration']['appliance_url'] \
  = 'https://ec2-54-90-25-181.compute-1.amazonaws.com/api'

default['conjur']['configuration']['plugins'] = ['host-factory']

default['conjur']['configuration']['ssl_certificate'] = <<END_SSL
-----BEGIN CERTIFICATE-----
MIIDMzCCAhugAwIBAgIJAPXKyoAwwkkDMA0GCSqGSIb3DQEBBQUAMDMxMTAvBgNV
BAMTKGVjMi01NC05MC0yNS0xODEuY29tcHV0ZS0xLmFtYXpvbmF3cy5jb20wHhcN
MTUwNDIzMTczMjI0WhcNMjUwNDIwMTczMjI0WjAzMTEwLwYDVQQDEyhlYzItNTQt
OTAtMjUtMTgxLmNvbXB1dGUtMS5hbWF6b25hd3MuY29tMIIBIjANBgkqhkiG9w0B
AQEFAAOCAQ8AMIIBCgKCAQEA4LvjUh09WebsUIRhV5NVgDhJk5KBUp9tjq8DtO6i
2fpfg4O7ABNZ/UIaYTsEcpa1ihRirvSAv0NvxpPWAAqQD4lEFwXTW+Xk4lwY378u
FNxtW3OPIgokXOfcj9nECjhBhVX9Q/Ulrvz0XKG6bChTkp0M1E16cqXqncpCUEjU
g/HJFLcLPYC8+anaU2+faYJT1cYbzxbkOl1Qkvq4f1TXgdkyYim3zzKwmnQV9akv
+40JRZZG0iVTYMPXY2AV1LWz6lHzFGT5eFEaopanRX/9JQjcWTlhSGJqo3uKZRTl
Tq8jNCfa/N8nx5pBQaQqiRl2q1S/Y5Zjc8sEMPDmH1dtLQIDAQABo0owSDBGBgNV
HREEPzA9gglsb2NhbGhvc3SCBmNvbmp1coIoZWMyLTU0LTkwLTI1LTE4MS5jb21w
dXRlLTEuYW1hem9uYXdzLmNvbTANBgkqhkiG9w0BAQUFAAOCAQEAdLKNQhdaoqUh
MYfMAr+UGLD9qLvwaxOm2F6ul0H6J0H52qCuvKtdZDZwUHCjX61EPaH02elEi5oJ
zvH6UvP89zQX/2PCQpQr+9nD0TEJdLuJBAm3mD73AjHF0h87xcq4QHCaPgONcWgN
OhstUkicObOwu0KDHbZWIVr3gvEJsFFdx8upu+l/3kwJCaO1t0Dwv5iDYs5C339G
i1lui5hT5HqbZgwaUd0hEbLX6ex5xnDGvCiZEQpnXpkjYp6EDISu5yy8Ey8jh8Ka
0bE7SFOnxzK0rgN4vnmbysZ3Zy1t1VkJw+MXKR/qO3t82NDhiNYlyam+eyfzjWr6
tfG42GP2JQ==
-----END CERTIFICATE-----
END_SSL
