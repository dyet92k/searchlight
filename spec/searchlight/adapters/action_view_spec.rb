require "spec_helper"

describe "Searchlight::Adapters::ActionView", type: :feature do

  let(:view)   { ::ActionView::Base.new }
  let(:search) { AccountSearch.new(paid_amount: 15) }

  before :all do
    # Only required when running these tests
    require "searchlight/adapters/action_view"
  end

  before :each do
    allow(view).to receive(:protect_against_forgery?).and_return(false)
  end

  it "it can be used to build a form" do
    form = view.form_for(search, url: '#') do |f|
      f.text_field(:paid_amount)
    end

    expect(form).to have_selector("form input[name='account_search[paid_amount]'][value='15']")
  end

  it "tells the form that it is not persisted" do
    expect(search).not_to be_persisted
  end

end
