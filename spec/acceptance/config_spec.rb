require 'spec_helper_acceptance'
require 'fileutils'

describe 'pdk config' do
  include_context 'with a fake TTY'

  context 'when run outside of a module' do
    describe command('pdk config') do
      its(:exit_status) { is_expected.to eq 0 }
      # Should show the command help
      its(:stdout) { is_expected.to match(/pdk config \[subcommand\] \[options\]/) }
      its(:stderr) { is_expected.to match(/The 'pdk config' command is deprecated/) }
    end
  end
end
