#cloud-config
users:
  - name: ${vm_ssh_user}
    ssh-authorized-keys:
      - ${vm_ssh_key}
    sudo: ALL=(ALL) NOPASSWD:ALL
write_files:
  - path: /root/nginx.conf
    content: |
        load_module /usr/lib/nginx/modules/ngx_stream_module.so;

        worker_processes 4;
        worker_rlimit_nofile 40000;

        events {
            worker_connections 8192;
        }

        stream {
            upstream rancher_servers_http {
                least_conn;
            %{ for s in servers ~}
                server ${s}:39050 max_fails=3 fail_timeout=5s;
            %{ endfor ~}
            }
            server {
                listen 80;
                proxy_pass rancher_servers_http;
            }

            upstream rancher_servers_https {
                least_conn;
            %{ for s in servers ~}
                server ${s}:30050 max_fails=3 fail_timeout=5s;
            %{ endfor ~}
            }
            server {
                listen     443;
                proxy_pass rancher_servers_https;
            }
        }