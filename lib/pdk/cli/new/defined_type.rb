module PDK
  module CLI
    @new_define_cmd = @new_cmd.define_command do
      name 'defined_type'
      usage 'defined_type [options] <name>'
      summary 'Create a new defined type named <name> using given options'

      run do |opts, args, _cmd|
        PDK::CLI::Util.ensure_in_module!(
          message: 'Defined types can only be created from inside a valid module directory.',
          log_level: :info
        )

        defined_type_name = args[0]

        if defined_type_name.nil? || defined_type_name.empty?
          puts command.help
          exit 1
        end

        raise PDK::CLI::ExitWithError, format("'%{name}' is not a valid defined type name", name: defined_type_name) unless Util::OptionValidator.valid_defined_type_name?(defined_type_name)

        require 'pdk/generate/defined_type'

        updates = PDK::Generate::DefinedType.new(PDK.context, defined_type_name, opts).run
        PDK::CLI::Util::UpdateManagerPrinter.print_summary(updates, tense: :past)
      end
    end
  end
end
