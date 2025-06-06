require 'spec_helper_acceptance'

describe 'pdk validate', :module_command do
  include_context 'with a fake TTY'

  context 'when run inside of a module' do
    include_context 'in a new module', 'validate_all'

    before(:all) do
      File.open(File.join('manifests', 'init.pp'), 'w') do |f|
        f.puts <<~EOS
          # validate_all
          class validate_all {}
        EOS
      end
    end

    describe command('pdk validate') do
      # Warn is outputed as failure on non-windows
      #   Warn caused by tests being run against only a single Puppet version
      if Gem.win_platform?
        its(:exit_status) { is_expected.to eq(0) }
      else
        its(:exit_status) { is_expected.to eq(1) }
      end
      its(:stderr) { is_expected.to match(/Running all available validators/i) }
      its(:stderr) { is_expected.to match(/Checking metadata syntax/i) }
      its(:stderr) { is_expected.to match(/Checking module metadata style/i) }
      its(:stderr) { is_expected.to match(/Checking Puppet manifest syntax/i) }
      its(:stderr) { is_expected.to match(/Checking Puppet manifest style/i) }
      its(:stderr) { is_expected.to match(/Checking Ruby code style/i) }
    end

    context 'with a puppet syntax failure should still run all validators' do
      init_pp = File.join('manifests', 'init.pp')

      before(:all) do
        File.open(init_pp, 'w') do |f|
          f.puts <<~EOS
            # foo
            class validate_all {
              Fails here because of gibberish
            }
          EOS
        end
      end

      describe command('pdk validate --format text:stdout --format junit:report.xml') do
        its(:exit_status) { is_expected.not_to eq(0) }
        its(:stderr) { is_expected.to match(/Running all available validators/i) }
        its(:stderr) { is_expected.to match(/Checking metadata syntax/i) }
        its(:stderr) { is_expected.to match(/Checking module metadata style/i) }
        its(:stderr) { is_expected.to match(/Checking Puppet manifest syntax/i) }
        its(:stderr) { is_expected.to match(/Checking Ruby code style/i) }

        describe file('report.xml') do
          its(:content) { is_expected.to contain_valid_junit_xml }

          its(:content) do
            is_expected.to have_junit_testsuite('puppet-syntax').with_attributes(
              'failures' => eq(3),
              'tests' => eq(3)
            )
          end

          its(:content) do
            is_expected.to have_junit_testcase.in_testsuite('puppet-syntax').with_attributes(
              'classname' => 'puppet-syntax',
              'name' => a_string_starting_with(init_pp)
            ).that_failed(
              'type' => 'Error',
              'message' => a_string_matching(/This Name has no effect/i)
            )
          end

          its(:content) do
            is_expected.to have_junit_testcase.in_testsuite('puppet-syntax').with_attributes(
              'classname' => 'puppet-syntax',
              'name' => a_string_starting_with(init_pp)
            ).that_failed(
              'type' => 'Error',
              'message' => a_string_matching(/This Type-Name has no effect/i)
            )
          end
        end
      end

      describe command('pdk validate --parallel') do
        its(:exit_status) { is_expected.not_to eq(0) }
        its(:stderr) { is_expected.to match(/Running all available validators/i) }
        its(:stderr) { is_expected.to match(/Checking metadata syntax/i) }
        its(:stderr) { is_expected.to match(/Checking module metadata style/i) }
        its(:stderr) { is_expected.to match(/Checking Puppet manifest syntax/i) }
        its(:stdout) { is_expected.to match(/\(error\):.*This Name has no effect/i) }
        its(:stdout) { is_expected.to match(/\(error\):.*This Type-Name has no effect/i) }
        its(:stdout) { is_expected.to match(/\(error\):.*Language validation logged 2 errors/i) }
        its(:stderr) { is_expected.to match(/Checking Ruby code style/i) }
      end
    end

    context "when 'pdk' is included in the Gemfile" do
      before(:all) do
        File.open('Gemfile', 'a') do |f|
          f.puts "gem 'pdk', path: '#{File.expand_path(File.join(__FILE__, '..', '..', '..'))}'"
        end

        File.open(File.join('manifests', 'init.pp'), 'w') do |f|
          f.puts <<-EOS.gsub(/^ {10}/, '')
            # pdk_in_gemfile
            class pdk_in_gemfile {}
          EOS
        end
      end

      describe command('pdk validate') do
        its(:exit_status) { is_expected.to eq(1) | eq(256) }
        its(:stderr) { is_expected.to match(/Running all available validators/i) }
        its(:stderr) { is_expected.to match(/Checking metadata syntax/i) }
        its(:stderr) { is_expected.to match(/Checking module metadata style/i) }
        its(:stderr) { is_expected.to match(/Checking Puppet manifest syntax/i) }
        its(:stderr) { is_expected.to match(/Checking Ruby code style/i) }
        its(:stdout) { is_expected.to match(/\(warning\):.*indent should be 0 chars and is 2/i) }
      end
    end
  end
end
