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
# Unit tests for ironic
#

require 'spec_helper'

describe 'ironic' do

  let :params do
    { :package_ensure              => 'present',
      :debug                       => false,
      :database_connection         => 'sqlite:////var/lib/ironic/ironic.sqlite',
      :database_max_retries        => 10,
      :database_idle_timeout       => 3600,
      :database_reconnect_interval => 10,
      :database_retry_interval     => 10,
      :glance_num_retries          => 0,
      :glance_api_insecure         => false,
      :purge_config                => false,
    }
  end

  shared_examples_for 'ironic' do

    context 'and if rabbit_host parameter is provided' do
      it_configures 'a ironic base installation'
      it_configures 'with SSL disabled'
      it_configures 'with SSL enabled without kombu'
      it_configures 'with SSL enabled with kombu'
      it_configures 'with amqp_durable_queues disabled'
      it_configures 'with amqp_durable_queues enabled'
      it_configures 'with one glance server'
      it_configures 'with two glance servers'
    end

    context 'and if rabbit_hosts parameter is provided' do

      context 'with one server' do
        before { params.merge!( :rabbit_hosts => ['127.0.0.1:5672'] ) }
        it_configures 'a ironic base installation'
        it_configures 'rabbit HA with a single virtual host'
      end

      context 'with multiple servers' do
        before { params.merge!( :rabbit_hosts => ['rabbit1:5672', 'rabbit2:5672'] ) }
        it_configures 'a ironic base installation'
        it_configures 'rabbit HA with multiple hosts'
      end
    end

    context 'with amqp rpc_backend value' do
      it_configures 'amqp support'
    end

  end

  shared_examples_for 'a ironic base installation' do

    it { is_expected.to contain_class('ironic::logging') }
    it { is_expected.to contain_class('ironic::params') }

    it 'installs ironic-common package' do
      is_expected.to contain_package('ironic-common').with(
        :ensure => 'present',
        :name   => platform_params[:common_package_name],
        :tag    => ['openstack', 'ironic-package'],
      )
    end

    it 'installs ironic-lib package' do
      is_expected.to contain_package('ironic-lib').with(
        :ensure => 'present',
        :name   => platform_params[:lib_package_name],
        :tag    => ['openstack', 'ironic-package'],
      )
    end

    it 'passes purge to resource' do
      is_expected.to contain_resources('ironic_config').with({
        :purge => false
      })
    end

    it 'configures credentials for rabbit' do
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/rabbit_userid').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/rabbit_password').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/rabbit_virtual_host').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/rabbit_password').with_secret( true )
    end

    it 'should perform default database configuration' do
      is_expected.to contain_ironic_config('database/connection').with_value(params[:database_connection])
      is_expected.to contain_ironic_config('database/max_retries').with_value(params[:database_max_retries])
      is_expected.to contain_ironic_config('database/idle_timeout').with_value(params[:database_idle_timeout])
      is_expected.to contain_ironic_config('database/retry_interval').with_value(params[:database_retry_interval])
    end

    it 'configures glance connection' do
      is_expected.to contain_ironic_config('glance/glance_num_retries').with_value(params[:glance_num_retries])
      is_expected.to contain_ironic_config('glance/glance_api_insecure').with_value(params[:glance_api_insecure])
    end

    it 'configures ironic.conf' do
      is_expected.to contain_ironic_config('DEFAULT/auth_strategy').with_value('keystone')
      is_expected.to contain_ironic_config('DEFAULT/my_ip').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ironic_config('DEFAULT/rpc_response_timeout').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ironic_config('DEFAULT/control_exchange').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ironic_config('DEFAULT/transport_url').with_value('<SERVICE DEFAULT>')
    end
  end

  shared_examples_for 'rabbit HA with a single virtual host' do
    it 'in ironic.conf' do
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/rabbit_host').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/rabbit_port').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/rabbit_hosts').with_value( params[:rabbit_hosts] )
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/rabbit_ha_queues').with_value('<SERVICE DEFAULT>')
    end
  end

  shared_examples_for 'rabbit HA with multiple hosts' do
    it 'in ironic.conf' do
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/rabbit_host').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/rabbit_port').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/rabbit_hosts').with_value( params[:rabbit_hosts].join(',') )
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/rabbit_ha_queues').with_value(true)
    end
  end

  shared_examples_for 'with SSL enabled with kombu' do
    before do
      params.merge!(
        :rabbit_use_ssl     => true,
        :kombu_ssl_ca_certs => '/path/to/ssl/ca/certs',
        :kombu_ssl_certfile => '/path/to/ssl/cert/file',
        :kombu_ssl_keyfile  => '/path/to/ssl/keyfile',
        :kombu_ssl_version  => 'TLSv1'
      )
    end

    it do
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/rabbit_use_ssl').with_value('true')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/kombu_ssl_ca_certs').with_value('/path/to/ssl/ca/certs')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/kombu_ssl_certfile').with_value('/path/to/ssl/cert/file')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/kombu_ssl_keyfile').with_value('/path/to/ssl/keyfile')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/kombu_ssl_version').with_value('TLSv1')
    end
  end

  shared_examples_for 'with SSL enabled without kombu' do
    before do
      params.merge!(
        :rabbit_use_ssl     => true,
      )
    end

    it do
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/rabbit_use_ssl').with_value('true')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/kombu_ssl_ca_certs').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/kombu_ssl_certfile').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/kombu_ssl_keyfile').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/kombu_ssl_version').with_value('<SERVICE DEFAULT>')
    end
  end

  shared_examples_for 'with SSL disabled' do
    before do
      params.merge!(
        :rabbit_use_ssl     => false,
      )
    end

    it do
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/rabbit_use_ssl').with_value('false')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/kombu_ssl_ca_certs').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/kombu_ssl_certfile').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/kombu_ssl_keyfile').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/kombu_ssl_version').with_value('<SERVICE DEFAULT>')
    end
  end


  shared_examples_for 'with amqp_durable_queues disabled' do
    it { is_expected.to contain_ironic_config('oslo_messaging_rabbit/amqp_durable_queues').with_value('<SERVICE DEFAULT>') }
  end

  shared_examples_for 'with amqp_durable_queues enabled' do
    before do
      params.merge!( :amqp_durable_queues => true )
    end

    it { is_expected.to contain_ironic_config('oslo_messaging_rabbit/amqp_durable_queues').with_value(true) }
  end

  shared_examples_for 'with one glance server' do
    before do
      params.merge!(:glance_api_servers => '10.0.0.1:9292')
    end

    it 'should configure one glance server' do
      is_expected.to contain_ironic_config('glance/glance_api_servers').with_value(params[:glance_api_servers])
    end
  end

  shared_examples_for 'with two glance servers' do
    before do
      params.merge!(:glance_api_servers => ['10.0.0.1:9292','10.0.0.2:9292'])
    end

    it 'should configure one glance server' do
       is_expected.to contain_ironic_config('glance/glance_api_servers').with_value(params[:glance_api_servers].join(','))
    end
  end

  shared_examples_for 'amqp support' do
    context 'with default parameters' do
      before { params.merge!( :rpc_backend => 'amqp' ) }

      it { is_expected.to contain_ironic_config('DEFAULT/rpc_backend').with_value('amqp') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/server_request_prefix').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/broadcast_prefix').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/group_request_prefix').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/container_name').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/idle_timeout').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/trace').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/ssl_ca_file').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/ssl_cert_file').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/ssl_key_file').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/ssl_key_password').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/allow_insecure_clients').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/sasl_mechanisms').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/sasl_config_dir').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/sasl_config_name').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/username').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/password').with_value('<SERVICE DEFAULT>') }
    end

    context 'with overriden amqp parameters' do
      before { params.merge!(
        :rpc_backend        => 'amqp',
        :amqp_idle_timeout  => '60',
        :amqp_trace         => true,
        :amqp_ssl_ca_file   => '/path/to/ca.cert',
        :amqp_ssl_cert_file => '/path/to/certfile',
        :amqp_ssl_key_file  => '/path/to/key',
        :amqp_username      => 'amqp_user',
        :amqp_password      => 'password',
      ) }

      it { is_expected.to contain_ironic_config('DEFAULT/rpc_backend').with_value('amqp') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/server_request_prefix').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/broadcast_prefix').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/group_request_prefix').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/container_name').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/idle_timeout').with_value('60') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/trace').with_value('true') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/ssl_ca_file').with_value('/path/to/ca.cert') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/ssl_cert_file').with_value('/path/to/certfile') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/ssl_key_file').with_value('/path/to/key') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/allow_insecure_clients').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/sasl_mechanisms').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/sasl_config_dir').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/sasl_config_name').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/username').with_value('amqp_user') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/password').with_value('password') }
    end
  end

  context 'on Debian platforms' do
    let :facts do
      @default_facts.merge({ :osfamily => 'Debian' })
    end

    let :platform_params do
      { :common_package_name => 'ironic-common',
        :lib_package_name    => 'python-ironic-lib' }
    end

    it_configures 'ironic'
  end

  context 'on RedHat platforms' do
    let :facts do
      @default_facts.merge({ :osfamily => 'RedHat' })
    end

    let :platform_params do
      { :common_package_name => 'openstack-ironic-common',
        :lib_package_name    => 'python-ironic-lib' }
    end

    it_configures 'ironic'
  end
end
