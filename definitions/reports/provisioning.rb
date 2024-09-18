module Checks
  module Report
    class Provisioning < ForemanMaintain::Report
      metadata do
        description 'Provisioning facts about the system'
      end

      def run
        hosts_in_3_months = sql_count("hosts WHERE managed = true AND created_at >= current_date - interval '3 months'")

        # Compute resources
        compute_resources_by_type = feature(:foreman_database).query("select type, count(*) from compute_resources group by type").map { |row| [row['type'], row['count']]}.to_h

        hosts_by_compute_resources_type = feature(:foreman_database).query("select compute_resources.type, count(hosts.id) from hosts left outer join compute_resources on compute_resource_id = compute_resources.id group by compute_resources.type").map { |row| [row['type'] || 'baremetal', row['count']]}.to_h
        hosts_by_compute_profile = feature(:foreman_database).query("select max(compute_profiles.name) as name, count(hosts.id) from hosts left outer join compute_profiles on compute_profile_id = compute_profiles.id group by compute_profile_id").map { |row| [row['name'] || 'none', row['count']]}.to_h

        # Bare metal
        nics_by_type_count = feature(:foreman_database).query("select type, count(*) from nics group by type").map { |row| [row['type'] || 'none', row['count']]}.to_h
        discovery_rules_count = sql_count('discovery_rules')
        hosts_by_managed_count = feature(:foreman_database).query("select managed, count(*) from hosts group by managed").map { |row| [row['managed'], row['count']]}.to_h


        # Templates
        non_default_templates_per_type = feature(:foreman_database).query("select type, count(*) from templates where templates.default = false group by type").map { |row| [row['type'], row['count']]}.to_h

        data = {
          discovery_rules_count: discovery_rules_count,
          managed_hosts_created_in_last_3_months: hosts_in_3_months
        }
        data.merge!(flatten(compute_resources_by_type, 'compute_resources_by_type'))
        data.merge!(flatten(hosts_by_compute_resources_type, 'hosts_by_compute_resources_type'))
        data.merge!(flatten(hosts_by_compute_profile, 'hosts_by_compute_profile'))
        data.merge!(flatten(nics_by_type_count, 'nics_by_type'))
        data.merge!(flatten(hosts_by_managed_count, 'hosts_by_managed'))
        data.merge!(flatten(non_default_templates_per_type, 'non_default_templates_per_type'))

        self.data = data
      end
    end
  end
end
