#
# Cookbook Name:: nvm
# Provider:: nvm_install
#
# Copyright 2013, HipSnip Limited
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

action :create do
	from_source_message = new_resource.from_source ? ' from source' : ''
	from_source_arg = new_resource.from_source ? '-s' : ''
  user_install = false
  chef_nvm_user = 'root'
  chef_nvm_group = 'root'
  user_home = '/root'

  if new_resource.user && new_resource.user != 'root'
    user_install = true
    chef_nvm_user = new_resource.user
    chef_nvm_group = new_resource.group || new_resource.user
  end

  nvm_dir = new_resource.nvm_directory

  if user_install
    nvm_dir_base = new_resource.user_home || "/home/" + chef_nvm_user
    nvm_dir = nvm_dir_base + "/.nvm"
  end

  directory nvm_dir do
    user chef_nvm_user
    group chef_nvm_group
    action :create
  end

  git nvm_dir do
    user chef_nvm_user
    group chef_nvm_group
    repository node['nvm']['repository']
    reference node['nvm']['reference']
    action :sync
  end

  template '/etc/profile.d/nvm.sh' do
    source 'nvm.sh.erb'
    mode 0755
    cookbook 'nvm'
    variables ({
      :nvm_dir => nvm_dir
    })
  end

	script "Installing node.js #{new_resource.version}#{from_source_message}, as #{chef_nvm_user}:#{chef_nvm_group} from #{nvm_dir}" do
    interpreter 'bash'
    flags '-l'
    user chef_nvm_user
    group chef_nvm_group
    environment Hash[ 'HOME' => user_home ]
		code <<-EOH
      export NVM_DIR=#{nvm_dir}
      source /etc/profile.d/nvm.sh
			nvm install #{from_source_arg} #{new_resource.version}
		EOH
	end
	# break FC021: Resource condition in provider may not behave as expected
	# silly thing because new_resource.version is dynamic not fixed
	nvm_alias_default new_resource.version do
    user chef_nvm_user
    group chef_nvm_group
    nvm_directory nvm_dir
		action :create
		only_if { new_resource.alias_as_default }
	end
	new_resource.updated_by_last_action(true)
end
