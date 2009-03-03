class PitchesController < ApplicationController
  before_filter :store_location, :only => :show
  before_filter :organization_required, :only => :fully_fund
  resources_controller_for :pitch

  def index
    redirect_to(news_items_path)
  end

  def feature
    pitch = find_resource
    pitch.feature!
    redirect_to pitch_path(pitch)
  end

  def unfeature
    pitch = find_resource
    pitch.unfeature!
    redirect_to pitch_path(pitch)
  end

  def fully_fund
    pitch = find_resource
    if donation = pitch.fully_fund!(current_user)
      flash[:success] = "Your donation was successfully created"
      redirect_to edit_myspot_donations_amounts_path
    else
      flash[:error] = "An error occurred while trying to fund this pitch"
      redirect_to pitch_path(pitch)
    end

  end

  protected

  def can_create?
    access_denied unless Pitch.createable_by?(current_user)
  end

  def can_edit?

    pitch = find_resource

    if not pitch.editable_by?(current_user)
      if pitch.user == current_user
        if pitch.donated_to?
          access_denied( \
            :flash => "You cannot edit a pitch that has donations.  For minor changes, contact info@spot.us",
            :redirect => pitch_url(pitch))
        else
          access_denied( \
            :flash => "You cannot edit this pitch.  For minor changes, contact info@spot.us",
            :redirect => pitch_url(pitch))
        end
      else
        access_denied( \
          :flash => "You cannot edit this pitch, since you didn't create it.",
          :redirect => pitch_url(pitch))
      end
    end
  end

  def new_resource
    params[:pitch] ||= {}
    params[:pitch][:headline] = params[:headline] if params[:headline]
    current_user.pitches.new(params[:pitch])
  end

  def organization_required
    access_denied unless current_user && current_user.organization?
  end

end
