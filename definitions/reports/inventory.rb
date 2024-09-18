# copy the file and add the .rb suffix
module Checks
  module Report
    class Inventory < ForemanMaintain::Report
      metadata do
        description 'Facts about hosts and the rest of the inventory'
      end

      def run
        # Hosts
        hosts_by_type_count = feature(:foreman_database).query("select type, count(*) from hosts group by type").map { |row| [row['type'], row['count']]}.to_h

        # OS usage
        hosts_by_os_count = feature(:foreman_database).query("select max(operatingsystems.name) as os_name, max(operatingsystems.type) as os_type, count(*) as hosts_count from hosts inner join operatingsystems on operatingsystem_id = operatingsystems.id group by operatingsystem_id").map { |row| [row['os_name'], row['hosts_count']]}.to_h

        # Facts usage
        facts_by_type = feature(:foreman_database).query("select fact_names.type, min(fact_values.updated_at) as min_update_time, max(fact_values.updated_at) as max_update_time, count(fact_values.id) from fact_values inner join fact_names on fact_name_id = fact_names.id group by fact_names.type").map { |row| [row['type'], row]}.to_h

        # Audits
        audits = feature(:foreman_database).query("select count(*), min(created_at), max(created_at) from audits").first

        # Parameters
        parameters = feature(:foreman_database).query("select type, count(*) from parameters group by type").map { |row| [row['type'], row['count']]}.to_h

        data = {}

        data.merge!(flatten(hosts_by_type_count, 'hosts_by_type_count'))
        data.merge!(flatten(hosts_by_type_count, 'hosts_by_type_count'))
        data.merge!(flatten(hosts_by_os_count,'hosts_by_os_count'))
        data.merge!(flatten(facts_by_type,'facts_by_type'))
        data.merge!(flatten(audits,'audits'))
        data.merge!(flatten(parameters,'parameters'))

        self.data = data
      end
    end
  end
end
