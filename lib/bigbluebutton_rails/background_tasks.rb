module BigbluebuttonRails

  # Helper methods to execute tasks that run in resque and rake.
  class BackgroundTasks

    # For each meeting that hasn't ended yet, call `getMeetingInfo` and update
    # the meeting attributes or end it.
    def self.finish_meetings
      BigbluebuttonMeeting.where(ended: false).find_each do |meeting|
        Rails.logger.info "BackgroundTasks: Checking if the meeting has ended: #{meeting.inspect}"
        room = meeting.room
        if room.present? #and !meeting.room.fetch_is_running?
          begin
            # `fetch_meeting_info` will automatically update the meeting by
            # calling `room.update_current_meeting`
            room.fetch_meeting_info
          rescue BigBlueButton::BigBlueButtonException => e
            # TODO: get only the specific meetingID notFound exception

            Rails.logger.info "BackgroundTasks: Setting meeting as ended: #{meeting.inspect}"
            room.finish_meetings
          end

        end
      end
    end

    def self.update_recordings
      BigbluebuttonServer.find_each do |server|
        begin
          server.fetch_recordings
          Rails.logger.info "BackgroundTasks: List of recordings from #{server.url} updated successfully"
        rescue Exception => e
          Rails.logger.info "BackgroundTasks: Failure fetching recordings from #{server.inspect}"
          Rails.logger.info "BackgroundTasks: #{e.inspect}"
          Rails.logger.info "BackgroundTasks: #{e.backtrace.join("\n")}"
        end
      end
    end

  end

end
