# copy the file and add the .rb suffix
module Checks
  module Report
    class Platform < ForemanMaintain::Report
      metadata do
        description 'Report about platform usages'
      end

      def run
        # General
        smart_proxies_count = sql_count('smart_proxies')
        smart_proxies_creation_date = feature(:foreman_database).query("select id, created_at from smart_proxies").map { |row| [row['id'], row['created_at']]}.to_h

        #RBAC
        total_users_count = sql_count('users')
        non_admin_users_count = sql_count('users where admin = false')

        custom_roles_count = sql_count('roles where origin = null')
        taxonomies_counts = feature(:foreman_database).query("select type, count(*) from taxonomies group by type").map { |row| [row['type'], row['count']]}.to_h

        #Settings
        modified_settings = feature(:foreman_database).query("select name from settings")

        #User groups
        user_groups_count = sql_count('usergroups')

        #Bookmarks
        bookmarks_by_public_by_type = feature(:foreman_database).query("select public, owner_type, count(*) from bookmarks group by public, owner_type").map { |row| ["#{row['public'] ? 'public' : 'private'}:#{row['owner_type']}", row['count']]}.to_h
        bookmarks_by_owner = feature(:foreman_database).query("select owner_type, owner_id, count(*) from bookmarks group by owner_type, owner_id").map { |row| ["#{row['owner_type']}:#{row['owner_id']}", row['count']]}.to_h

        #Mail notifications
        users_per_mail_notification = feature(:foreman_database).query("select max(mail_notifications.name) as notification_name, count(user_mail_notifications.user_id) from user_mail_notifications inner join mail_notifications on mail_notification_id = mail_notifications.id group by mail_notification_id").map { |row| [row['notification_name'], row['count']]}.to_h

        #Webhooks
        #TODO

        data = {
          smart_proxies_count: smart_proxies_count,
          total_users_count: total_users_count,
          non_admin_users_count: non_admin_users_count,
          custom_roles_count: custom_roles_count,
          modified_settings: modified_settings,
          user_groups_count: user_groups_count,
        }

        data.merge!(flatten(smart_proxies_creation_date, 'smart_proxies_creation_date'))
        data.merge!(flatten(taxonomies_counts, 'taxonomies_counts'))
        data.merge!(flatten(bookmarks_by_public_by_type, 'bookmarks_by_public_by_type'))
        data.merge!(flatten(bookmarks_by_owner, 'bookmarks_by_owner'))
        data.merge!(flatten(users_per_mail_notification, 'users_per_mail_notification'))

        self.data = data
      end
    end
  end
end
