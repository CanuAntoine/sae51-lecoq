#!/usr/bin/env python3
# /opt/myapp/servHeb/servHeb.py
from flask import Flask, request, jsonify
import os, netifaces, random, subprocess, shutil, socket, pathlib, time, psutil

app = Flask(__name__)

BASE_DIR = '/opt/user_sites'
os.makedirs(BASE_DIR, exist_ok=True)

def choose_port():
    """
    Selects the port that the website will use
    """
    for _ in range(50):
        p = random.randint(20000,30000)
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            try:
                s.bind(('0.0.0.0', p))
                return p
            except OSError:
                continue
    raise RuntimeError("Unable to find an available port")

def get_lan_ip():
    """
    Returns the LAN IP address of the server in the VirtualBox network (192.168.56.x)
    """
    for iface in netifaces.interfaces():
        if iface.startswith('enp0s8'):  
            addrs = netifaces.ifaddresses(iface)
            if netifaces.AF_INET in addrs:
                return addrs[netifaces.AF_INET][0]['addr']
    return '127.0.0.1'



@app.route('/create_service', methods=['POST'])
def create_service():
    """
    Endpoint for creating user service
    """
    try:
        user_id = request.form.get('userId') or request.form.get('username') or request.values.get('userId')
        service = request.form.get('service') or 'html'
        service_id = request.form.get('serviceId') or str(int(time.time()))
        if not user_id:
            return jsonify({"success": False, "erreur": "userId manquant"}), 400

        # create user dir
        safe_name = "".join(c for c in user_id if c.isalnum() or c in ('_','-')) or "user"
        site_dir = os.path.join(BASE_DIR, f"{safe_name}_{service_id}")
        pathlib.Path(site_dir).mkdir(parents=True, exist_ok=True)

        # Save uploaded files
        # Accept multiple files under field name 'files[]' or 'files'
        files = []
        if 'files[]' in request.files:
            files = request.files.getlist('files[]')
        elif 'files' in request.files:
            files = request.files.getlist('files')
        else:
            files = list(request.files.values())

        for f in files:
            filename = os.path.basename(f.filename)
            if not filename:
                continue
            target = os.path.join(site_dir, filename)
            f.save(target)
            os.chmod(target, 0o644)

        # If no index present, create a simple one from form html or default
        if not any(os.path.exists(os.path.join(site_dir, name)) for name in ('index.html','index.php','index.htm')):
            html = request.form.get('html') or "<h1>Bonjour</h1><p>Site créé automatiquement.</p>"
            with open(os.path.join(site_dir, 'index.html'), 'w') as fh:
                fh.write(html)

        # pick port and image/volume mapping
        port = choose_port()
        container_name = f"user_{safe_name}_{service_id}"

        if service == 'php':
            image = 'php:8.2-apache'
            container_cmd = [
                'docker','run','-d',
                '--name', container_name,
                '-p', f'{port}:80',
                '-v', f'{site_dir}:/var/www/html:ro',
                image
            ]
        else: 
            image = 'nginx:alpine'
            container_cmd = [
                'docker','run','-d',
                '--name', container_name,
                '-p', f'{port}:80',
                '-v', f'{site_dir}:/usr/share/nginx/html:ro',
                image
            ]

        # ensure any old container with same name removed
        try:
            subprocess.run(['docker','rm','-f',container_name], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception:
            pass

        # run the container
        res = subprocess.run(container_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if res.returncode != 0:
            return jsonify({"success": False, "erreur": f"docker run failed: {res.stderr}"}), 500

        pub_ip = get_lan_ip()
        return jsonify({"success": True, "ip": pub_ip, "port": port, "service": service, "container": container_name})

    except Exception as e:
        return jsonify({"success": False, "erreur": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
