## Pre- and Post-Hooks

The Pre- and Post-Hooks of [acme.sh](https://github.com/acmesh-official/acme.sh/) are available in the container now. Therefor it is possible to trigger actions just before and after a certificate is issued (see  https://github.com/acmesh-official/acme.sh/wiki/Using-pre-hook-post-hook-renew-hook-reloadcmd)

### Pre-Hook
The **Pre-Hook** is called before the certificate is issued. Therefor it is possible to perform some custom actions for minitoring or carry uot some other necassery actions.

The Pre-Hook is set in the proxied container by using the env var `ACME_PRE_HOOK=myCustomCommand`

### Post-Hook
The **Post-Hook** is called after the certificate is issued. Therefor it is possible to perform some custom actions for minitoring or carry out some other necassery actions.

The Post-Hook is set in the proxied container by using the env var `ACME_POST_HOOK=myCustomCommand`

### Default Pre-Hook
Default Pre-Hook action is used when no Pre-Hook action in the proxied container is set.
The default Pre-Hook is set in the acme-companion container by using the env var `ACME_DEFAULT_PRE_HOOK=myCustomCommand`

### Default Post-Hook
Default Post-Hook action is used when no Post-Hook action in the proxied container is set.
The default Post-Hook is set in the acme-companion container by using the env var `ACME_DEFAULT_POST_HOOK=myCustomCommand`


### Example:
based on the example of [Basic usage](./Basic-usage.md)
#### nginx-proxy

```shell
$ docker run --detach \
    --name nginx-proxy \
    --publish 80:80 \
    --publish 443:443 \
    --volume certs:/etc/nginx/certs \
    --volume vhost:/etc/nginx/vhost.d \
    --volume html:/usr/share/nginx/html \
    --volume /var/run/docker.sock:/tmp/docker.sock:ro \
    nginxproxy/nginx-proxy
```

#### acme-companion

```shell
$ docker run --detach \
    --name nginx-proxy-acme \
    --volumes-from nginx-proxy \
    --volume /var/run/docker.sock:/var/run/docker.sock:ro \
    --volume acme:/etc/acme.sh \
    --env "DEFAULT_EMAIL=mail@yourdomain.tld" \
    --env "ACME_DEFAULT_PRE_HOOK=echo 'start'" \
    --env "ACME_DEFAULT_POST_HOOK=echo 'finish'" \
    nginxproxy/acme-companion
```

#### proxyed container(s)

```shell
$ docker run --detach \
    --name grafana \
    --env "VIRTUAL_HOST=othersubdomain.yourdomain.tld" \
    --env "VIRTUAL_PORT=3000" \
    --env "LETSENCRYPT_HOST=othersubdomain.yourdomain.tld" \
    --env "LETSENCRYPT_EMAIL=mail@yourdomain.tld" \
    --env "ACME_PRE_HOOK=myCustomCommand"
    grafana/grafana
```

### Verifying the Command is set correctly:
If you want to check weather the hook-command is delivered properly to [acme.sh](https://github.com/acmesh-official/acme.sh/), you should check `/etc/acme.sh/[EMAILADDRESS]/[DOMAIN]/[DOMAIN].conf`.
The variable `Le_PreHook` contains the Pre-Hook-Command base64 encoded.
The variable `Le_PostHook` contains the Post-Hook-Command base64 encoded.

### Limitations
* The commands that can be used in the hooks are only these commands available inside the acme-companion container. Fortunately `wget` and `curl` are available, therefor it is possible to communicate with the outside world via http-requests. So more complex actions can be implemented somewhere else, for example in other containers.

### Use-cases
* Change some firewall-rules just for the issuing-process of the certificates. So the ports 80 and 443 haven't to be publicly reachable all the time.
* Monitoring

