
module ActionSprout
  module ElasticSearch
    class ReindexStatus
      extend ActionSprout::MethodObject
      method_object client: (ElasticSearch.migrate_to_client || ElasticSearch.client), now: Time.current

      def call
        require "action_view"

        tasks = load_tasks

        tasks.each do |task|
          description = task.description[/to \[\w+\]/]
          migrated = ActiveSupport::NumberHelper.number_to_human task.migrated
          total = ActiveSupport::NumberHelper.number_to_human task.total

          percent_complete = task.migrated.to_f / task.total.to_f

          time_taken = now - task.start_time
          estimated_total_time = time_taken / percent_complete
          estimated_time_remaining = (1 - percent_complete) * estimated_total_time

          time_taken_string = render_time time_taken
          estimated_total_time_string = render_time estimated_total_time
          estimated_time_remaining_string = render_time estimated_time_remaining

          printf "%-30s %13s of %13s (%2.1f%%) -- %s elapsed\n", description, migrated, total, (percent_complete * 100), time_taken_string
          printf "Estimated %38s left of %38s total", estimated_time_remaining_string, estimated_total_time_string
          printf "\n\n"
        end
      end

      private

      def load_tasks
        tasks_response = client.tasks.list(actions: "*reindex", detailed: true)

        tasks_response["nodes"].flat_map do |nid, node|
          node["tasks"].flat_map { |id, task| Task.new id: id, data: task }
        end
      end

      def render_time(seconds)
        if seconds.finite?
          ActiveSupport::Duration.build(seconds.to_i).inspect
        end
      end

      class Task
        kwattr :id, :data

        def created
          data.dig("status", "created") || 0
        end

        def updated
          data.dig("status", "updated") || 0
        end

        def migrated
          created + updated
        end

        def total
          data.dig("status", "total") || 0
        end

        def description
          data.dig("description")
        end

        def start_time
          Time.at 0, data["start_time_in_millis"], :millisecond
        end
      end
    end
  end
end
