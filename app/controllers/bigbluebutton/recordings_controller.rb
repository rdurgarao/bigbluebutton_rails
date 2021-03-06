class Bigbluebutton::RecordingsController < ApplicationController
  include BigbluebuttonRails::InternalControllerMethods

  respond_to :html
  before_filter :find_recording, :except => [:index]
  before_filter :check_for_server, :only => [:publish, :unpublish]
  before_filter :find_playback, :only => [:play]

  def index
    @recordings ||= BigbluebuttonRecording.all
    respond_with(@recordings)
  end

  def show
    respond_with(@recording)
  end

  def edit
    respond_with(@recording)
  end

  def update
    respond_with @recording do |format|
      if @recording.update_attributes(recording_params)
        format.html {
          message = t('bigbluebutton_rails.recordings.notice.update.success')
          redirect_to_using_params @recording, :notice => message
        }
      else
        format.html { redirect_to_params_or_render :edit }
      end
    end
  end

  def destroy
    error = false
    begin
      if @recording.server
        server = @recording.server
        server.send_delete_recordings(@recording.recordid)
      end
      message = t('bigbluebutton_rails.recordings.notice.destroy.success')
    rescue BigBlueButton::BigBlueButtonException => e
      error = true
      message = t('bigbluebutton_rails.recordings.notice.destroy.success_with_bbb_error', :error => e.to_s[0..200])
    end

    # TODO: what if it fails?
    @recording.destroy

    respond_with do |format|
      format.html {
        if error
          flash[:error] = message
          redirect_to_using_params bigbluebutton_recordings_url
        else
          redirect_to_using_params bigbluebutton_recordings_url, :notice => message
        end
      }
    end
  end

  def play
    respond_with do |format|
      format.html {
        if @playback
          redirect_to @playback.url
        else
          flash[:error] = t('bigbluebutton_rails.recordings.errors.play.no_format')
          redirect_to_using_params bigbluebutton_recording_url(@recording)
        end
      }
    end
  end

  def publish
    self.publish_unpublish(true)
  end

  def unpublish
    self.publish_unpublish(false)
  end

  protected

  def find_recording
    @recording ||= BigbluebuttonRecording.find_by_recordid(params[:id])
  end

  def check_for_server
    unless @recording.server
      message = t('bigbluebutton_rails.recordings.errors.check_for_server.no_server')
      respond_with do |format|
        format.html {
          flash[:error] = message
          redirect_to bigbluebutton_recording_path(@recording)
        }
      end
      false
    else
      true
    end
  end

  def publish_unpublish(publish)
    begin
      server = @recording.server
      server.send_publish_recordings(@recording.recordid, publish)
      respond_with do |format|
        if publish
          message = t('bigbluebutton_rails.recordings.notice.publish.success')
        else
          message = t('bigbluebutton_rails.recordings.notice.unpublish.success')
        end
        format.html {
          redirect_to_using_params bigbluebutton_recording_path(@recording), :notice => message
        }
      end
    rescue BigBlueButton::BigBlueButtonException => e
      respond_with do |format|
        format.html {
          flash[:error] = e.to_s[0..200]
          redirect_to_using_params bigbluebutton_recording_path(@recording)
        }
      end
    end
  end

  def recording_params
    unless params[:bigbluebutton_recording].nil?
      params[:bigbluebutton_recording].permit(*recording_allowed_params)
    else
      {}
    end
  end

  def recording_allowed_params
    [ :description ]
  end

  protected

  def find_playback
    if params[:type]
      @playback = @recording.playback_formats.where(:playback_type_id => BigbluebuttonPlaybackType.find_by_identifier(params[:type])).first
    else
      @playback = @recording.default_playback_format || @recording.playback_formats.first
    end
  end

end
