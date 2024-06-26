require 'spec_helper_acceptance'
require 'fileutils'

describe 'pdk get config' do
  include_context 'with a fake TTY'

  context 'when run outside of a module' do
    describe command('pdk get config') do
      its(:exit_status) { is_expected.to eq 0 }
      # This setting should appear in all pdk versions
      its(:stdout) { is_expected.to match(/user.pdk_feature_flags.available=/) }
      its(:stderr) { is_expected.to have_no_output }
    end

    describe command('pdk get config user.pdk_feature_flags.available') do
      its(:exit_status) { is_expected.to eq 0 }
      # This setting, and only, this setting should appear in output
      its(:stdout) { is_expected.to match('["controlrepo"]') }
      its(:stderr) { is_expected.to have_no_output }
    end

    describe command('pdk get config user.pdk_feature_flags') do
      its(:exit_status) { is_expected.to eq 0 }
      # There should be two configuration items returned
      its(:stdout) { expect(is_expected.target.split("\n").count).to eq(2) }

      its(:stdout) do
        result = is_expected.target.split("\n").sort
        expect(result[0]).to match('user.pdk_feature_flags.available=["controlrepo"]')
        expect(result[1]).to match(/user.pdk_feature_flags.requested=.+/)
      end

      its(:stderr) { is_expected.to have_no_output }
    end

    describe command('pdk get config does.not.exist') do
      its(:exit_status) { is_expected.not_to eq(0) }
      its(:stdout) { is_expected.to have_no_output }
      its(:stderr) { is_expected.to match(/does\.not\.exist/) }
    end
  end
end
