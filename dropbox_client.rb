# Install this the SDK with "gem install dropbox-sdk"
require 'dropbox_sdk'

class DropboxClientWrapper

  def initialize
    access_token = ENV['MORPH_DROPBOX_ACCESS_TOKEN']
    @client = DropboxClient.new(access_token)
  end

  def get_file_paths(position)
    metadata = @client.metadata(position)
    metadata["contents"].map do |hash|
      hash["path"]
    end
  end

  def download_file(path)
    contents = @client.get_file(path)
    path.gsub!('/', '')
    File.open(path, 'w') {|f| f.puts contents }
  end
end

