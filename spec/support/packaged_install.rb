RSpec.shared_context 'packaged install' do
  let(:package_cachedir) { '/package/share/cache' }

  before do
    allow(PDK::Util).to receive(:package_install?).and_return(true)
    allow(PDK::Util::Filesystem).to receive(:file?).with(/PDK_VERSION/).and_return(true)
    allow(PDK::Util::Filesystem).to receive(:exist?).with(/bundle(\.bat)?$/).and_return(true)
    allow(PDK::Util).to receive(:package_cachedir).and_return(package_cachedir)
    allow(PDK::Util::RubyVersion).to receive(:versions).and_return('2.4.4' => '2.4.0')
    allow(PDK::Util::RubyVersion).to receive(:default_ruby_version).and_return('2.4.4')
  end
end

RSpec.shared_context 'not packaged install' do
  before do
    allow(PDK::Util).to receive(:package_install?).and_return(false)
  end
end
