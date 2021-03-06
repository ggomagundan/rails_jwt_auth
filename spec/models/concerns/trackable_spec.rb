require 'rails_helper'

describe RailsJwtAuth::Authenticatable do
  %w[ActiveRecord Mongoid].each do |orm|
    let(:user) do
      FactoryGirl.create(
        "#{orm.underscore}_user",
        last_sign_in_at: Time.now,
        last_sign_in_ip: '127.0.0.1'
      )
    end

    context "when use #{orm}" do
      describe '#attributes' do
        it { expect(user).to have_attributes(last_sign_in_at: user.last_sign_in_at) }
        it { expect(user).to have_attributes(last_sign_in_ip: user.last_sign_in_ip) }
      end

      describe '#update_tracked_fields!' do
        before do
          class Request
            def remote_ip
            end
          end
        end

        after do
          Object.send(:remove_const, :Request)
        end

        it 'updates tracked fields and save record' do
          user = FactoryGirl.create(:active_record_user)
          request = Request.new
          allow(request).to receive(:remote_ip).and_return('127.0.0.1')
          user.update_tracked_fields!(request)
          expect(user.last_sign_in_at).not_to eq(Time.now)
          expect(user.last_sign_in_ip).to eq('127.0.0.1')
        end
      end

      describe 'hook' do
        it 'calls update_tracked_fields! after_set_user' do
          user = FactoryGirl.create(:active_record_user)
          expect(user).to receive(:update_tracked_fields!)

          manager = Warden::Manager.new(nil, &Rails.application.config.middleware.detect{|m| m.name == 'Warden::Manager'}.block)
          warden = Warden::Proxy.new({}, manager)
          warden.set_user(user, store: false)
        end
      end
    end
  end
end
