#!/bin/sh

# For vagrant up hosts only
HOST=${HOST:-192.168.50.2}
PORT=${PORT:-39041}
APP_NS=${APP_NS:-demo}
AUTHVERIFY_NS=${AUTHVERIFY_NS:-demo}
REDIS_NS=${REDIS_NS:-demo}
MONGO_NS=${MONGO_NS:-demo}

call() {
  curl -v \
    -k \
    --cert-type pem \
    --cert ../haproxy/accesscerts/client.pem \
    --key-type pem \
    --key ../haproxy/accesscerts/client.pem \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d "$(python -c "import json; print json.dumps($1)")" \
    https://$HOST:$PORT/stacks/actions/deploy
}


redis() {
call '{
    "name": "'$REDIS_NS'_redis",
    "stack": "redis",
    "context": {
        "services.redis.limits.memory": "1024M",
        "construct.type": "single",
        "construct.auth_password": "Werttji5490xVg6r5"
    },
    "links": []
}
'
}

mongo() {
call '{
    "name": "'$MONGO_NS'_mongo",
    "stack": "mongo",
    "context": {
            "services.mongo.limits": "1024M",
            "services.mongo.cpus": "1.0",
            "construct.type": "single",
            "construct.admin_password": "qwerty",
            "construct.dbs": [{"db": "ico", "user": "user", "password": "Werttj"}],
            "construct.shared_key": "123EAABCC12341234123412341234"

    },
    "links": []
}
'
}

authverify() {
call '{
    "name": "'$AUTHVERIFY_NS'_authverify",
    "stack": "authverify",
    "context": {
            "ingress.auth.expose": "route://auth.com:3000?limitter=1s,4,6,10s,20,30",
            "services.auth.limits.memory": "1024M",
            "services.auth.limits.cpus": "1.0",
            "ingress.verify.expose": "route://verify.com:3000?limitter=1s,4,6,10s,20,30",
            "services.verify.limits.memory": "1024M",
            "services.verify.limits.cpus": "1.0",
            "construct.jwt_key": "Qr3r14rewqr9j8j98jrjhjnj54",
            "construct.redis_url": "redis://redis:Werttji5490xVg6r5@redis",
            "construct.mail_provider": "mailjet",
            "construct.mail_config": {
                "*MAILJET_API_KEY": "e3affab4235dd1bea58b6b39bb26e034",
                "*MAILJET_API_SECRET": "ae9a9aa605bfe3244c6d06ed661e7288"
            },
            "construct.tls.tenant_ca_cn": "secrettech.deployav",
            "construct.tls.tenant_ca": """
-----BEGIN CERTIFICATE-----
MIIGGzCCBAOgAwIBAgIJAIXG4F0T3bE5MA0GCSqGSIb3DQEBCwUAMIGjMQswCQYD
VQQGEwJSVTEcMBoGA1UECAwTc2VjcmV0dGVjaC5kZXBsb3lhdjEcMBoGA1UEBwwT
c2VjcmV0dGVjaC5kZXBsb3lhdjEcMBoGA1UECgwTc2VjcmV0dGVjaC5kZXBsb3lh
djEcMBoGA1UECwwTc2VjcmV0dGVjaC5kZXBsb3lhdjEcMBoGA1UEAwwTc2VjcmV0
dGVjaC5kZXBsb3lhdjAeFw0xODA2MjgxMzQwMTZaFw0yODA2MjUxMzQwMTZaMIGj
MQswCQYDVQQGEwJSVTEcMBoGA1UECAwTc2VjcmV0dGVjaC5kZXBsb3lhdjEcMBoG
A1UEBwwTc2VjcmV0dGVjaC5kZXBsb3lhdjEcMBoGA1UECgwTc2VjcmV0dGVjaC5k
ZXBsb3lhdjEcMBoGA1UECwwTc2VjcmV0dGVjaC5kZXBsb3lhdjEcMBoGA1UEAwwT
c2VjcmV0dGVjaC5kZXBsb3lhdjCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC
ggIBAMsrweOxpMsIBkuaojM027axPCq4FtmvTi+WHz1T3gVmP64/G7GCFbl1Te84
Gi0TuaLT1Z0isgticE49p3zG+UD4r3LQ0kenTGLCbL3RS2+DsS3eN14eGZ3K0jqk
s/GPCGXF8EeSJHS1UiXhPAb/CaUBGoSxg0Y2Hy5WVNylXjiD8N8IXPGlUsrr8tW3
3P9BQBY2i8bzeAIdv2Kf7toPdpqhjeo/7jHNabMRW/U4A7WGPoAVs09G2L7eWSyX
6+A9y/mdA1D8wR+KRWXCTTsPqeG7QpT0Die6PpXvAXqPOJHzHPStFShwrZJR7nrS
C2Cawvw5VsQA9fDIdJ8e6QQ916+Sc2m1KmRgX/c5oOTIRJSYGry/PyMBSVNPJ7JF
hnsW8pJbA3jgDe9MLbLd3lyoDq7Esd0nC7UL/x+Gqk5zJ8vdoyGtzWSRH21Yts6j
VhoP2f+b5efQwh0rRYaGQOjGhyblDsXcXkzpOikAUrC6tg38Z/+nEDUpOoTBy1Ek
KNH7lA8Mdis1gmJ1WvAD2S9HzvgBSPW2o25kczNLXjy4jMCOzWiBaxYsPqlpo8K9
xnm/vjOWdy8Qi+Km5M4LjvE+GwSKbp7n+rvY8DBiR+ASSe1UXJ+omEzrdYL6Yx2l
bgsg+NY9uUH36mXE9kYNsCZ350U9Odp64P1pizHzUgr8XQVbAgMBAAGjUDBOMB0G
A1UdDgQWBBSwd6dCGIzIp6Q+fORqzLs42dy/ATAfBgNVHSMEGDAWgBSwd6dCGIzI
p6Q+fORqzLs42dy/ATAMBgNVHRMEBTADAQH/MA0GCSqGSIb3DQEBCwUAA4ICAQCM
rR3LZ1skH9CCEUYngxYJM1ze68r8alqpnX/BAHFGQMtKz/lmq949bQcQLgwbTDJU
Hh/C5EhRdAjzCYp/8V2MRa1oaig4EexH+q6DzgHb0HTRkW5zoo2YO4UB9NFATcVJ
dz7MklercVW45erISasDDigwT4wAlRai+45q6PZWJMH74nRCJmguuaYRkgkMXP8o
9xNW5McBaYOQIbiIFOTGSnzuxchQX/GbU/LumxAzvm5g1xIqxPIf3ZzGo761cjC/
58XQxh/lcNO49JtOqF5z4YM2RGjlg40EJg/S+WAQJONfZvyRMj/6bPgITq5wcyzE
93dq6xJGrLc5d0TD7yfjuRQ/s27DSatUjODgi9RBEWwaJC3uO2HtDAJZ8fn4mdgh
XUfQt3ghQyAtcB7B1vSHMsWpNORVTQuwqazOPXnF4w3nXByymqZwrPD2zwY90zn0
sqGytp/dEEHd6zWymjr2YMtAMbbRiEt57U8e7W4D+Vgnh9X6IPIhTwgWTYqupOBX
NvwSXO4wcFi8I+yOAsrCyR0qWLR56vvT0cUQ2/d1Z6VFcIzb9fM4fhXf4cuIvA95
eB0nk236wywBfpwkZRx/ZdExId4dZn9pjr3ArjMzzYWi5LAVaQnOgAgCpC3GY2D5
gm1sofevxOEN0Uy7bAYm0NdLAehc8jhk7zoRX2zufg==
-----END CERTIFICATE-----
""",
            "construct.tls.tenant_server": """
-----BEGIN CERTIFICATE-----
MIIFdTCCA12gAwIBAgIJAJ6m7GBvHDg6MA0GCSqGSIb3DQEBCwUAMIGjMQswCQYD
VQQGEwJSVTEcMBoGA1UECAwTc2VjcmV0dGVjaC5kZXBsb3lhdjEcMBoGA1UEBwwT
c2VjcmV0dGVjaC5kZXBsb3lhdjEcMBoGA1UECgwTc2VjcmV0dGVjaC5kZXBsb3lh
djEcMBoGA1UECwwTc2VjcmV0dGVjaC5kZXBsb3lhdjEcMBoGA1UEAwwTc2VjcmV0
dGVjaC5kZXBsb3lhdjAeFw0xODA2MjgxMzQwMzhaFw0yODA2MjUxMzQwMzhaMB4x
HDAaBgNVBAMME3NlY3JldHRlY2guZGVwbG95YXYwggIiMA0GCSqGSIb3DQEBAQUA
A4ICDwAwggIKAoICAQDicWQS/Jg7Bu/1koqG0WXUAL/xcR7TxD4WuClZRYb5t2WO
SiwFtH1kNxEwuinTFTy6npSjLBeoFKh3YOCuOXTIjzQL0Ekof3RhMxQjx7m5ye03
wWoModp3iDyP4/mNOL9I2p6KSNVdvXrfApeA533HHhOzu2vKaeq2/DgVfOkNsUAK
+HEVdC8Dp58uMP7eVQPFaW7fF315J7dYSy487YE7nhcOMS22rA8P6XXLo6/zBHSb
cmnCN4hb1xfJKgfD/DKr5LqalZSqnv3Jg2pkxEyBB3xTGI266iErYjzqqYW93Dih
k6RYX4Fu1cqJ74AdDIrOpKMH+llANLzarmJALVfD86gdTkkRw5dlUNCpQhVoLpY2
yBQwe0WtMJTkK9kIbzjUneE+4up+obFdNfa+Dl5DJyBeXSNanDRCgvyZg4YM4x7R
KqK0avnO3MPliYCDXybl20YwdzIhpOapOEO+pecdkrDFbD1vaeX5SH1SE462XJIi
b0e+TcW+Psg8kgmc1zdH8/HxCMqtTonpjCqS1tFAClvKFTcO8nOsCZSqYSfkLtAu
/yQNiu4ys0JR1PcHV9d9AO88KZT4ZAFxiYFUUllZoITO3DAyaCwlMKQtixYLe/NK
Ggjvw26bTIYPGjQia7WF4crC5YoQ777Bo++568rNvidvSsMAUoNN6dE+3UmKVwID
AQABozAwLjAXBgNVHREEEDAOggxJUDoxMjcuMC4wLjEwEwYDVR0lBAwwCgYIKwYB
BQUHAwEwDQYJKoZIhvcNAQELBQADggIBABNm2jDfBBFUnkyAmqDtJHb3xlsL1icI
cbrNTwE2/Z2ndeXg8rxUWkPD3H/RGvwbdSPUHNSSVegD8MX6qt12pFMRjzluXgcN
BbgNKSw7oADw6cp2rWaGaHnJzmWZiXG29D5dm8Y1ivgjKOvJyTmIXyBBoHf2Krro
GjdeZuN2Y0zgwTYRJViP4T7ZkEqLTOwHXHLvbWEP/JGww8qlq5lc8ugm7kC+EjDC
bR348byr7+5U2agc7QBHCVLZDyzK5v+3gJ3NnbVuE71s4ueD891B/xtYc1mTX73O
oT5VMjdciXv4PSFcD8UhKOhqTE8kz0zP0HfQe/QWfUL5s+3V4A7EiOCbKAifC8la
oIKsFUITGxhZRyLaR+jeNTTNwIHr7MhbAy3peol6APaU4U2f9SZPvV1bk+ifZzUt
fs5CF/abNXmJp0wnwdisA7+fNBM5olK1Ycncj22jcE8l/hUk9gujzcSpiDzUX831
D0+bHYDr5wvlxK9+7e14yfGFCiXVVNUGmdKyI3GAzvEUz1BsdtDxJ2VbBoPjBd9h
usFg26wTEBmeiH6r/LCpfeeiTHYnK2249MJMhguOwTHnLENYMsQiDtcaDyYM44uI
Vw56w3yOD8C0q+gUPB7Rmgy4StMPYO+E89OD+wM6eOyJjvVF8O+z7ozQD2P2IZw8
gIKWeuMZ1BZM
-----END CERTIFICATE-----
-----BEGIN RSA PRIVATE KEY-----
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
-----END RSA PRIVATE KEY-----
"""
    },
    "links": ["redis:'$REDIS_NS'_redis"]
}
'
}

app() {
call '{
    "name": "'$APP_NS'_app",
    "stack": "app",
    "context": {
        "ingress.frontend.expose": "route://${APP_FRONT_HOST:-invest.stage.jincor.com}:80",
        "services.frontend.image": "alekns/frontend-ico-dashboard:latest",
        "services.frontend.limits.memory": "1024M",
        "services.frontend.limits.cpus": "1.0",
        "ingress.backend.expose": "route://${APP_BACK_HOST:-ico-api.stage.jincor.com}:3000?limitter=1s,12,16",
        "services.backend.image": "alekns/backend-ico-dashboard:latest",
        "services.backend.limits.memory": "1024M",
        "services.backend.limits.cpus": "1.0",
        "services.backend.envs": """
COMPANY_NAME=Test
ENVIRONMENT=test
TOKEN_PRICE_USD=1.0
API_URL=http://ico-api.stage.jincor.com
FRONTEND_URL=http://invest.stage.jincor.com

ICO_END_TIMESTAMP=1517443200

MONGO_AUTH_SOURCE=admin
MONGO_REPLICA_SET=replica

# Smart-contracts
SC_ABI_FOLDER=contracts/default
ICO_SC_ADDRESS=0x4be257d468dae409e0b875ebb1569c25cf3b1d59
ICO_OLD_SC_ADRESSES=
WHITELIST_SC_ADDRESS=0x3c97c521cc60e3c6bb8b568d36d7d2f7fa2435fb
TOKEN_ADDRESS=0xae2de83a3894fcbbce560492fad3ca8bbdb6d0da
WL_OWNER_PK=
TEST_FUND_PK=

RPC_TYPE=http
RPC_ADDRESS=https://rinkeby.infura.io/ujGcHij7xZIyz2afx4h2
WEB3_RESTORE_START_BLOCK=2015593
WEB3_BLOCK_OFFSET=200

DEFAULT_INVEST_GAS=230000

THROTTLER_INTERVAL=10000

# Email
# EMAIL_TEMPLATE_FOLDER=default
EMAIL_FROM=noreply@icodashboard.space
EMAIL_REFERRAL=partners@icodashboard.space
MAIL_DRIVER=mailjet
# Mailgun provider
# MAILGUN_DOMAIN=icodashboard.space
# MAILGUN_API_KEY=key-0123456789

# mailjet provider
MAILJET_API_KEY=e3affab4235dd1bea58b6b39bb26e034
MAILJET_API_SECRET=ae9a9aa605bfe3244c6d06ed661e7288

# KYC settings
KYC_STATUS_DEFAULT=verified
KYC_ENABLED=false
KYC_ENABLED=false
KYC_PROVIDER=JUMIO

# Jumio provider
KYC_JUMIO_BASE_URL=http://kyc.example.com
KYC_JUMIO_TOKEN=api_token
KYC_JUMIO_SECRET=api_secret
# KYC_JUMIO_TOKEN_LIFETIME=5184000

# Shufti Pro provider
KYC_SHUFTIPRO_CLIENT_ID=CLIENTID
KYC_SHUFTIPRO_SECRET_KEY=SECRETKEY
KYC_SHUFTIPRO_REDIRECT_URL=http://localhost
KYC_SHUFTIPRO_CALLBACK_URL=http://localhost
KYC_SHUFTIPRO_ALLOW_RECREATE_SESSION=false
KYC_SHUFTIPRO_DEFAULT_PHONE=+440000000000

ACCESS_LOG=true
LOGGING_LEVEL=debug
""",
        "construct.tenant_email": "test@testtest.com",
        "construct.tenant_password": "aQWERqreRer342",
        "construct.tenant_client": """
-----BEGIN CERTIFICATE-----
MIIFdTCCA12gAwIBAgIJAJ6m7GBvHDg7MA0GCSqGSIb3DQEBCwUAMIGjMQswCQYD
VQQGEwJSVTEcMBoGA1UECAwTc2VjcmV0dGVjaC5kZXBsb3lhdjEcMBoGA1UEBwwT
c2VjcmV0dGVjaC5kZXBsb3lhdjEcMBoGA1UECgwTc2VjcmV0dGVjaC5kZXBsb3lh
djEcMBoGA1UECwwTc2VjcmV0dGVjaC5kZXBsb3lhdjEcMBoGA1UEAwwTc2VjcmV0
dGVjaC5kZXBsb3lhdjAeFw0xODA2MjgxMzQwNTFaFw0yODA2MjUxMzQwNTFaMB4x
HDAaBgNVBAMME3NlY3JldHRlY2guZGVwbG95YXYwggIiMA0GCSqGSIb3DQEBAQUA
A4ICDwAwggIKAoICAQCp5aTSvKlJV3vdqM9aJysx8DOdBt8tUa6jm2qjpx6ABpNc
c62qKf1oHVcHXc75q37Uz9B1JEQ8SC8ESyrgQoqGIW4wjea5CuEA/6uZV+7hf2uZ
NUfpJ+gws6F7dW9G0G0IulOZJUyBNc+Tb/+F4VLS1FcYwvtqZKLGjWT7KiDzDaIR
+MSXtA+eGxuhOxudfz8hSycDxbMLR5LJ7nrtEuyTSM+D52ihs4b0X9TtMm0ifXWh
8/QolnD/J/BCDtHUV10TwgjMV0omV7FfNJDrB59adOA0uGwNRjQN3m//0U/gamMK
gIAhsGzJ81itaW2R/7uNNzVOXBQ74MbsGyYTE1ZAk3s5rcr7a3SU7I85o6P2zER8
JlsF8NnubVCn94rv6nH6vJKTBfuk1jSIjoANreXr7/uIKbUXykN672rIf9yx01F8
TZQCteIK53nvUJ5shhVG8LZvh1wWu9ccqYxMI5a6nOLqH4SdmjT/Z5Ay3/DI958D
JvQYIo0ezdaXh6af1wFAjkn5y/TTtTabi9v410k1mYv+3ktCYxssZttZsjEUMGzA
VbBhRWlJ8yK3Zty8WJ//ea76N7U1v0FHR3EmTg3tYl+oWkgXeOS63EbE/d+Zb/Ai
Zqz76+wdTZu6U9r4bqztH1+bySpymyZawSAJUPUYu3KuVZ2lO15gsZARlOECWwID
AQABozAwLjAXBgNVHREEEDAOggxJUDoxMjcuMC4wLjEwEwYDVR0lBAwwCgYIKwYB
BQUHAwIwDQYJKoZIhvcNAQELBQADggIBALZsSjBwyhUcTOJ7bZBOM46VjTQHLXAz
ZtAmqv08jTOxsBw/gpPYYinYp8PwhnGxFjdWFcaL8JldFadkLyyZOw88eUIDVBTN
eax/bjzu5TqdTzghjxA0zkeS9+SVc7ULFtDsVad5+xfGRpd6pZkE/cSAwawrC7Fz
xBBDETVCAHDhEDQQTd79J9U1RxvztwqmnDmaaaCiKPBY0/1Cs5R0dEPF6rAYhx5M
Ld5jheh10+uxSCFUab6cHRBQTRo1vO4hJihzd2ud5XOgGkaPRmHEbndOKdk1tuV9
csUAU2g7oL81Cu7eb52nI+fx288hlVn3H2+IPrX9eqXt/BIx1SxjC8JddmhLQCEc
WYysFFaZU+i3b5Mgp5LR0z8XTW7RM1XhUcYNJti7jN2na/w+/XNCwvq+jQ3ZFH8M
USSQ0FG6ZbU2aTbr+ZfLtg5UclIQW1CkTpqs5MUYhJE2tEW6Np/MX9s05ft76Qpi
0Crd2DzptADNPulostjJLhYt/BDzhCZfhSRMvWw30ZDRSrGjsggewukg0JNTfrPY
cOxaB5HYGm4l1i1GYm0pz+35OZ725mGcUmtNYwSDrMenV7wtasJ/KARC48OXiiD3
YQXhLJPJHNNtBOzvnFGDlP2h3b75CpiqiFl05ySZ3y5vsKzXUNzYUjyWa50nLZUH
go4LVSYx5Wpo
-----END CERTIFICATE-----
-----BEGIN RSA PRIVATE KEY-----
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
-----END RSA PRIVATE KEY-----
""",
        "construct.auth_url": "http://auth:3000",
        "construct.verify_url": "http://verify:3000",
        "construct.redis_url": "redis://redis:Werttji5490xVg6r5@redis",
        "construct.mongo_url": "mongodb://user:Werttj@mongo-1/ico?authSource=admin"
    },
    "links": ["authverify:'$AUTHVERIFY_NS'_authverify", "mongo:'$MONGO_NS'_mongo", "redis:'$REDIS_NS'_redis"]
}
'
}
#        "construct.mongo_url": "mongodb://user:Werttj@mongo-1/ico?authSource=admin"
#        "construct.mongo_url": "mongodb://user:Werttj@mongo-1,mongo-2,mongo-3/ico?replicaSet=replica&authSource=admin"

case $1 in
  redis)
    redis
    ;;
  mongo)
    mongo
    ;;
  authverify)
    authverify
    ;;
  app)
    app
    ;;
  *)
    echo 'Use: reqs-example.sh {redis,mongo,authverify,app}'
    ;;
esac
