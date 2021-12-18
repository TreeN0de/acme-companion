## Pre- and Post-Hooks

The Pre- and Post-Hooks of [acme.sh](https://github.com/acmesh-official/acme.sh/) are used and are available in the container now. Therefor it is possible to trigger actions just before and after a certificate is issued (see  https://github.com/acmesh-official/acme.sh/wiki/Using-pre-hook-post-hook-renew-hook-reloadcmd)

#### Pre-Hook
This command will be performed, before certificates are issued. For example `echo 'start'`:
```shell
$ docker run --detach \
    --name nginx-proxy-acme \
    --volumes-from nginx-proxy \
    --volume /var/run/docker.sock:/var/run/docker.sock:ro \
    --volume acme:/etc/acme.sh \
    --env "DEFAULT_EMAIL=mail@yourdomain.tld" \
    --env "ACME_PRE_HOOK=echo 'start'"
    nginxproxy/acme-companion
```

#### Post-Hook
This command will be performed, after certificates are issued. For example `echo 'end'`:
```shell
$ docker run --detach \
    --name nginx-proxy-acme \
    --volumes-from nginx-proxy \
    --volume /var/run/docker.sock:/var/run/docker.sock:ro \
    --volume acme:/etc/acme.sh \
    --env "DEFAULT_EMAIL=mail@yourdomain.tld" \
    --env "ACME_POST_HOOK=echo 'end'"
    nginxproxy/acme-companion
```

#### Verification:
If you want to check weather the hook-command is delivered properly to [acme.sh](https://github.com/acmesh-official/acme.sh/), you should check `/etc/acme.sh/[EMAILADDRESS]/[DOMAIN]/[DOMAIN].conf`.
The variable `Le_PreHook` contains the Pre-Hook-Command base64 encoded.
The variable `Le_PostHook` contains the Pre-Hook-Command base64 encoded.

#### Limitations
* The commands that can be used in the hooks are only the commands available inside the container. Fortunately `wget` is available, therefore it is possible to communicate with tools outside the container via http. So more complex actions can be implemented outside or in other containers.
* The hooks are general options, therefore the action for all certificates are the same. In future it could be possible to implement custom-hooks for each certificate like the `VIRTUAL_HOST` parameter today.

#### Use-cases
* Change some firewall-rules just for the Issuing-process of the certificates. So the ports 80 and 443 haven't to be publicly reachable all the time
* Monitoring

