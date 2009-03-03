require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PitchesController do
  route_matches("/pitches/1/fully_fund", :put, :id => "1", :controller => "pitches", :action => "fully_fund")

  describe "on GET to /pitchs/new" do
    before(:each) do
      Pitch.stub!(:createable_by?).and_return(true)
      @user = Factory(:user)
      controller.stub!(:current_user).and_return(@user)
      get :new
    end

    it "assigns the new pitch the current user" do
      assigns(:pitch).user_id.should == @user.id
    end
  end

  describe "when can't create on new" do
    before(:each) do
      Pitch.stub!(:createable_by?).and_return(false)
      get :new
    end
    it_denies_access
  end

  describe "when can't edit" do
    it "should deny access and add flash when not owner" do
      user = Factory(:user)
      pitch = Factory(:pitch, :user => Factory(:user))
      Pitch.stub!(:find).and_return(pitch)
      get :edit, :id => pitch.id
      flash[:error].should match(/You cannot edit this pitch, since you didn't create it./)
      response.should redirect_to(pitch_path(pitch))
    end

    it "should deny access and add flash when donations added" do
      user = Factory(:user)
      pitch = Factory(:pitch, :user => user)
      controller.stub!(:current_user).and_return(user)
      donation = Factory(:donation, :pitch => pitch, :amount => 2, :status => 'paid')
      Pitch.stub!(:find).and_return(pitch)
      get :edit, :id => pitch.id
      flash[:error].should match(/You cannot edit a pitch that has donations.  For minor changes, contact info@spot.us/)
      response.should redirect_to(pitch_path(pitch))
    end
  end

  describe "can_edit?" do
    it "should allow the owner of a pitch to have access" do
      user = Factory(:user)
      pitch = Factory(:pitch, :user => user)
      pitch.should be_editable_by(user)
      get :edit, :id => pitch.id
    end

    it "should allow an admin to have access" do
      user = Factory(:admin)
      pitch = Factory(:pitch)
      controller.stub!(:current_user).and_return(user)
      donation = Factory(:donation, :pitch => pitch, :amount => 3, :status => 'paid')
      get :edit, :id => pitch.id
      flash[:error].should be_nil
    end
  end

  describe "on GET to /pitches/1/edit" do
    describe "without donations" do
      it "renders edit" do
        controller.stub!(:can_edit?).and_return(true)
        pitch = Factory(:pitch)
        get :edit, :id => pitch.to_param
        response.should render_template(:edit)
      end
    end
  end

  describe "on PUT to /pitches/1/feature" do
    before do
      @pitch = Factory(:pitch, :id => 17, :feature => true)
    end

    it "should redirect back to the pitch" do
      put :feature, :id => @pitch.to_param
      response.should redirect_to(pitch_path(@pitch))
    end

    it "should call feature! on the pitch" do
      controller.stub!(:find_resource).and_return(@pitch)
      @pitch.should_receive(:feature!).and_return(true)
      put :feature, :id => @pitch.id
    end
  end

  describe "on PUT to /pitches/1/unfeature" do
    before do
      @pitch = Factory(:pitch, :id => 17, :feature => true)
    end

    it "should redirect back to the pitch" do
      put :unfeature, :id => @pitch.to_param
      response.should redirect_to(pitch_path(@pitch))
    end

    it "should call feature! on the pitch" do
      controller.stub!(:find_resource).and_return(@pitch)
      @pitch.should_receive(:unfeature!).and_return(true)
      put :unfeature, :id => @pitch.id
    end
  end

  describe "on PUT to fully_fund" do
    before do
      @organization = Factory(:organization)
      controller.stub!(:current_user).and_return(@organization)
      @pitch = Factory(:pitch)
      Pitch.stub!(:find).and_return(@pitch)
    end

    it "requires a logged in user" do
      controller.should_receive(:current_user).and_return(nil)
      put :fully_fund, :id => @pitch.id
      response.should redirect_to(new_session_path)
    end

    it "requires the current user is a news organization" do
      controller.stub!(:current_user).and_return(Factory(:reporter))
      put :fully_fund, :id => @pitch.id
      flash[:error].should_not be_nil
      response.should redirect_to(new_session_path)
    end

    it "creates a donation for the full amount requested" do
      @pitch.should_receive(:fully_fund!).with(@organization)
      put :fully_fund, :id => @pitch.id
    end

    it "sets a flash message on success" do
      put :fully_fund, :id => @pitch.id
      flash[:success].should_not be_nil
    end
    it "redirects to myspot/donations_amounts/edit on success" do
      put :fully_fund, :id => @pitch.id
      response.should redirect_to(edit_myspot_donations_amounts_path)
    end

    describe "if the donation creation fails" do
      before do
        @pitch.donations.stub!(:create).and_return(false)
      end
      it "should set an error message if the donation creation fails" do
        put :fully_fund, :id => @pitch.id
        flash[:error].should_not be_nil
      end
      it "should redirect back to the pitch if the donation creation fails" do
        put :fully_fund, :id => @pitch.id
        response.should redirect_to(pitch_path(@pitch))
      end
    end
  end

  describe "on GET to show" do
    before do
      @pitch = Factory(:pitch)
    end

    it "should store the location in the session" do
      do_show
      session[:return_to].should == pitch_path(@pitch)
    end

    def do_show
      get :show, :id => @pitch.id
    end
  end

  describe "on GET to new with a headline" do
    before do
      login_as Factory(:user)
      controller.stub!(:can_create?).and_return(true)
      get :new, :headline => 'example'
    end

    it "should prefill the headline on the pitch" do
      assigns[:pitch].headline.should == 'example'
    end
  end

  describe "on GET to index" do
    it "should redirect to /news_items" do
      get :index
      response.should redirect_to(news_items_path)
    end
  end
end
