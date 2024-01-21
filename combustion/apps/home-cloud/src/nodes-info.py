#!/usr/bin/env python3
#
# Local apps
# 1. read all /cloud/*/app.conf files
# 2. read /cloud/system/system.conf
# 3. produce /cloud/home-cloud/data/data/home_cloud_site/index.json
#
from dataclasses import dataclass
import dataclasses, json
import os
from glob import glob
import socket
import urllib.request

#
# data structures
#

@dataclass
class System:
    name: str
    hostname: str
    avahiAlias: str
    sortOrder: int = 0
    lbInternal: bool = True
    lbExternal: bool = True

@dataclass
class App:
    name: str
    avahiAlias: str
    lbInternal: str
    lbExternal: str
    publicPort: int

@dataclass
class Server:
    system: System
    apps: [App]

#
# input
#

def read_file(filename:str):
    print("Processing %s" % filename)
    with open(filename, 'r') as env_file:
        data = env_file.read()
        return data

def read_file_properties(filename:str):
    data = read_file(filename)
    variables = {}
    for line in data.split('\n'):
        l=line.strip()
        # empty or comment
        if not l or l.startswith("#"):
            continue
        key, value = line.split("=")
        variables[key.strip()] = value.strip().strip('"')
    return variables

def load_json(url):
    print("loading %s" % url)
    with urllib.request.urlopen(url) as response:
        data = response.read
        encoding = response.info().get_content_charset('utf-8')
        json_object = json.loads(data.decode(encoding))
        return json_object

def vars2system(variables, hostname, avahiAlias):
    return System(
        name = variables["NODE_NAME"],
        hostname = hostname,
        avahiAlias = avahiAlias,
        sortOrder = int(variables["SORT_ORDER"]),
        lbInternal = variables["LB_INTERNAL"].lower() == "true",
        lbExternal = variables["LB_EXTERNAL"].lower() == "true"
    )

def vars2app(variables):
    return App(
        name = variables["NAME"],
        avahiAlias = variables.get("AVAHI_ALIAS"),
        lbInternal = variables.get("LB_INTERNAL"),
        lbExternal = variables.get("LB_EXTERNAL"),
        publicPort = int(variables.get("PUBLIC_PORT"))
    )

system_file = "/cloud/system/system.conf"
system_variables = read_file_properties(system_file)
hostname = socket.gethostname()
short_hostname = socket.gethostname().split('.', 1)[0]
system = vars2system(system_variables, hostname, short_hostname + ".local")

parent_dir = "/cloud"
files = glob(os.path.join(parent_dir,'*','app.conf'))
apps = list(map(vars2app,map(read_file_properties,files)))

server = Server(system, apps)

server_urls_file = "/cloud/home-cloud/data/data/home_cloud_site/servers_urls.csv"
servers_urls = list(filter(None, read_file(server_urls_file).split('\n')))

servers = [server]
servers += list(map(load_json, servers_urls))

#
# output
#

def caddyfile_200_record(domain):
    return "%s {\n\trespond /health 200\n}\n" % domain

def caddyfile_200_tls_record(domain, tls):
    return "%s {\n\ttls %s\n\trespond /health 200\n}\n" % (domain, tls)

def caddyfile_static_tls_record(domain, tls, path):
    return "%s {\n\ttls %s\n\troot * %s\n\tfile_server\n}\n" % (domain, tls, path)

def caddyfile_proxy_record(domain, tls, proxy_url):
    return "%s {\n\ttls %s\n\treverse_proxy %s\n}\n" % (domain, tls, proxy_url)

def caddyfile_redir_record(domain, domain_dst):
    return "%s {\n\tredir %s{uri} permanent\n}\n" % (domain, domain_dst)

def caddyfile_gen(server):
    public_tls = '/config/fullchain.pem /config/privkey.pem'

    output = ""
    output += caddyfile_static_tls_record(server.system.avahiAlias, 'internal', '/data/home_cloud_site/')
    output += caddyfile_200_tls_record(':443', 'internal')
    output += caddyfile_200_record(':8080')
    for app in server.apps:
        proxy_url = server.system.hostname + ":" + str(app.publicPort)
        if app.avahiAlias:
            output += caddyfile_proxy_record(app.avahiAlias, 'internal', proxy_url)
        if app.lbInternal and server.system.lbInternal:
            output += caddyfile_proxy_record(app.lbInternal, public_tls, proxy_url)
        if app.lbExternal and server.system.lbExternal:
            output += caddyfile_proxy_record(app.lbExternal, public_tls, proxy_url)
            output += caddyfile_proxy_record("https://"+app.lbExternal+":8443", public_tls, proxy_url)
            output += caddyfile_redir_record("http://"+app.lbExternal+":8080", "https://"+app.lbExternal)
    return output

caddyfile = caddyfile_gen(server)

output_file_index = "/cloud/home-cloud/data/data/home_cloud_site/index.json"
output_file_caddyfile = "/cloud/home-cloud/data/config/Caddyfile"


class EnhancedJSONEncoder(json.JSONEncoder):
        def default(self, o):
            if dataclasses.is_dataclass(o):
                return dataclasses.asdict(o)
            return super().default(o)

with open(output_file_index, 'w') as f:
    json.dump(servers, f, cls=EnhancedJSONEncoder)
    f.write('\n')

with open(output_file_caddyfile, 'w') as f:
    f.write(caddyfile)
