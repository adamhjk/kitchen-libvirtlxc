require "securerandom"
require "kitchen"

module Kitchen
  module Driver
    class Libvirtlxc < Kitchen::Driver::SSHBase
      no_parallel_for :create

      default_config :use_sudo, false
      default_config :customize, {:memory => 256, :vcpu => 1}
      default_config :port, 22
      default_config :username, "root"
      default_config :ssh_key, "/root/.ssh/id_rsa"
      default_config :ssh_public_key, "/root/.ssh/id_rsa.pub"
      default_config :container_path, "/var/lib/libvirt/lxc"
      default_config :base_container, "lxc0"

      def create(state)
        state[:container_id] = SecureRandom.uuid
        new_container = File.join(config[:container_path], state[:container_id])
        state[:container_path] = new_container
        run_command("cp -r #{File.join(config[:container_path], config[:base_container])} #{new_container}")
        run_command("mkdir -p #{new_container}/root/.ssh")
        run_command("chmod 0700 #{new_container}/root/.ssh")
        run_command("cat #{config[:ssh_public_key]} >> #{new_container}/root/.ssh/authorized_keys")
        run_command("chmod 0644 #{new_container}/root/.ssh/authorized_keys")
        fixup_files(container_id, new_container)
        run_command("virt-install --connect lxc:/// --name #{state[:container_id]} --ram #{config[:customize][:memory]} --vcpu #{config[:customize][:vcpu]} --filesystem #{new_container}/,/ --noautoconsole")
        run_command("virsh --connect lxc:/// start #{state[:container_id]}")
        state[:hostname] = wait_for_lease(state[:container_id])
        wait_for_sshd(state[:hostname])
      end

      def destroy(state)
        if state[:container_id] && state[:container_path]
          run_command("virsh --connect lxc:/// destroy #{state[:container_id]}")
          run_command("rm -rf #{state[:container_path]}")
          run_command("rm /etc/libvirt/lxc/#{state[:container_id]}.xml")
        end
      end

      def fixup_files(container_id, container_path)
        etc_sysconfig_network = File.join(container_path, "etc", "sysconfig", "network")
        if File.exists?(etc_sysconfig_network)
          run_command("sed -i s/HOSTNAME=.+/HOSTNAME=#{state[:container_id]}/g #{etc_sysconfig_network}")
        end
        ifcfg_eth0 = File.join(container_path, "etc", "sysconfig", "network-scripts", "ifcfg-eth0")
        if File.exists?(etc_sysconfig_network)
          run_command("sed -i s/BOOTPROTO=.+/BOOTPROTO=dhcp/g #{ifcfg_eth0}")
          run_command("sed -i s/IPADDR=.+//g #{ifcfg_eth0}")
        end
      end

      def wait_for_lease(container_id)
        mac_address = nil
        ip_address = nil
        File.open("/etc/libvirt/lxc/#{container_id}.xml", "r") do |xml|
          xml.each_line do |line|
            if line =~ /mac address='(.+)'/
              mac_address = $1
              break
            end
          end
        end

        tries = 30
        while ip_address == nil && tries > 0
          File.open("/var/lib/libvirt/dnsmasq/default.leases") do |leases|
            leases.each_line do |line|
              if line =~ /^\d+ #{mac_address} (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/
                ip_address = $1
              end
            end
          end
          if ip_address.nil?
            tries = tries - 1
            sleep 1
          end
        end

        raise ActionFailed, "Cannot determine IP Address of '#{container_id}'" unless ip_address

        return ip_address
      end

    end
  end
end
