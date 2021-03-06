#
# Copyright (C) 2013 eNovance SAS <licensing@enovance.com>
#
# Author: Emilien Macchi <emilien.macchi@enovance.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# ironic::params
#

class ironic::params {
  include ::openstacklib::defaults

  $dbsync_command =
    'ironic-dbsync --config-file /etc/ironic/ironic.conf'

  $inspector_dbsync_command =
    'ironic-inspector-dbsync --config-file /etc/ironic-inspector/inspector.conf upgrade'

  case $::osfamily {
    'RedHat': {
      $common_package_name       = 'openstack-ironic-common'
      $lib_package_name          = 'python-ironic-lib'
      $api_package               = 'openstack-ironic-api'
      $api_service               = 'openstack-ironic-api'
      $conductor_package         = 'openstack-ironic-conductor'
      $conductor_service         = 'openstack-ironic-conductor'
      $client_package            = 'python-ironicclient'
      $inspector_package         = 'openstack-ironic-inspector'
      $inspector_service         = 'openstack-ironic-inspector'
      $inspector_dnsmasq_service = 'openstack-ironic-inspector-dnsmasq'
      $ipxe_rom_dir              = '/usr/share/ipxe'
      $ironic_wsgi_script_path   = '/var/www/cgi-bin/ironic'
      $ironic_wsgi_script_source = '/usr/lib/python2.7/site-packages/ironic/api/app.wsgi'
      $tftpd_package             = 'tftp-server'
      $ipxe_package              = 'ipxe-bootimgs'
      $syslinux_package          = 'syslinux-extlinux'
      $syslinux_path             = '/usr/share/syslinux'
      $syslinux_files            = ['pxelinux.0', 'chain.c32']
    }
    'Debian': {
      $common_package_name       = 'ironic-common'
      $lib_package_name          = 'python-ironic-lib'
      $api_service               = 'ironic-api'
      $api_package               = 'ironic-api'
      $conductor_service         = 'ironic-conductor'
      $conductor_package         = 'ironic-conductor'
      $client_package            = 'python-ironicclient'
      $inspector_package         = 'ironic-inspector'
      $inspector_service         = 'ironic-inspector'
      # it seems like there is not currently a builtin dnsmasq in the debian packaging
      # https://packages.debian.org/source/experimental/ironic-inspector
      # this should be changed to whatever debian will use for dnsmasq
      $inspector_dnsmasq_service = 'ironic-inspector-dnsmasq'
      $ipxe_rom_dir              = '/usr/lib/ipxe'
      $ironic_wsgi_script_path   = '/usr/lib/cgi-bin/ironic'
      $ironic_wsgi_script_source = '/usr/lib/python2.7/dist-packages/ironic/api/app.wsgi'
      $tftpd_package             = 'tftpd'
      $ipxe_package              = 'ipxe'
      $syslinux_package          = 'syslinux-common'
      $syslinux_path             = '/usr/lib/syslinux'
      $syslinux_files            = ['pxelinux.0', 'chain.c32', 'libcom32.c32', 'libutil.c32']
    }
    default: {
      fail("Unsupported osfamily ${::osfamily}")
    }
  }

}
