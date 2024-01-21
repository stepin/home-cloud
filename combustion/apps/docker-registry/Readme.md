# Local Docker Registry

## Test
```bash
$ podman login registry.lan.example.com:5000
Username: myUsername
Password:

$ podman tag docker.io/library/registry:2 registry.lan.example.com:5000/registry:2

$ podman push registry.lan.example.com:5000/registry:2
```
