def extract_hosts():
    import json
    with open('terraform-output.json') as json_file:
        data = json.load(json_file)
    hosts = {'masters': [], 'workers': []}
    ec2_instances_created = data['ec2_instances_created']['value']
    for key in ec2_instances_created:
        if('master' in ec2_instances_created[key]['tags']['Name']):
            hosts['masters'].append({
                'public_ip': ec2_instances_created[key]['public_ip'],
                'tag': ec2_instances_created[key]['tags']['Name']
            })
        else:
            hosts['workers'].append({
                'public_ip': ec2_instances_created[key]['public_ip'],
                'tag': ec2_instances_created[key]['tags']['Name']
            })
    return hosts

def generate_inventory(hosts, file_name='hosts', ansible_user='admin', docker_swarm_port='2377'):
    f = open(file_name, "w")
    f.write("[masters]\n")
    for master in hosts['masters']:
        f.write('{tag} ansible_host={public_ip}\n'.format(tag=master['tag'], public_ip=master['public_ip']))
    f.write('\n\n')
    f.write("[workers]\n")
    for worker in hosts['workers']:
        f.write('{tag} ansible_host={public_ip}\n'.format(tag=worker['tag'], public_ip=worker['public_ip']))
    f.write('\n\n')

    f.write('[all:vars]\n')
    f.write('ansible_python_interpreter=/usr/bin/python3\n')
    f.write('ansible_user={ansible_user}\n'.format(ansible_user=ansible_user))
    f.write('master_ip={master_ip}\n'.format(master_ip=hosts['masters'][0]['public_ip']))
    f.write('docker_swarm_port={docker_swarm_port}\n'.format(docker_swarm_port=docker_swarm_port))
    f.close()
    print('ansible inventory generated check /etc/ansible/hosts')

def update_ansible_config():
    import shutil
    import os
    if(os.path.exists('/etc/ansible/hosts_old')):
        os.remove("/etc/ansible/hosts_old")
    shutil.copy('/root/terraform/output/hosts', '/etc/ansible/hosts')

def main():
    hosts = extract_hosts()
    generate_inventory(hosts)
    update_ansible_config()

main()

# terraform output -json > output/terraform-output.json
# cd output && python3 generate_host.py
# mv /etc/ansible/hosts /etc/ansible/hosts_old
# cp hosts /etc/ansible/
