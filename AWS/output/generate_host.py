
def extaction():
    import json
    with open('terraform-output.json') as json_file:
        data = json.load(json_file)
    ec2_instances_created = data['ec2_instances_created']['value']
    groups = []
    for key in ec2_instances_created:
        groups.append(ec2_instances_created[key]['tags']['group'])
    groups = list(set(groups))
    hosts = {}
    for group in groups:
        group_name = group + "_group"
        hosts[group_name] = []
    for key in ec2_instances_created:
        group_name = ec2_instances_created[key]['tags']['group']+"_group"
        tag = ec2_instances_created[key]['tags']['group']+str(len(hosts[group_name])+1)
        hosts[group_name].append({
            'public_ip': ec2_instances_created[key]['public_ip'],
            'tag': tag
        })
    return hosts

def generate_inventory(hosts, file_name='hosts.ini', ansible_user='admin', master_ip='master_ip', docker_swarm_port='2377'):
    with open(file_name, "w") as hosts_file:
        for key in hosts:
            hosts_file.write("[{group_name}]\n".format(group_name=key))
            for host in hosts[key]:
                hosts_file.write('{tag} ansible_host={public_ip}\n'.format(tag=host['tag'], public_ip=host['public_ip']))
            hosts_file.write('\n\n')
        hosts_file.write('[all:vars]\n')
        hosts_file.write('ansible_python_interpreter=/usr/bin/python3\n')
        hosts_file.write('ansible_user={ansible_user}\n'.format(ansible_user=ansible_user))
        hosts_file.write('master_ip={master_ip}\n'.format(master_ip=master_ip))
        hosts_file.write('docker_swarm_port={docker_swarm_port}\n'.format(docker_swarm_port=docker_swarm_port))

hosts = extaction()
generate_inventory(hosts)