require 'spec_helper'
require 'pdk/cli'

describe 'PDK::CLI new task' do
  let(:help_text) { a_string_matching(/^USAGE\s+pdk new task/m) }

  before do
    allow(PDK::Util).to receive(:module_root).and_return(module_root)
    # Stop printing out the result
    allow(PDK::CLI::Util::UpdateManagerPrinter).to receive(:print_summary)
  end

  shared_examples 'it exits non-zero and prints the help text' do
    it 'exits non-zero and prints the `pdk new task` help' do
      expect { PDK::CLI.run(args) }.to exit_nonzero.and output(help_text).to_stdout
    end
  end

  shared_examples 'it exits with an error' do |expected_error|
    it 'exits with an error' do
      expect(logger).to receive(:error).with(a_string_matching(expected_error))

      expect { PDK::CLI.run(args) }.to exit_nonzero
    end
  end

  context 'when not run from inside a module' do
    include_context 'run outside module'
    let(:module_root) { nil }
    let(:args) { ['new', 'task', 'test_task'] }

    it_behaves_like 'it exits with an error', /must be run from inside a valid module/
  end

  context 'when run from inside a module' do
    let(:module_root) { '/path/to/test/module' }

    context 'and not provided with a name for the new task' do
      let(:args) { ['new', 'task'] }

      it_behaves_like 'it exits non-zero and prints the help text'
    end

    context 'and provided an empty string as the task name' do
      let(:args) { ['new', 'task', ''] }

      it_behaves_like 'it exits non-zero and prints the help text'
    end

    context 'and provided an invalid task name' do
      let(:args) { ['new', 'task', 'test-task'] }

      it_behaves_like 'it exits with an error', /'test-task' is not a valid task name/
    end

    context 'and provided a valid task name' do
      let(:generator) { PDK::Generate::Task }
      let(:generator_double) { instance_double(generator, run: true) }
      let(:generator_opts) { {} }

      before do
        allow(generator).to receive(:new).with(anything, 'test_task', hash_including(generator_opts)).and_return(generator_double)
      end

      it 'generates the task' do
        expect(generator_double).to receive(:run)

        PDK::CLI.run(['new', 'task', 'test_task'])
      end

      context 'and provided a description for the task' do
        let(:generator_opts) do
          {
            description: 'test_task description'
          }
        end

        it 'generates the task with the specified description' do
          expect(generator_double).to receive(:run)

          PDK::CLI.run(['new', 'task', 'test_task', '--description', 'test_task description'])
        end
      end
    end
  end
end
